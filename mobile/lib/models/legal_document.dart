import 'package:flutter/material.dart';

class LegalDocument {
  final String type;
  final String title;
  final String content;
  final DateTime? updatedAt;

  LegalDocument({
    required this.type,
    required this.title,
    required this.content,
    this.updatedAt,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      type: json['type'],
      title: json['title'],
      content: json['content'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}