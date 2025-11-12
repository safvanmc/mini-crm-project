import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';

class LeadsPageResult {
  const LeadsPageResult({
    required this.leads,
    required this.lastDocument,
  });

  final List<Lead> leads;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}

abstract class LeadsRepository {
  Stream<List<Lead>> watchLeads();
  Stream<List<Lead>> searchLeads(String query);
  Future<void> addLead(Lead lead);
  Future<LeadsPageResult> fetchLeadsPage({
    LeadStatus? status,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit,
  });
}

class LeadRepositoryException implements Exception {
  LeadRepositoryException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}
