import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileInitial {
  final String? username;
  final String? name;
  final String? email;
  final String? studentId; // ← map กับ user_code
  final String? className; // ← map กับ user_class
  final String? avatar;    // ← map กับ user_img (URL/asset)

  const EditProfileInitial({
    this.username,
    this.name,
    this.email,
    this.studentId,
    this.className,
    this.avatar,
  });
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.role,
    this.initial,
  });

  final String role;
  final EditProfileInitial? initial;

  static const _primary = Color(0xFF3D5CFF);
  static const _label = Color(0xFF8C8FA1);
  static const _border = Color(0xFFE5E7F0);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const double _headerH = 200;
  static const double _avatarR = 44;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _username =
      TextEditingController(text: widget.initial?.username ?? '');
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.initial?.email ?? '');
  late final TextEditingController _stuId =
      TextEditingController(text: widget.initial?.studentId ?? '');

  String? _classValue = '';
  String? _selectedAvatarRaw; // เก็บ raw (URL หรือ asset path)
  ImageProvider? _avatarPreview;

  String? _docId; // เก็บ docId ของคอลเลกชัน 'user' เพื่อใช้ update
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _classValue = widget.initial?.className;
    _selectedAvatarRaw = widget.initial?.avatar;
    _avatarPreview = _toImageProvider(_selectedAvatarRaw);
    _loadUserData(); // ✅ โหลดข้อมูลจริงจาก DB ใหม่
  }

  ImageProvider? _toImageProvider(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) {
      return NetworkImage(v);
    }
    // รองรับทั้ง 'assets/avatars/1.png' หรือ '1.png'
    if (v.startsWith('assets/')) {
      return AssetImage(v);
    }
    return AssetImage('assets/avatars/$v');
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _loading = true);

      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final authEmail = authUser.email;
      if (authEmail == null || authEmail.isEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบอีเมลของผู้ใช้จาก FirebaseAuth')),
        );
        return;
      }

      final qs = await FirebaseFirestore.instance
          .collection('user') // ← คอลเลกชันตามสคีมาใหม่
          .where('user_email', isEqualTo: authEmail)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _email.text = authEmail; // อย่างน้อยให้เห็นอีเมล
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ในฐานข้อมูลใหม่')),
        );
        return;
      }

      final doc = qs.docs.first;
      final data = doc.data();

      _docId = doc.id;

      final fullname  = data['user_fullname'] as String?;
      final username  = data['user_name'] as String?;
      final email     = data['user_email'] as String?;
      final userCode  = data['user_code'] as String?;   // ← Student ID
      final className = data['user_class'] as String?;
      final userImg   = data['user_img'] as String?;

      if (!mounted) return;
      setState(() {
        _name.text = fullname ?? '';
        _username.text = username ?? '';
        _email.text = email ?? authEmail;
        _stuId.text = userCode ?? '';
        _classValue = className;
        _selectedAvatarRaw = userImg;
        _avatarPreview = _toImageProvider(userImg);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint("Error loading user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _email.dispose();
    _stuId.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอกข้อมูล';
    return null;
  }

  InputDecoration _decoration(String hint,
          {bool readOnly = false, Color? fillColor}) =>
      InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: fillColor ?? (readOnly ? Colors.grey.shade200 : Colors.white),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EditProfilePage._border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EditProfilePage._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: EditProfilePage._primary, width: 1.5),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            color: EditProfilePage._label,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบเอกสารผู้ใช้ในฐานข้อมูล')),
      );
      return;
    }

    try {
      // เตรียมค่าที่จะบันทึกกลับสคีมาใหม่
      final Map<String, dynamic> payload = {
        'user_name': _username.text.trim(),
        'user_fullname': _name.text.trim(),
        'user_class': _classValue,
        'user_img': _selectedAvatarRaw, // raw (URL หรือ asset path)
      };

      // เฉพาะนักศึกษาเท่านั้นที่บังคับให้มี user_code (Student ID)
      final isStudent = widget.role.toLowerCase() == 'student';
      if (isStudent) {
        payload['user_code'] =
            _stuId.text.trim().isEmpty ? null : _stuId.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('user')
          .doc(_docId)
          .update(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    final chosenKey = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เลือก Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 20,
            itemBuilder: (context, index) {
              final file = '${index + 1}.png';
              final assetPath = 'assets/avatars/$file';
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, assetPath),
                child: CircleAvatar(
                  backgroundImage: AssetImage(assetPath),
                  radius: 30,
                ),
              );
            },
          ),
        ),
      ),
    );

    if (chosenKey != null) {
      setState(() {
        _selectedAvatarRaw = chosenKey;      // เก็บเป็น asset path
        _avatarPreview = _toImageProvider(chosenKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.role.toLowerCase() == 'student';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: _headerH,
                  width: double.infinity,
                  color: EditProfilePage._primary,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16, _avatarR + 24, 16, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Username'),
                                TextFormField(
                                  controller: _username,
                                  validator: _required,
                                  decoration: _decoration('Username'),
                                ),
                                const SizedBox(height: 14),

                                _label('Name'),
                                TextFormField(
                                  controller: _name,
                                  validator: _required,
                                  decoration: _decoration('Name'),
                                ),
                                const SizedBox(height: 14),

                                _label('Email'),
                                TextFormField(
                                  controller: _email,
                                  readOnly: true,
                                  decoration: _decoration(
                                    'Email',
                                    readOnly: true,
                                    fillColor: Colors.grey.shade200,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                if (isStudent) ...[
                                  _label('Student ID'),
                                  TextFormField(
                                    controller: _stuId,
                                    validator: _required,
                                    decoration: _decoration('Student ID'),
                                  ),
                                  const SizedBox(height: 14),

                                  _label('Class'),
                                  DropdownButtonFormField<String>(
                                    value: _classValue,
                                    decoration: _decoration('Class'),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'SE-3/1', child: Text('SE-3/1')),
                                      DropdownMenuItem(
                                          value: 'SE-3/2', child: Text('SE-3/2')),
                                      DropdownMenuItem(
                                          value: 'SE-4/1', child: Text('SE-4/1')),
                                    ],
                                    onChanged: (v) => setState(() => _classValue = v),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'กรุณาเลือกชั้นเรียน'
                                        : null,
                                  ),
                                  const SizedBox(height: 18),
                                ],

                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: EditProfilePage._primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _submit,
                                    child: const Text(
                                      'Submit',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),

            // ✅ Avatar + ปุ่มแก้ไข
            Positioned(
              top: _headerH - _avatarR,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: _avatarR,
                      backgroundImage: _avatarPreview,
                      backgroundColor: const Color(0xFFE9ECFF),
                      child: _avatarPreview == null
                          ? const Icon(Icons.person,
                              size: 34, color: Color(0xFF4B5563))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              size: 18, color: EditProfilePage._primary),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
