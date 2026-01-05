import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  LoginController get controller => Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isLogin.value ? "Login" : "Sign Up")),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.authenticate(
                        emailController.text.trim(),
                        passwordController.text,
                      ),
              child: Text(
                controller.isLoading.value
                    ? "..."
                    : (controller.isLogin.value ? "Login" : "Create account"),
              ),
            )),
            Obx(() => TextButton(
              onPressed: controller.toggleMode,
              child: Text(
                controller.isLogin.value
                    ? "Need an account? Sign up"
                    : "Have an account? Login",
              ),
            )),
          ],
        ),
      ),
    );
  }
}
