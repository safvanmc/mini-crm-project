import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_crm_project/features/leads/data/models/lead_model.dart';
import 'package:mini_crm_project/features/leads/repo/leads_repository.dart';

class FirebaseLeadsRepository implements LeadsRepository {
  FirebaseLeadsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('leads');

  Stream<List<Lead>> _mapSnapshots(
    Stream<QuerySnapshot<Map<String, dynamic>>> snapshots, {
    required String failureMessage,
  }) {
    return snapshots.transform(
      StreamTransformer.fromHandlers(
        handleData: (snapshot, sink) {
          sink.add(snapshot.docs.map(Lead.fromDocument).toList());
        },
        handleError: (error, stackTrace, sink) {
          print(error);
          sink.addError(
            LeadRepositoryException(
              failureMessage,
              cause: error,
              stackTrace: stackTrace,
            ),
            stackTrace,
          );
        },
      ),
    );
  }

  @override
  Future<void> addLead(Lead lead) async {
    final payload = lead.toFirestorePayload();

    try {
      await _collection.add(payload);
    } on FirebaseException catch (error, stackTrace) {
      throw LeadRepositoryException(
        'Unable to save lead right now. Please try again.',
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      print(error);
      throw LeadRepositoryException(
        'An unexpected error occurred while saving the lead.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<List<Lead>> watchLeads() {
    final query = _collection.orderBy('createdAt', descending: true);
    return _mapSnapshots(
      query.snapshots(),
      failureMessage: 'Unable to load leads right now. Please try again.',
    );
  }

  @override
  Future<LeadsPageResult> fetchLeadsPage({
    LeadStatus? status,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _collection.orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.label);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();
      final docs = snapshot.docs;

      final leads = docs.map(Lead.fromDocument).toList(growable: false);
      final lastDocument = docs.isNotEmpty ? docs.last : startAfter;

      return LeadsPageResult(
        leads: leads,
        lastDocument: lastDocument,
      );
    } on FirebaseException catch (error, stackTrace) {
      log(error.toString());
      throw LeadRepositoryException(
        'Unable to load leads right now. Please try again.',
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      log(error.toString());
      throw LeadRepositoryException(
        'An unexpected error occurred while loading leads.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<List<Lead>> searchLeads(String query) {
    final trimmedQuery = query.trim();
    final normalizedQuery = trimmedQuery.toLowerCase();
    if (normalizedQuery.isEmpty) {
      return Stream.value(const []);
    }

    final baseStream = _mapSnapshots(
      _collection.orderBy('createdAt', descending: true).snapshots(),
      failureMessage: 'Unable to search leads right now. Please try again.',
    );

    return baseStream.map(
      (leads) => leads
          .where(
            (lead) =>
                lead.leadName.toLowerCase().contains(normalizedQuery) ||
                lead.projectName.toLowerCase().contains(normalizedQuery) ||
                lead.mobile.contains(trimmedQuery),
          )
          .toList(),
    );
  }
}
//   @override
//   Future<void> seedTestLeads({int count = 100}) async {
//     if (count <= 0) return;

//     final random = Random();
//     final pendingCommits = <Future<void>>[];
//     var batch = _firestore.batch();
//     var writesInBatch = 0;
//     final now = DateTime.now();

//     String randomMobile() {
//       final buffer = StringBuffer();
//       buffer.write(random.nextInt(9) + 1);
//       for (var i = 0; i < 9; i++) {
//         buffer.write(random.nextInt(10));
//       }
//       return buffer.toString();
//     }

//     String pick(List<String> options) =>
//         options[random.nextInt(options.length)];

//     for (var index = 0; index < count; index++) {
//       final docRef = _collection.doc();
//       final createdAtOffset =
//           Duration(minutes: random.nextInt(60 * 24 * 30)); // up to 30 days ago
//       final lead = Lead(
//         id: docRef.id,
//         leadName: '${pick(_seedFirstNames)} ${pick(_seedLastNames)}',
//         mobile: randomMobile(),
//         projectName:
//             '${pick(_seedProjectPrefixes)} ${pick(_seedProjectSuffixes)}',
//         status: LeadStatus.values[random.nextInt(LeadStatus.values.length)],
//         createdAt: now.subtract(createdAtOffset),
//       );

//       batch.set(docRef, lead.toFirestorePayload());
//       writesInBatch++;

//       if (writesInBatch == 500) {
//         pendingCommits.add(batch.commit());
//         batch = _firestore.batch();
//         writesInBatch = 0;
//       }
//     }

//     if (writesInBatch > 0) {
//       pendingCommits.add(batch.commit());
//     }

//     await Future.wait(pendingCommits);
//   }
// }

// const _seedFirstNames = <String>[
//   'Aarav',
//   'Vihaan',
//   'Sai',
//   'Ishita',
//   'Meera',
//   'Kabir',
//   'Anaya',
//   'Rohan',
//   'Diya',
//   'Advait',
// ];

// const _seedLastNames = <String>[
//   'Sharma',
//   'Patel',
//   'Iyer',
//   'Gupta',
//   'Reddy',
//   'Chopra',
//   'Malhotra',
//   'Nair',
//   'Bose',
//   'Desai',
// ];

// const _seedProjectPrefixes = <String>[
//   'Skyline',
//   'Greenview',
//   'Sunset',
//   'Riverfront',
//   'Harmony',
//   'Bluebell',
//   'Palm Grove',
//   'Golden Heights',
//   'Willow',
//   'Silver Oak',
// ];

// const _seedProjectSuffixes = <String>[
//   'Residency',
//   'Enclave',
//   'Gardens',
//   'Heights',
//   'Retreat',
//   'Square',
//   'Vista',
//   'Meadows',
//   'Court',
//   'Homes',
// ];
