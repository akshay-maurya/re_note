import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  bool isSynced;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  bool isDeleted;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.isSynced = false,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    bool? isSynced,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isSynced': isSynced,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      isSynced: map['isSynced'] as bool? ?? false,
      updatedAt: DateTime.parse(map['updatedAt'] as String).toLocal(),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
