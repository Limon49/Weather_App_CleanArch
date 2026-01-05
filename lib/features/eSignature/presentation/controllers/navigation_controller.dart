import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt currentTabIndex = 1.obs;

  void setTab(int index) {
    currentTabIndex.value = index;
  }
}

