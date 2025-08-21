import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _emailController = TextEditingController();

  // Helper method to check if roll or email exists
  Future<bool> _studentExists(String roll, String email) async {
    final rollQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('rollNumber', isEqualTo: roll)
        .get();

    if (rollQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roll number already registered')),
      );
      return true;
    }

    final emailQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('email', isEqualTo: email)
        .get();

    if (emailQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email already registered')),
      );
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2FC), // To match subject page background color
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: const Color(0xFF7951DB), // Changed to subject page's appbar color
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                ),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rollController,
                            decoration: const InputDecoration(
                              hintText: 'Roll Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(0),
                                ),
                              ),
                              contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7951DB), // Match subject page color
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () async {
                              final name = _nameController.text.trim();
                              final roll = _rollController.text.trim();
                              final email = _emailController.text.trim();

                              if (name.isEmpty || roll.isEmpty || email.isEmpty) {
                                return;
                              }

                              // Check if roll or email already exists
                              final exists = await _studentExists(roll, email);
                              if (exists) return;

                              // If unique, add student
                              await FirebaseFirestore.instance.collection('students').add({
                                'name': name,
                                'rollNumber': roll,
                                'email': email,
                              });

                              _nameController.clear();
                              _rollController.clear();
                              _emailController.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('students').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final student = doc.data() as Map<String, dynamic>;
                    final studentId = doc.id;
                    final name = student['name'] ?? 'Unknown';
                    final roll = student['rollNumber'] ?? '';
                    final email = student['email'] ?? '';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFF4F2FC), // Match subject page background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Roll No: $roll"),
                              Text("Email: $email"),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('students')
                                .doc(studentId)
                                .delete();
                          },
                        ),
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
