import 'package:flutter/material.dart';
import 'login.dart'; // ✅ เพิ่ม import login

class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D5CFF),
        title: Text('Setting', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text("Smith", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 30),
            _buildSettingOption(context, "Edit Account"),
            _buildSettingOption(context, "Change Password"),
            _buildSettingOption(context, "Logout", isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingOption(BuildContext context, String title, {bool isLogout = false}) {
    return InkWell(
      onTap: () {
        if (isLogout) {
          // ✅ นำทางไปหน้า Login แล้วล้าง Stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        } else {
          // เพิ่มการนำทางไปยังหน้าที่ต้องการ
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, color: isLogout ? Colors.red : Colors.black),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
