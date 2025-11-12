import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_crm_project/features/leads/repo/firebase_leads_repository.dart';
import 'package:mini_crm_project/features/leads/repo/leads_repository.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirebaseLeadsRepository(firestore);
});
