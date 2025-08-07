import 'package:flutter/material.dart';
import 'home.dart'; // ✅ Import หน้า Home
import 'register.dart'; // ✅ Import หน้า Register
import 'forgot_password.dart'; // ✅ Import หน้า Forgot Password

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Log In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: const Color.fromARGB(255, 230, 230, 230),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        leading: null, // ปิดลูกศรย้อนกลับ
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildTextField(controller: emailController, label: 'Username', isPassword: false),
            SizedBox(height: 15),
            _buildTextField(controller: passwordController, label: 'Password', isPassword: true),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ForgotPasswordScreen()), // ✅ นำทางไปหน้า Forgot Password
                  );
                },
                child: Text('Forget password?', style: TextStyle(color: Color.fromARGB(255, 180, 180, 180))),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if ((emailController.text == 'admin' && passwordController.text == '123456') || //กำหนดเงื่อนไขสำหรับการเข้าสู่ระบบ
                      emailController.text.isEmpty && passwordController.text.isEmpty) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()), // เข้าสู่หน้า HomeScreen
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid username or password')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3D5CFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Log In', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()), // ✅ ลิงก์ไปหน้า Register
                    );
                  },
                  child: Text('Sign up', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildDividerWithText(),
            SizedBox(height: 15),
            _buildSocialButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required bool isPassword}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscurePassword : false,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => obscurePassword = !obscurePassword),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDividerWithText() {
    return Row(
      children: [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Or login with'),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
          onPressed: () {},
        ),
        SizedBox(width: 20),
        IconButton(
          icon: Icon(Icons.facebook, size: 30, color: Color(0xFF3D5CFF)),
          onPressed: () {},
        ),
      ],
    );
  }
}
