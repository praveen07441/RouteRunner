class SyncAction {
  final String requestId;
  final String deliveryId;
  final String action;
  final DateTime createdAt;

  String syncStatus;
  int attempts;

  SyncAction({
    required this.requestId,
    required this.deliveryId,
    required this.action,
    required this.createdAt,
    this.syncStatus = 'Pending',
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'deliveryId': deliveryId,
      'action': action,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus,
      'attempts': attempts,
    };
  }

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      requestId: json['requestId'] as String,
      deliveryId: json['deliveryId'] as String,
      action: json['action'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncStatus: json['syncStatus'] as String? ?? 'Pending',
      attempts: json['attempts'] as int? ?? 0,
    );
  }
}
