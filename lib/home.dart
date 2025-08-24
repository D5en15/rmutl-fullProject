import 'package:flutter/material.dart';
import 'setting.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeContent(),        
    SettingScreen(name: "John Smith", role: "User"),  // ✅ ส่งค่า name & role
    MessageScreen(),      
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF3D5CFF),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Transform.translate(
                offset: const Offset(0, -30),
                child: _buildProgressCard(),
              ),
              const SizedBox(height: 10),
              _buildSection("Career advice", [
                _buildCard(Icons.work, 'View career',
                    'Look at careers that interest you.', 'Enter'),
                const SizedBox(height: 12),
                _buildCard(Icons.poll, 'Survey',
                    'Take the survey to find the right career.', 'Log In'),
              ]),
              const SizedBox(height: 20),
              _buildSection("Leader Board", [
                _buildCard(Icons.emoji_events, 'Score ranking',
                    'Rank individual learning.', 'View'),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ Header พร้อมคลิกโปรไฟล์แล้วไป SettingScreen(name, role)
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF3D5CFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Hi, Smith',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 4),
                Text("Let's start learning",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),

          // ✅ กดแล้วไปหน้า SettingScreen พร้อมส่ง name, role
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingScreen(name: "Smith", role: "User"),
                ),
              );
            },
            borderRadius: BorderRadius.circular(100),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child:
                    Icon(Icons.person, size: 30, color: Color(0xFF3D5CFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grade point average',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('46min / 60min',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text('My learning',
                  style: TextStyle(color: Color(0xFF3D5CFF))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const LinearProgressIndicator(
              value: 46 / 60,
              backgroundColor: Colors.grey,
              color: Colors.orange,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(children: cards),
      ],
    );
  }

  Widget _buildCard(
      IconData icon, String title, String subtitle, String buttonText) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF3D5CFF)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5CFF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(buttonText,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ เพิ่มหน้า Message (mock UI)
class MessageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("📩 Messages for User",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
