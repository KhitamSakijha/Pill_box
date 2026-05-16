import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool isDeafMute = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  CollectionReference users = FirebaseFirestore.instance.collection('users');
  //دالة اضافة بيانات المستخدم في الفير بيس داتا بيس
  Future<void> addUser(String uid) {
    return users
        .doc(uid)
        .set({
          'name': usernameController.text.trim(),
          'phone': phoneController.text.trim(),
          'isDeafMute': isDeafMute,
        })
        .then((value) => print("User Added"))
        .catchError((error) => print("Failed to add user: $error"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        title: const Text(
          "Create Account",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== شعار التطبيق =====
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Color(0xFF2196F3),
                  size: 40,
                ),
              ),

              // ===== الفورم =====
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _field(
                        label: "Username",
                        hint: "Enter your username",
                        controller: usernameController,
                        validator: (v) =>
                            v!.isEmpty ? "Username required" : null,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        label: "Phone Number",
                        hint: "Enter your phone",
                        controller: phoneController,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Can't be empty";
                          }
                          if (v.length != 10) {
                            return "The number is short";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      _field(
                        label: "Email",
                        hint: "Enter your email",
                        controller: emailController,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Email required";
                          if (!v.contains('@')) return "Enter a valid email";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _passwordField(
                        label: "Password",
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        toggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _passwordField(
                        label: "Confirm Password",
                        controller: confirmController,
                        obscureText: _obscureConfirm,
                        toggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Confirm password required";
                          }
                          if (v != passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: isDeafMute,
                            onChanged: (v) =>
                                setState(() => isDeafMute = v ?? false),
                          ),
                          const Text("I am Deaf / Mute"),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            try {
                              // 1️⃣ إنشاء الحساب
                              UserCredential credential = await FirebaseAuth
                                  .instance
                                  .createUserWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );

                              // 2️⃣ حفظ البيانات في Firestore
                              await addUser(credential.user!.uid);

                              // 3️⃣ إرسال رسالة التحقق
                              await credential.user!.sendEmailVerification();

                              // 4️⃣ رسالة تنبيه
                              AwesomeDialog(
                                context: context,
                                dialogType: DialogType.info,
                                animType: AnimType.rightSlide,
                                title: 'Verify your email',
                                desc:
                                    'A verification link has been sent to your email. Please verify your account before logging in.',
                                btnOkText: 'OK',
                                btnOkOnPress: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                              ).show();
                            } on FirebaseAuthException catch (e) {
                              String message = 'Something went wrong';

                              if (e.code == 'weak-password') {
                                message = 'The password provided is too weak.';
                              } else if (e.code == 'email-already-in-use') {
                                message =
                                    'The account already exists for that email.';
                              }

                              AwesomeDialog(
                                context: context,
                                dialogType: DialogType.error,
                                animType: AnimType.rightSlide,
                                title: 'Error',
                                desc: message,
                              ).show();
                            }
                          },
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator:
              validator ??
              (v) => v == null || v.isEmpty ? "$label required" : null,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: const Color(0xFFF1F3F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: toggleObscure,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F3F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
