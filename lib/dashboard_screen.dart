import 'package:flutter/material.dart';

import 'subjects.dart';
import 'students.dart';
import 'attendance_history_page.dart';
import 'subject_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  Subject? selectedSubject; // store selected subject

  late AnimationController _profileController;
  late Animation<Offset> _profileOffset;
  late AnimationController _cardsController;
  List<Animation<Offset>> _cardOffsets = [];

  @override
  void initState() {
    super.initState();

    _profileController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _profileOffset = Tween(begin: const Offset(-1.5, 0), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _profileController,
      curve: Curves.easeOut,
    ));

    _cardsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    const delayStep = 0.2;
    for (int i = 0; i < 3; i++) {
      final start = i * delayStep;
      final end = start + 0.5;
      _cardOffsets.add(Tween(begin: const Offset(-1.5, 0), end: Offset.zero)
          .animate(CurvedAnimation(
          parent: _cardsController,
          curve: Interval(start, end, curve: Curves.easeOut))));
    }

    _profileController.forward().then((_) => _cardsController.forward());
  }

  @override
  void dispose() {
    _profileController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // AppBar
          Container(
            height: size.height * 0.25,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF512DA8)]),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5))
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.menu,
                            color: Colors.white, size: isTablet ? 34 : 28),
                        Text('St Philomena College',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 26 : 20,
                                fontWeight: FontWeight.w900)),
                        Icon(Icons.notifications_none,
                            color: Colors.white, size: isTablet ? 34 : 28),
                      ],
                    ),
                    SizedBox(height: size.height * 0.025),
                    SlideTransition(
                      position: _profileOffset,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 14 : 10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          children: [
                            CircleAvatar(
                                radius: isTablet ? 36 : 28,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person,
                                    color: Colors.purple.shade700,
                                    size: isTablet ? 40 : 32)),
                            SizedBox(width: size.width * 0.04),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ajin Thomas',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 20 : 16,
                                        fontWeight: FontWeight.w800)),
                                Text('ajin.example@mail.com',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isTablet ? 16 : 12)),
                                Text('+91 111 1111 111',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isTablet ? 16 : 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body cards
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(size.width * 0.06),
              child: GridView.count(
                crossAxisCount: isTablet ? 2 : 1,
                mainAxisSpacing: size.height * 0.025,
                crossAxisSpacing: size.width * 0.05,
                childAspectRatio: isTablet ? 3 : 3.5,
                children: [
                  _buildAnimatedCard(
                    index: 0,
                    title: 'Subjects',
                    icon: Icons.book,
                    gradientColors: const [
                      Color(0xFF7B1FA2),
                      Color(0xFF9C27B0),
                      Color(0xFFE040FB)
                    ],
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SubjectsPage()),
                      );
                      if (result != null && result is Subject) {
                        setState(() {
                          selectedSubject = result;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "Selected subject: ${result.name}")));
                      }
                    },
                  ),
                  _buildAnimatedCard(
                    index: 1,
                    title: 'Students',
                    icon: Icons.group,
                    gradientColors: const [
                      Color(0xFF283593),
                      Color(0xFF3949AB),
                      Color(0xFF5C6BC0)
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentsPage(),
                        ),
                      );
                    },
                  ),
                  _buildAnimatedCard(
                    index: 2,
                    title: 'Attendance History',
                    icon: Icons.check_circle,
                    gradientColors: const [
                      Color(0xFF2E7D32),
                      Color(0xFF43A047),
                      Color(0xFF66BB6A)
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AttendanceHistoryPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({
    required int index,
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return SlideTransition(
      position: _cardOffsets[index],
      child: _buildDashboardCard(
        title: title,
        icon: icon,
        gradientColors: gradientColors,
        onTap: onTap,
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: gradientColors.last.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(4, 6)),
            BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(-2, -2)),
          ],
        ),
        padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06, vertical: size.height * 0.025),
        child: Row(
          children: [
            CircleAvatar(
                radius: isTablet ? 36 : 30,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(icon,
                    size: isTablet ? 36 : 28, color: Colors.white)),
            SizedBox(width: size.width * 0.06),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: isTablet ? 22 : 18),
          ],
        ),
      ),
    );
  }
}
