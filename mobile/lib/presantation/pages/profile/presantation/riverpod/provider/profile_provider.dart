import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/riverpod/notifier/profile_notifier.dart';

import '../../../../../../injection.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) => ProfileNotifier(profileRepository));
