<?php

namespace App\Services\Dashboard;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Query\Builder as QueryBuilder;
use Illuminate\Support\Collection;

class TimePeriodService {
    public const PERIOD_DAILY = 'daily';

    public const PERIOD_WEEKLY = 'weekly';

    public const PERIOD_MONTHLY = 'monthly';

    public const PERIOD_YEARLY = 'yearly';

    /**
     * Get date range based on period type
     */
    public static function getDateRange(string $period, ?Carbon $startDate = null, ?Carbon $endDate = null): array {
        $end = $endDate ?? Carbon::now();
        $start = $startDate ?? match ($period) {
            self::PERIOD_DAILY => $end->copy()->subDays(30),
            self::PERIOD_WEEKLY => $end->copy()->subWeeks(12),
            self::PERIOD_MONTHLY => $end->copy()->subMonths(12),
            self::PERIOD_YEARLY => $end->copy()->subYears(5),
            default => $end->copy()->subMonths(12),
        };

        return [$start, $end];
    }

    /**
     * The SQL expression that buckets `$dateColumn` into `$period` — the same
     * keys fillMissingPeriods() produces, for queries built outside the
     * groupBy helpers (multi-series charts grouping by period AND a second
     * column).
     */
    public static function periodExpression(string $period, string $dateColumn = 'created_at'): string {
        return match ($period) {
            self::PERIOD_WEEKLY => "YEARWEEK({$dateColumn}, 1)",
            self::PERIOD_MONTHLY => "DATE_FORMAT({$dateColumn}, '%Y-%m')",
            self::PERIOD_YEARLY => "YEAR({$dateColumn})",
            default => "DATE({$dateColumn})",
        };
    }

    /**
     * Group query by time period
     *
     * @return Builder|QueryBuilder
     *
     * @phpstan-return Builder|QueryBuilder
     */
    public static function groupByPeriod(Builder $query, string $period, string $dateColumn = 'created_at') {
        return match ($period) {
            self::PERIOD_DAILY => $query->selectRaw("DATE({$dateColumn}) as period, COUNT(*) as count")
                ->groupBy('period')
                ->orderBy('period'),
            self::PERIOD_WEEKLY => $query->selectRaw("YEARWEEK({$dateColumn}, 1) as period, COUNT(*) as count")
                ->groupBy('period')
                ->orderBy('period'),
            self::PERIOD_MONTHLY => $query->selectRaw("DATE_FORMAT({$dateColumn}, '%Y-%m') as period, COUNT(*) as count")
                ->groupBy('period')
                ->orderBy('period'),
            self::PERIOD_YEARLY => $query->selectRaw("YEAR({$dateColumn}) as period, COUNT(*) as count")
                ->groupBy('period')
                ->orderBy('period'),
            default => $query->selectRaw("DATE({$dateColumn}) as period, COUNT(*) as count")
                ->groupBy('period')
                ->orderBy('period'),
        };
    }

    /**
     * Group query by time period with sum
     *
     * @return Builder|QueryBuilder
     *
     * @phpstan-return Builder|QueryBuilder
     */
    public static function groupByPeriodWithSum(Builder $query, string $period, string $sumColumn, string $dateColumn = 'created_at') {
        return match ($period) {
            self::PERIOD_DAILY => $query->selectRaw("DATE({$dateColumn}) as period, SUM({$sumColumn}) as total")
                ->groupBy('period')
                ->orderBy('period'),
            self::PERIOD_WEEKLY => $query->selectRaw("YEARWEEK({$dateColumn}, 1) as period, SUM({$sumColumn}) as total")
                ->groupBy('period')
                ->orderBy('period'),
            self::PERIOD_MONTHLY => $query->selectRaw("DATE_FORMAT({$dateColumn}, '%Y-%m') as period, SUM({$sumColumn}) as total")
                ->groupBy('period')
                ->orderBy('period'),
            self::PERIOD_YEARLY => $query->selectRaw("YEAR({$dateColumn}) as period, SUM({$sumColumn}) as total")
                ->groupBy('period')
                ->orderBy('period'),
            default => $query->selectRaw("DATE({$dateColumn}) as period, SUM({$sumColumn}) as total")
                ->groupBy('period')
                ->orderBy('period'),
        };
    }

    /**
     * Format period label for display
     */
    public static function formatPeriodLabel(string $period, string|int $periodValue): string {
        return match ($period) {
            self::PERIOD_DAILY => Carbon::parse($periodValue)->format('Y-m-d'),
            self::PERIOD_WEEKLY => self::formatWeekLabel($periodValue),
            // '!' zeroes the fields the format lacks. Without it the day is
            // taken from today, so on the 29th-31st '2026-02' became Feb 29-31,
            // overflowed into March, and the dashboard labelled February
            // "Mar 2026".
            self::PERIOD_MONTHLY => Carbon::createFromFormat('!Y-m', $periodValue)->format('M Y'),
            self::PERIOD_YEARLY => (string) $periodValue,
            default => (string) $periodValue,
        };
    }

    /**
     * Format week label from YEARWEEK value
     */
    protected static function formatWeekLabel(int|string $yearweek): string {
        $yearweekStr = (string) $yearweek;
        // YEARWEEK returns format like 202401 (year + week)
        // We need to extract year (first 4 digits) and week (remaining)
        if (strlen($yearweekStr) >= 6) {
            $year = (int) substr($yearweekStr, 0, 4);
            $week = (int) substr($yearweekStr, 4);
        } else {
            // Fallback for shorter strings
            $year = (int) date('Y');
            $week = (int) $yearweekStr;
        }

        try {
            $date = Carbon::now()->setISODate($year, $week, 1);

            return "Week {$week}, {$year}";
        } catch (\Exception $e) {
            return "Week {$week}, {$year}";
        }
    }

    /**
     * Fill missing periods in collection
     */
    public static function fillMissingPeriods(Collection $data, string $period, Carbon $start, Carbon $end): Collection {
        $filled = collect();

        // Anchor the cursor to the start of its bucket before stepping.
        // Stepping from the raw start date skipped short months — a window
        // starting Jan 29-31 never produced a February bucket (Jan 31
        // ->addMonth() overflows to Mar 3), so February's query rows were
        // dropped from the chart — and lost the final partial bucket whenever
        // the end's day fell before the start's day-of-month/-week/-time.
        $current = $start->copy();
        match ($period) {
            self::PERIOD_DAILY => $current->startOfDay(),
            self::PERIOD_WEEKLY => $current->startOfWeek(),
            self::PERIOD_MONTHLY => $current->startOfMonth(),
            self::PERIOD_YEARLY => $current->startOfYear(),
            default => $current->startOfDay(),
        };

        while ($current <= $end) {
            $periodKey = match ($period) {
                self::PERIOD_DAILY => $current->format('Y-m-d'),
                self::PERIOD_WEEKLY => (string) $current->format('oW'),
                self::PERIOD_MONTHLY => $current->format('Y-m'),
                self::PERIOD_YEARLY => (string) $current->year,
                default => $current->format('Y-m-d'),
            };

            $existing = $data->firstWhere('period', $periodKey);
            $filled->push($existing ?? ['period' => $periodKey, 'count' => 0, 'total' => 0]);

            match ($period) {
                self::PERIOD_DAILY => $current->addDay(),
                self::PERIOD_WEEKLY => $current->addWeek(),
                self::PERIOD_MONTHLY => $current->addMonth(),
                self::PERIOD_YEARLY => $current->addYear(),
                default => $current->addDay(),
            };
        }

        return $filled;
    }
}
