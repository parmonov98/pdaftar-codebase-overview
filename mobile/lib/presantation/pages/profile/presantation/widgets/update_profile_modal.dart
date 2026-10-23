import 'dart:developer';

import 'package:pdaftaruz/core/imports/imports.dart';


class UpdateProfileModal extends ConsumerStatefulWidget {
  const UpdateProfileModal({super.key});

  @override
  ConsumerState<UpdateProfileModal> createState() => _UpdateProfileModalState();
}

class _UpdateProfileModalState extends ConsumerState<UpdateProfileModal> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(profileProvider.notifier);
    final state = ref.watch(profileProvider);

    return  Container(
        padding: EdgeInsets.only(
            top: 0.00.sh,
            left: 24.0.w,
            right: 24.0.w,
            // bottom: MediaQuery.of(context).viewInsets.bottom
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
                controller: notifier.nameController,
                textCapitalization: TextCapitalization.words,
                title: "${AppLocalization.getText(context)?.name}",
                labelText: "${AppLocalization.getText(context)?.name}"),
            /* 14.0.h.verticalSpace,
            CustomTextField(
                controller: notifier.emailController,
                title: "Email",
                labelText: "Email"),*/
            // 0.02.sh.verticalSpace,
            // CustomTextField(
            //   keyboardType: TextInputType.phone,
            //     controller: notifier.phoneController,
            //     title: "${AppLocalization.getText(context)?.phone_number}",
            //     labelText: "${AppLocalization.getText(context)?.phone_number}"),
            // const Spacer(),
            0.04.sh.verticalSpace,

            CustomButtonWidget(
              title: "${AppLocalization.getText(context)?.edit_accept}",
              isLoading: state.isUpdateLoading,
              onTap: () {
                log(LocalStorage.instance.getToken());
                notifier.update(
                  context: context,
                  userId: LocalStorage.instance.getID(),
                  imagePath: state.selectedImageFile,
                  success: () {
                    // Rasmni tozalash
                    notifier.clearSelectedImage();
                    // Profil ma'lumotlarini yangilash
                    notifier.getUserInfo();
                    // Modalni yopish
                    AppNavigator.pop();
                  });
              },
            ),
            0.04.sh.verticalSpace,
          ],
        ),
      );
  }
}
