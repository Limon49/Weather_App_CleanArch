import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLogin = true;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Login" : "Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: pass, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                setState(() => loading = true);
                try {
                  if (isLogin) {
                    await auth.signIn(email.text.trim(), pass.text);
                  } else {
                    await auth.signUp(email.text.trim(), pass.text);
                  }
                } catch (e) {
                  Get.snackbar("Auth error", e.toString());
                } finally {
                  setState(() => loading = false);
                }
              },
              child: Text(loading ? "..." : (isLogin ? "Login" : "Create account")),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Need an account? Sign up" : "Have an account? Login"),
            )
          ],
        ),
      ),
    );
  }
}
