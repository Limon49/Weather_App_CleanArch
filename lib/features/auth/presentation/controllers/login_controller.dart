import 'package:get/get.dart';
import '../../data/auth_service.dart';

class LoginController extends GetxController {
  final AuthService authService = Get.find<AuthService>();

  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;

  void toggleMode() {
    isLogin.value = !isLogin.value;
  }

  Future<void> authenticate(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    isLoading.value = true;
    try {
      if (isLogin.value) {
        await authService.signIn(email.trim(), password);
      } else {
        await authService.signUp(email.trim(), password);
      }
    } catch (e) {
      Get.snackbar("Auth error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

