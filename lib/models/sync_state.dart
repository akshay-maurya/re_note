class SyncState {
  final int pendingCount;
  final bool isSyncing;
  final List<String> logs;
  final String? syncErrorMessage;

  SyncState({
    required this.pendingCount,
    required this.isSyncing,
    required this.logs,
    this.syncErrorMessage,
  });

  SyncState copyWith({
    int? pendingCount,
    bool? isSyncing,
    List<String>? logs,
    String? syncErrorMessage,
  }) {
    return SyncState(
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      logs: logs ?? this.logs,
      syncErrorMessage: syncErrorMessage,
    );
  }
}
