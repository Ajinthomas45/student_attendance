import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String subjectId;
  final String studentId;
  final DateTime date;
  final bool isPresent;

  Attendance({
    required this.id,
    required this.subjectId,
    required this.studentId,
    required this.date,
    required this.isPresent,
  });

  factory Attendance.fromMap(Map<String, dynamic> map, String docId) {
    return Attendance(
      id: docId,
      subjectId: map['subjectId'],
      studentId: map['studentId'],
      date: (map['date'] as Timestamp).toDate(),
      isPresent: map['isPresent'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'studentId': studentId,
      'date': date,
      'isPresent': isPresent,
    };
  }
}
