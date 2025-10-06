import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ClassroomsManagePage extends StatefulWidget {
  const ClassroomsManagePage({super.key});

  @override
  State<ClassroomsManagePage> createState() => _ClassroomsManagePageState();
}

class _ClassroomsManagePageState extends State<ClassroomsManagePage> {
  final _db = FirebaseFirestore.instance;
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  // ✅ สร้าง room_id อัตโนมัติ (เริ่มจาก 001)
  Future<String> _generateNextRoomId() async {
    final snap = await _db.collection('classroom').orderBy('room_id').get();
    if (snap.docs.isEmpty) return '001';

    final lastId = snap.docs.last['room_id'] ?? '000';
    final nextNum = int.tryParse(lastId) ?? 0;
    return (nextNum + 1).toString().padLeft(3, '0');
  }

  // ✅ เพิ่มห้องเรียน
  Future<void> _addRoom() async {
    final roomName = _nameCtrl.text.trim();
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a room name.")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final newId = await _generateNextRoomId();

      await _db.collection('classroom').doc(newId).set({
        'room_id': newId,
        'room_name': roomName,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Classroom added successfully.")),
      );
      _nameCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ✅ ลบห้องเรียน
  Future<void> _deleteRoom(String id) async {
    try {
      await _db.collection('classroom').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room deleted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete room.")),
      );
    }
  }

  // ✅ แก้ไขชื่อห้องเรียน
  Future<void> _editRoom(String id, String currentName) async {
    final nameCtrl = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Classroom'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Room Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              await _db.collection('classroom').doc(id).update({
                'room_name': newName,
              });
              if (context.mounted) context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Room name updated.")),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Classrooms'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Classroom",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Room Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loading ? null : _addRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5CFF),
                    foregroundColor: Colors.white, // ✅ ตัวอักษรสีขาว
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Existing Classrooms",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('classroom')
                    .orderBy('room_id', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No classrooms found."));
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final id = data['room_id'] ?? '';
                      final name = data['room_name'] ?? '';

                      return ListTile(
                        leading: const Icon(Icons.meeting_room_outlined,
                            color: Color(0xFF3D5CFF)),
                        title: Text(
                          name, // ✅ แสดงเฉพาะชื่อห้อง
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.orange),
                              onPressed: () => _editRoom(id, name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteRoom(id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}