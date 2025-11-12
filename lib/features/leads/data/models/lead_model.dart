import 'package:cloud_firestore/cloud_firestore.dart';

enum LeadStatus {
  newLead('New'),
  followUp('Follow-up'),
  closed('Closed');

  const LeadStatus(this.label);

  final String label;

  static LeadStatus fromRaw(String raw) {
    return LeadStatus.values.firstWhere(
      (status) => status.label.toLowerCase() == raw.toLowerCase(),
      orElse: () => LeadStatus.newLead,
    );
  }
}

class Lead {
  const Lead({
    required this.id,
    required this.leadName,
    required this.mobile,
    required this.projectName,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String leadName;
  final String mobile;
  final String projectName;
  final LeadStatus status;
  final DateTime? createdAt;

  Lead copyWith({
    String? id,
    String? leadName,
    String? mobile,
    String? projectName,
    LeadStatus? status,
    DateTime? createdAt,
  }) {
    return Lead(
      id: id ?? this.id,
      leadName: leadName ?? this.leadName,
      mobile: mobile ?? this.mobile,
      projectName: projectName ?? this.projectName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestorePayload() {
    return {
      'leadName': leadName,
      'mobile': mobile,
      'projectName': projectName,
      'status': status.label,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  static Lead fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'];
    DateTime? createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      createdAt = timestamp;
    }

    return Lead(
      id: doc.id,
      leadName: (data['leadName'] as String?) ?? '',
      mobile: (data['mobile'] as String?) ?? '',
      projectName: (data['projectName'] as String?) ?? '',
      status: LeadStatus.fromRaw(
          (data['status'] as String?) ?? LeadStatus.newLead.label),
      createdAt: createdAt,
    );
  }
}

// // keywords builder //
// List<String> keywordsBuilder(String convertName) {
//   final filteredKeyword = convertName.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
//   List<String> words = filteredKeyword.split(" ");
//   List<String> substrings = [];
//   for (String word in words) {
//     String currentSubstring = "";
//     for (int i = 0; i < word.length; i++) {
//       currentSubstring += word[i];
//       substrings.add(currentSubstring.toLowerCase());
//     }
//     substrings.add(word.toLowerCase());
//   }
//   if (!words.contains("")) {
//     substrings.add(filteredKeyword.replaceAll(' ', '').toLowerCase());
//   }
//   substrings = substrings.toSet().toList();
//   substrings.remove('');
//   substrings.sort();

//   return substrings;
// }
