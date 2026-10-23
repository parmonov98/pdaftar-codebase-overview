<?php

namespace App\Services;

/**
 * Makes newer iPhone HEICs readable by libheif 1.17 (Ubuntu 24.04's version,
 * which production runs) without upgrading the system package.
 *
 * Since iOS 18 a photo can carry an ISO 21496-1 HDR gain map as a `tmap`
 * item, and Portrait shots attach their depth (and sometimes alpha) image to
 * that `tmap` item through an `auxl` reference. libheif < 1.18 does not know
 * `tmap` is an image, so it rejects the WHOLE file with
 * "Non-existing depth image referenced" before it even looks at the primary
 * image (fixed upstream in libheif 1.18, strukturag/libheif#1213).
 *
 * The primary photo itself is a normal HEVC grid. We copy the file and
 * rename the type of every `auxl`/`thmb` reference that points at an item
 * libheif 1.17 does not treat as an image to an unknown four-cc, which
 * libheif silently ignores. The rename is in place (same byte length), so no
 * box size or `iloc` offset moves and the image data is untouched. Only the
 * depth/gain-map association is lost, which a JPEG cannot hold anyway.
 */
class HeifAuxReferenceSanitizer {
    /** Four-cc written over a neutralised reference type; unknown to libheif. */
    public const NEUTRALISED_TYPE = 'pdxr';

    /** Item types libheif 1.17 treats as images (HeifContext::item_type_is_image). */
    private const LIBHEIF_117_IMAGE_TYPES = [
        'hvc1', 'grid', 'iden', 'iovl', 'av01', 'unci', 'vvc1', 'jpeg', 'mime', 'j2k1', 'mski',
    ];

    /** Reference types libheif 1.17 resolves against the image list. */
    private const CHECKED_REFERENCE_TYPES = ['auxl', 'thmb'];

    /**
     * Returns the path of a sanitised copy, or null when the file has nothing
     * to neutralise (or is not a parsable HEIF), so callers can skip a retry
     * that would fail the same way.
     */
    public function sanitizedCopy(string $path): ?string {
        $data = @file_get_contents($path);
        if ($data === false || $data === '') {
            return null;
        }

        $patched = $this->sanitize($data);
        if ($patched === null) {
            return null;
        }

        $out = sys_get_temp_dir().'/'.uniqid('heic_sanitized_').'.heic';
        if (file_put_contents($out, $patched) === false) {
            return null;
        }

        return $out;
    }

    /**
     * Returns the patched bytes, or null when nothing needed patching.
     */
    public function sanitize(string $data): ?string {
        $meta = $this->findBox($data, 0, strlen($data), 'meta');
        if ($meta === null) {
            return null;
        }
        // meta is a FullBox: 4 bytes of version/flags precede its children.
        $metaChildrenStart = $meta['body'] + 4;

        $iinf = $this->findBox($data, $metaChildrenStart, $meta['end'], 'iinf');
        $iref = $this->findBox($data, $metaChildrenStart, $meta['end'], 'iref');
        if ($iinf === null || $iref === null) {
            return null;
        }

        $itemTypes = $this->itemTypes($data, $iinf);
        if ($itemTypes === []) {
            return null;
        }

        $irefVersion = ord($data[$iref['body']]);
        $idSize = $irefVersion === 0 ? 2 : 4;
        $changed = false;

        $pos = $iref['body'] + 4;
        while ($pos + 8 <= $iref['end']) {
            $box = $this->boxAt($data, $pos, $iref['end']);
            if ($box === null) {
                break;
            }

            if (in_array($box['type'], self::CHECKED_REFERENCE_TYPES, true)) {
                $cursor = $box['body'] + $idSize; // skip from_item_ID
                if ($cursor + 2 <= $box['end']) {
                    $count = unpack('n', substr($data, $cursor, 2))[1];
                    $cursor += 2;
                    for ($i = 0; $i < $count && $cursor + $idSize <= $box['end']; $i++, $cursor += $idSize) {
                        $toId = $this->readUint($data, $cursor, $idSize);
                        $type = $itemTypes[$toId] ?? null;
                        if ($type === null || ! in_array($type, self::LIBHEIF_117_IMAGE_TYPES, true)) {
                            // Overwrite the four-cc only — same length, nothing shifts.
                            $data = substr_replace($data, self::NEUTRALISED_TYPE, $box['start'] + 4, 4);
                            $changed = true;
                            break;
                        }
                    }
                }
            }

            $pos = $box['end'];
        }

        return $changed ? $data : null;
    }

    /** @return array<int, string> item_ID => item_type */
    private function itemTypes(string $data, array $iinf): array {
        $version = ord($data[$iinf['body']]);
        $pos = $iinf['body'] + 4 + ($version === 0 ? 2 : 4); // skip entry_count
        $types = [];

        while ($pos + 8 <= $iinf['end']) {
            $box = $this->boxAt($data, $pos, $iinf['end']);
            if ($box === null) {
                break;
            }
            if ($box['type'] === 'infe') {
                $infeVersion = ord($data[$box['body']]);
                $cursor = $box['body'] + 4;
                if ($infeVersion >= 2) {
                    $idSize = $infeVersion === 2 ? 2 : 4;
                    if ($cursor + $idSize + 6 <= $box['end']) {
                        $id = $this->readUint($data, $cursor, $idSize);
                        $types[$id] = substr($data, $cursor + $idSize + 2, 4);
                    }
                }
            }
            $pos = $box['end'];
        }

        return $types;
    }

    /** @return array{start:int, body:int, end:int, type:string}|null */
    private function findBox(string $data, int $from, int $to, string $type): ?array {
        $pos = $from;
        while ($pos + 8 <= $to) {
            $box = $this->boxAt($data, $pos, $to);
            if ($box === null) {
                return null;
            }
            if ($box['type'] === $type) {
                return $box;
            }
            $pos = $box['end'];
        }

        return null;
    }

    /** @return array{start:int, body:int, end:int, type:string}|null */
    private function boxAt(string $data, int $pos, int $limit): ?array {
        if ($pos + 8 > $limit) {
            return null;
        }
        $size = unpack('N', substr($data, $pos, 4))[1];
        $type = substr($data, $pos + 4, 4);
        $header = 8;

        if ($size === 1) {
            if ($pos + 16 > $limit) {
                return null;
            }
            $size = $this->readUint($data, $pos + 8, 8);
            $header = 16;
        } elseif ($size === 0) {
            $size = $limit - $pos;
        }

        if ($size < $header || $pos + $size > $limit) {
            return null;
        }

        return ['start' => $pos, 'body' => $pos + $header, 'end' => $pos + $size, 'type' => $type];
    }

    private function readUint(string $data, int $pos, int $bytes): int {
        return match ($bytes) {
            2 => unpack('n', substr($data, $pos, 2))[1],
            4 => unpack('N', substr($data, $pos, 4))[1],
            default => unpack('J', substr($data, $pos, 8))[1],
        };
    }
}
