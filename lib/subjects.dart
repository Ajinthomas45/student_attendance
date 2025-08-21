import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_model.dart';
import 'attendance.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final _nameController = TextEditingController();

  // Helper to check if subject name (case-insensitive) already exists
  Future<bool> _subjectNameExists(String name) async {
    final query = await FirebaseFirestore.instance
        .collection('subjects')
        .get();
    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final existingName = data['name'] as String? ?? '';
      if (existingName.toLowerCase() == name.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final lightCard = const Color(0xFFF4F2FC);
    final purple = const Color(0xFF7951db);

    return Scaffold(
      backgroundColor: lightCard,
      appBar: AppBar(
        title: const Text(
          'Subject',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        backgroundColor: purple,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Subject input + add button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(16),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Subject Name',
                        hintStyle: TextStyle(
                          color: Colors.deepPurple[200],
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Container(
                  height: 48,
                  width: 50,
                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: purple.withOpacity(0.09),
                          blurRadius: 7,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 26),
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;

                      // Check if subject name already exists (case-insensitive)
                      final exists = await _subjectNameExists(name);
                      if (exists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Subject name already exists.')),
                        );
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('subjects')
                          .add({'name': name});
                      _nameController.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
          // List of subjects
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No subjects added yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 15, left: 5, right: 5),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Safely get the name field to avoid exceptions
                    final subjectName =
                    data.containsKey('name') ? data['name'] as String : 'Unknown';

                    final subject = Subject(id: doc.id, name: subjectName);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.18),
                            blurRadius: 13,
                            offset: const Offset(0, 7),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                        title: Text(
                          subject.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7951db),
                            fontSize: 19,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 27),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('subjects')
                                    .doc(subject.id)
                                    .delete();
                              },
                            ),
                            const SizedBox(width: 7),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Color(0xFF7951db), size: 27),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AttendancePage(subjectId: subject.id)));
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context, subject);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
