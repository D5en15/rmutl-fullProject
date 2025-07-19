import 'package:flutter/material.dart';
import 'new_password.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  List<String> code = ['', '', '', ''];
  bool isVerifying = false;

  void _addDigit(String digit) {
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '') {
        setState(() {
          code[i] = digit;
        });
        break;
      }
    }
  }

  void _removeDigit() {
    for (int i = code.length - 1; i >= 0; i--) {
      if (code[i] != '') {
        setState(() {
          code[i] = '';
        });
        break;
      }
    }
  }

  Future<void> _verifyCode() async {
    String enteredCode = code.join('');

    if (enteredCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 4-digit code")),
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      // 🔄 จุดนี้คุณสามารถเปลี่ยนเป็นเรียก API ไปยัง backend
      // เช่น await AuthService.verifyOTP(email: widget.email, code: enteredCode);

      // จำลองว่าตรวจสอบสำเร็จ (เปลี่ยนส่วนนี้เป็นของจริงภายหลัง)
      await Future.delayed(const Duration(seconds: 1));

      // หากรหัสถูกต้อง
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordScreen(email: widget.email),
        ),
      );
    } catch (e) {
      // หากตรวจสอบไม่ผ่าน
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification failed")),
      );
    } finally {
      setState(() => isVerifying = false);
    }
  }

  Widget _buildCodeBox(String value) {
    return Container(
      width: 56,
      height: 70,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _addDigit(number),
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(35),
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: AppBar(
        title: const Text("Verify Email"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                "Code is sent to ${widget.email}",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: code.map((digit) => _buildCodeBox(digit)).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isVerifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5CFF),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verify",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (int i = 1; i <= 9; i++) _buildNumberButton(i.toString()),
                  _buildNumberButton('0'),
                  GestureDetector(
                    onTap: _removeDigit,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDED),
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: const Icon(Icons.backspace_outlined, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
