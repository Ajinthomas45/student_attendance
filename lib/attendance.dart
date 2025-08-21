import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

// Replace with your real DashboardScreen import
import 'dashboard_screen.dart';

DateTime getToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool isFutureDate(DateTime date) {
  final today = getToday();
  final check = DateTime(date.year, date.month, date.day);
  return check.isAfter(today);
}

class AttendancePage extends StatefulWidget {
  final String subjectId;

  const AttendancePage({super.key, required this.subjectId});

  @override
  State createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Map<String, bool> _attendanceMap = {};
  Map<String, String> _attendanceRecordIds = {}; // studentId -> docId
  DateTime _focusedDay = getToday();
  DateTime _selectedDay = getToday();

  bool _isEditMode = false;
  bool _attendanceExists = false;
  bool _loading = false;

  final Color deepPurple = const Color(0xFF7956EA);
  final Color deepPurpleLight = const Color(0xFF9379FE);

  bool get _canMarkAttendance {
    return !isFutureDate(_selectedDay) && (_isEditMode || !_attendanceExists);
  }

  @override
  void initState() {
    super.initState();
    _loadAttendanceForDay(_selectedDay);
  }

  Future<void> _loadAttendanceForDay(DateTime date) async {
    setState(() {
      _loading = true;
      _isEditMode = false;
    });

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('subjectId', isEqualTo: widget.subjectId)
        .where('date', isGreaterThanOrEqualTo: dayStart)
        .where('date', isLessThan: dayEnd)
        .get();

    Map<String, bool> attendanceData = {};
    Map<String, String> recordIds = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      attendanceData[data['studentId']] = data['isPresent'] ?? false;
      recordIds[data['studentId']] = doc.id;
    }

    setState(() {
      _attendanceMap = attendanceData;
      _attendanceRecordIds = recordIds;
      _attendanceExists = snapshot.docs.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _saveAttendance() async {
    if (_loading) return;

    if (isFutureDate(_selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot mark attendance for future dates.')));
      return;
    }

    setState(() {
      _loading = true;
    });

    final attendanceDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    // Fetch subject name once before batch
    final subjectDoc = await FirebaseFirestore.instance.collection('subjects').doc(widget.subjectId).get();
    final subjectName = subjectDoc.data()?['name'] ?? 'Unknown Subject';

    final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
    final batch = FirebaseFirestore.instance.batch();

    final existingSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('subjectId', isEqualTo: widget.subjectId)
        .where('date', isEqualTo: attendanceDate)
        .get();

    Map<String, DocumentSnapshot> existingRecords = {};
    for (var doc in existingSnapshot.docs) {
      final data = doc.data();
      existingRecords[data['studentId']] = doc;
    }

    for (var studentDoc in studentsSnapshot.docs) {
      final studentId = studentDoc.id;
      final studentName = studentDoc.data()['name'] ?? 'Unknown Student';
      final isPresent = _attendanceMap[studentId] ?? false;

      if (existingRecords.containsKey(studentId)) {
        batch.update(existingRecords[studentId]!.reference, {
          'isPresent': isPresent,
          'studentName': studentName,
          'subjectName': subjectName,
        });
      } else {
        final docRef = FirebaseFirestore.instance.collection('attendance').doc();
        batch.set(docRef, {
          'studentId': studentId,
          'studentName': studentName,
          'subjectId': widget.subjectId,
          'subjectName': subjectName,
          'date': attendanceDate,
          'isPresent': isPresent,
        });
      }
    }

    await batch.commit();

    setState(() {
      _loading = false;
      _isEditMode = false;
      _attendanceExists = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_attendanceExists ? 'Attendance updated' : 'Attendance saved')));

    await _loadAttendanceForDay(_selectedDay);

    // Wait for 1.5 seconds, then navigate to dashboard
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => DashboardScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 23,
        )),
        backgroundColor: deepPurple,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 27),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (_attendanceExists && !_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit attendance',
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Editing enabled')));
              },
            )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [deepPurple, deepPurpleLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(color: deepPurple.withOpacity(0.13), blurRadius: 30, offset: const Offset(0, 12))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: TableCalendar(
                  locale: 'en_US',
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2050, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.week,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (isFutureDate(selectedDay)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cannot mark attendance for future dates.')));
                      return;
                    }
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _loadAttendanceForDay(selectedDay);
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronVisible: false,
                    rightChevronVisible: false,
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Colors.white),
                    holidayTextStyle: const TextStyle(color: Colors.yellow),
                    todayDecoration: BoxDecoration(
                      color: deepPurpleLight,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(color: Colors.black),
                    selectedTextStyle: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 0, 20),
                  child: Text('Mark Attendance',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22)))),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('students').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final students = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final studentDoc = students[index];
                    final studentId = studentDoc.id;
                    final data = studentDoc.data() as Map<String, dynamic>;
                    final studentName = data['name'] ?? 'Unknown';

                    final isPresent = _attendanceMap[studentId] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: deepPurple,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: deepPurple.withOpacity(0.13), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: deepPurpleLight,
                          child: Text(studentName.isNotEmpty ? studentName[0] : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                        ),
                        title: Text(studentName,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text('Student ID: $studentId',
                            style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14)),
                        trailing: AbsorbPointer(
                          absorbing: !_isEditMode && _attendanceExists,
                          child: Opacity(
                            opacity: (!_isEditMode && _attendanceExists) ? 0.7 : 1,
                            child: CustomAttendanceSwitch(
                              value: isPresent,
                              onChanged: (val) {
                                setState(() {
                                  _attendanceMap[studentId] = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 22),
                label: Text(_isEditMode ? 'Update Attendance' : 'Save Attendance',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 5),
                onPressed: (_isEditMode || !_attendanceExists) ? _saveAttendance : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomAttendanceSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomAttendanceSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: value ? const Color(0xff4ecc6c) : const Color(0xffb71c1c),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: value ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (value)
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                width: 28,
                height: 28,
                child: const Icon(Icons.check, color: Color(0xff4ecc6c), size: 20),
              ),
            if (!value)
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                width: 28,
                height: 28,
                child: const Icon(Icons.close, color: Color(0xffb71c1c), size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
