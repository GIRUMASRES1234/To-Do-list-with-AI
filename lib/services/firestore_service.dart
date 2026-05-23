import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get taskCollection =>
      _db.collection("users").doc(userId).collection("tasks");

  Future<void> addTask(Map<String, dynamic> taskData) async {
    await taskCollection.add(taskData);
  }

  Stream<QuerySnapshot> getTasksStream() {
    return taskCollection.orderBy("createdAt", descending: true).snapshots();
  }

  Future<void> deleteTask(String taskId) async {
    await taskCollection.doc(taskId).delete();
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await taskCollection.doc(taskId).update(data);
  }
}
