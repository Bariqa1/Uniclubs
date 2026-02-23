import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;
  final String name;
  final String description;
  final String category;
  final String leaderId;
  final int memberCount;
  final String? logo;
  final Map<String, String> socialLinks;
  final bool isActive;
  final DateTime? createdAt;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.leaderId,
    required this.memberCount,
    this.logo,
    required this.socialLinks,
    required this.isActive,
    this.createdAt,
  });

  factory Club.fromMap(Map<String, dynamic> data) {
    return Club(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unnamed Club',
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      leaderId: data['leaderId'] ?? '',
      memberCount: data['memberCount'] ?? 0,
      logo: data['logo'],
      socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
