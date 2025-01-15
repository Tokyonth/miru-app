import 'package:get/get.dart';
import 'package:miru_app/utils/request.dart';

class AboutController extends GetxController {
  final contributors = [].obs;

  final links = {
    'Github': 'https://github.com/miru-project/miru-app',
    'Telegram Group': 'https://t.me/MiruChat',
    'Website': 'https://miru.js.org',
    'F-Droid': 'https://f-droid.org/zh_Hans/packages/miru.miaomint/',
  };

  final moruLink = "https://github.com/Tokyonth/moru-app";

  _getContributors() async {
    final res = await dio
        .get("https://api.github.com/repos/miru-project/miru-app/contributors");
    contributors.value = List.from(res.data)
        .where((element) => element["type"] == "User")
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _getContributors();
  }
}
