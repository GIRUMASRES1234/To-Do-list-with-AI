import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _taskCollection => FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .collection("tasks");

  // ✅ Add Task (with category, priority, dueDate)
  Future<void> addTask(
    String title,
    String description, {
    required String category,
    required String priority,
    String? dueDate,
  }) async {
    await _taskCollection.add({
      "title": title,
      "description": description,
      "category": category,
      "priority": priority,
      "dueDate": dueDate,
      "isCompleted": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // ✅ Get Tasks Stream
  Stream<QuerySnapshot> getTasks() {
    return _taskCollection.orderBy("createdAt", descending: true).snapshots();
  }

  // ✅ Toggle Complete
  Future<void> toggleTaskStatus(String taskId, bool value) async {
    await _taskCollection.doc(taskId).update({"isCompleted": value});
  }

  // ✅ Delete Task
  Future<void> deleteTask(String taskId) async {
    await _taskCollection.doc(taskId).delete();
  }

  // ✅ Update Task Title + Description
  Future<void> updateTask(
    String taskId,
    String title,
    String description,
  ) async {
    await _taskCollection.doc(taskId).update({
      "title": title,
      "description": description,
    });
  }

  Future<void> addGeneratedTask(Map<String, dynamic> task) async {
    await _taskCollection.add({
      "title": task["title"],
      "description": task["description"],
      "category": task["category"],
      "priority": task["priority"],
      "dueDate": null,
      "isCompleted": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
