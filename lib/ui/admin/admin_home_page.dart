import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: const [
              _BlueHeader(),
              _Body(),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Design tokens ----------
class _T {
  static const primary = Color(0xFF3D5CFF);
  static const muted = Color(0xFF858597);
  static const cardBorder = Color(0xFFEFF1F7);
  static const soft = Color(0xFFF6F7FF);
  static const shadow = Color(0x0D000000);
}

/// ---------- BLUE HEADER ----------
class _BlueHeader extends StatelessWidget {
  const _BlueHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: _T.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Hi, Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
              SizedBox(height: 4),
              Text("Let's start managing",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => context.go('/admin/notifications'),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => context.go('/admin/profile'),
              borderRadius: BorderRadius.circular(24),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black54, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- BODY ----------
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Expanded(
                child: _InfoCard(
                  icon: Icons.groups_2_outlined,
                  value: '244',
                  label: 'Total users',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.person_outline,
                  value: '180',
                  label: 'Students',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _InfoCard(
                  icon: Icons.school_outlined,
                  value: '42',
                  label: 'Teachers',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.admin_panel_settings_outlined,
                  value: '22',
                  label: 'Admins',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Text('Select role',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),

          // Dropdown (role)
          Container(
            decoration: BoxDecoration(
              color: _T.soft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'All roles',
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                isExpanded: true,
                items: const [
                  'All roles', 'Student', 'Teacher', 'Admin'
                ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (_) {},
              ),
            ),
          ),

          const SizedBox(height: 12),

          // CTA
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/admin/users'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Go to User List'),
            ),
          ),

          const SizedBox(height: 18),

          // Rings
          Row(
            children: const [
              Expanded(
                child: _RingCard(
                  title: 'Active users',
                  percentText: '72%',
                  percent: .72,
                  showAlertNote: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _RingCard(
                  title: 'Moderation pass',
                  percentText: '89%',
                  percent: .89,
                  showAlertNote: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const _UserGrowthCard(),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.value, required this.label});
  final IconData icon; final String value; final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.cardBorder),
        boxShadow: const [BoxShadow(color: _T.shadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _T.soft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _T.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: _T.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingCard extends StatelessWidget {
  const _RingCard({required this.title, required this.percentText, required this.percent, required this.showAlertNote});
  final String title, percentText; final double percent; final bool showAlertNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.cardBorder),
        boxShadow: const [BoxShadow(color: _T.shadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          SizedBox(
            width: 58, height: 58,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: percent.clamp(0, 1), strokeWidth: 7,
                backgroundColor: _T.cardBorder, color: _T.primary,
              ),
              Center(child: Text(percentText, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                if (showAlertNote)
                  Row(children: const [
                    Icon(Icons.circle, size: 8, color: Color(0xFFFF7A50)),
                    SizedBox(width: 6),
                    Text('Some alerts', style: TextStyle(fontSize: 12, color: _T.muted)),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserGrowthCard extends StatelessWidget {
  const _UserGrowthCard();

  @override
  Widget build(BuildContext context) {
    const data = [1.0, 1.6, 2.2, 2.0, 2.8, 3.6];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.cardBorder),
        boxShadow: const [BoxShadow(color: _T.shadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User growth', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(height: 170, width: double.infinity, child: CustomPaint(painter: _LineChartPainter(data))),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.data);
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFEFF1F7)..strokeWidth = 1;
    final border = Paint()..color = const Color(0xFFE1E3EC)..strokeWidth = 1;
    const steps = 4;
    for (var i = 0; i <= steps; i++) {
      final y = size.height * (i / steps);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i == steps ? border : grid);
    }

    const maxY = 4.0, minY = 0.0;
    final dx = size.width / (data.length - 1);
    final path = Path();
    final line = Paint()
      ..color = _T.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = _T.primary;

    for (var i = 0; i < data.length; i++) {
      final x = i * dx;
      final v = data[i].clamp(minY, maxY);
      final y = size.height - ((v - minY) / (maxY - minY)) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 3.5, dot);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.data != data;
}
