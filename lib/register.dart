import 'package:flutter/material.dart';
import 'verify_email.dart'; // เพิ่ม import

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isChecked = false;

  final List<String> forbiddenUsernames = [
    'admin',
    'admin123456',
    'adim',
  ];

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  bool isStrongPassword(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  bool containsForbiddenWord(String input) {
    final inputLower = input.toLowerCase();
    return forbiddenUsernames.any((word) => inputLower.contains(word));
  }

  void _onRegister() {
    String email = usernameController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    String fullName = nameController.text.trim();

    if (email.isEmpty || fullName.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (!isValidEmail(email)) {
      _showSnackBar("Please enter a valid email address");
      return;
    }

    if (containsForbiddenWord(email)) {
      _showSnackBar("Email contains restricted words");
      return;
    }

    if (containsForbiddenWord(fullName)) {
      _showSnackBar("Full name contains restricted words");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match");
      return;
    }

    if (!isStrongPassword(password)) {
      _showSnackBar(
        "Password must be at least 8 characters and include uppercase, lowercase, number, and special character.\nExample: MyP@ssw0rd!",
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyEmailScreen(email: email),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2D),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your details below & free sign up',
                  style: TextStyle(fontSize: 14, color: Color(0xFFB4B4C6)),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: usernameController,
                  label: 'Email',
                  hintText: 'example@email.com',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: nameController,
                  label: 'Full name',
                  hintText: 'e.g. John Doe',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: passwordController,
                  label: 'Password',
                  isPassword: true,
                  obscureText: obscurePassword,
                  toggleObscure: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use at least 8 characters with upper, lower case, number, and symbol.\nExample: MyP@ssw0rd!',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB4B4C6)),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: confirmPasswordController,
                  label: 'Confirm password',
                  isPassword: true,
                  obscureText: obscureConfirmPassword,
                  toggleObscure: () =>
                      setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (value) =>
                          setState(() => isChecked = value ?? false),
                      activeColor: const Color(0xFF3D5CFF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    const Expanded(
                      child: Text(
                        'By creating an account you agree to our terms & conditions.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFB4B4C6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isChecked ? _onRegister : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5CFF),
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                          style: TextStyle(fontSize: 13)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // กลับไปหน้า login
                        },
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Color(0xFF3D5CFF),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A6A))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFB4B4C6)),
            filled: true,
            fillColor: const Color(0xFFF7F7FA),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFB4B4C6),
                    ),
                    onPressed: toggleObscure,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
