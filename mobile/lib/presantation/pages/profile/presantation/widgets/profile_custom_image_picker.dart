import 'dart:developer';

import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/pdaftar_user_badge.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class CustomImagePicker extends StatefulWidget {
  final double? imageSize;
  final String? image;
  final double? height;
  final bool? editIcon;
  final bool isPDaftarUser;
  final Function? onTap;

  const CustomImagePicker(
      {super.key,
      this.height,
      this.imageSize,
      this.onTap,
      required this.isPDaftarUser,
      this.image,
      this.editIcon});

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    log(widget.image ?? "not found image");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.editIcon ?? false) {
          widget.onTap?.call();
        }
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: (widget.image?.isNotEmpty ?? false) &&
                      (widget.editIcon ?? false)
                  ? FadeInImage.assetNetwork(
                      placeholder: Assets.accountIconPng,
                      width: 85.sp,
                      height: 85.sp,
                      fit: BoxFit.cover,
                      image: widget.image ?? "",
                      imageErrorBuilder: (context, data, stacktrace) =>
                          Image.asset(
                        Assets.accountIconPng,
                        width: 85.sp,
                      ),
                    )
                  : CustomSvgWidgetAsset(
                      isFlag: true,
                      // Light placeholder glared on the dark header (#628).
                      context.isDark
                          ? Assets.accountDarkIconSvg
                          : Assets.accountIconSvg,
                      fit: BoxFit.contain,
                      size: 85.sp,
                    ),
            ),
          ),

          //   : CustomSvgWidgetAsset(
          //     isFlag: true,
          //     Assets.accountIconSvg,
          //     size: 50.sp,
          //     // blendMode: BlendMode.dst,
          //   ),
          // )

          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Visibility(
                visible: widget.editIcon ?? false,
                child: CustomSvgWidgetAsset(
                  Assets.cameraIconSvg,
                  size: 25.sp,
                  fit: BoxFit.contain,
                  blendMode: BlendMode.dst,
                )),
          ),
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: PdaftarUserBadge(
              isVisible: widget.isPDaftarUser,
              size: 12.sp,
            ),
          )
        ],
      ),
    );
  }
}
