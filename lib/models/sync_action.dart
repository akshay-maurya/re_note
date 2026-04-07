import 'package:hive/hive.dart';

part 'sync_action.g.dart';

@HiveType(typeId: 1)
enum ActionType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  like,
  @HiveField(3)
  delete,
}

@HiveType(typeId: 2)
enum SyncStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  syncing,
  @HiveField(2)
  failed,
}

@HiveType(typeId: 3)
class SyncAction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ActionType actionType;

  @HiveField(2)
  final Map<String, dynamic> payload;

  @HiveField(3)
  SyncStatus status;

  @HiveField(4)
  final DateTime createdAt;

  SyncAction({
    required this.id,
    required this.actionType,
    required this.payload,
    this.status = SyncStatus.pending,
    required this.createdAt,
  });
}
