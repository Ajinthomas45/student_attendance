import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  String? selectedSubjectId;
  String? selectedSubjectName;
  bool _isLoading = false;
  Map<String, String> _studentNames = {};
  late Map<String, bool> _expandedByDate = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0FB),
      appBar: AppBar(
        title: Text(
          selectedSubjectName == null
              ? "Attendance History"
              : "History - ${selectedSubjectName!}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF7951db),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 26),
          onPressed: () {
            if (selectedSubjectId != null) {
              setState(() {
                selectedSubjectId = null;
                selectedSubjectName = null;
              });
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedSubjectId == null
          ? _buildSubjectsList()
          : _buildAttendanceDates(),
    );
  }

  Future<Map<String, String>> _loadStudentNames() async {
    final snapshot = await FirebaseFirestore.instance.collection('students').get();
    final Map<String, String> names = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('name')) {
        names[doc.id] = data['name'];
      } else {
        names[doc.id] = 'Unknown';
      }
    }
    return names;
  }

  Widget _buildSubjectsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No subjects added yet.'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final subjectName = data.containsKey('name') ? data['name'] : 'Unknown';
            final subjectId = doc.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.09),
                    blurRadius: 20,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 25),
                title: Text(
                  subjectName.toLowerCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5636B9),
                    fontSize: 21,
                    letterSpacing: 0.5,
                  ),
                ),
                trailing: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EAFE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF7951db),
                    size: 21,
                  ),
                ),
                onTap: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  final names = await _loadStudentNames();
                  setState(() {
                    selectedSubjectId = subjectId;
                    selectedSubjectName = subjectName;
                    _studentNames = names;
                    _expandedByDate = {};
                    _isLoading = false;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceDates() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('subjectId', isEqualTo: selectedSubjectId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No attendance records yet.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7951db),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedSubjectId = null;
                      selectedSubjectName = null;
                    });
                  },
                  child: const Text('Back to Subjects', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          );
        }

        // Group docs by date as strings "yyyy-MM-dd"
        Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (!data.containsKey('date')) continue;
          final date = (data['date'] as Timestamp).toDate();
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          grouped.putIfAbsent(dateKey, () => []).add(doc);
        }

        final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final records = grouped[date]!;
            final isExpanded = _expandedByDate[date] ?? (index == 0);

            final presentStudents = records.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['isPresent'] ?? false) == true;
            }).toList();

            final absentStudents = records.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['isPresent'] ?? false) == false;
            }).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(19),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  )
                ],
              ),
              child: ExpansionTile(
                key: PageStorageKey(date),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _expandedByDate[date] = expanded;
                  });
                },
                tilePadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 21),
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(date)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7951db),
                      fontSize: 16,
                    ),
                  ),
                ),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade700,
                ),
                children: [
                  const Divider(height: 0, thickness: 1, indent: 8, endIndent: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 7, 22, 17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Present:", style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff29ae5d),
                        )),
                        if (presentStudents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 7, top: 6),
                            child: Text("None", style: TextStyle(color: Colors.grey)),
                          ),
                        ...presentStudents.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final studentId = data['studentId'] ?? '';
                          final studentName = _studentNames[studentId] ?? 'Unknown';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                ),
                                const Icon(Icons.check_circle, color: Color(0xff29ae5d), size: 22),
                                const SizedBox(width: 9),
                                const Text("Present", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        const Text("Absent:", style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xffec3a3a),
                        )),
                        if (absentStudents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 7, top: 6),
                            child: Text("None", style: TextStyle(color: Colors.grey)),
                          ),
                        ...absentStudents.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final studentId = data['studentId'] ?? '';
                          final studentName = _studentNames[studentId] ?? 'Unknown';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                ),
                                const Icon(Icons.cancel, color: Color(0xffec3a3a), size: 22),
                                const SizedBox(width: 9),
                                const Text("Absent", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
