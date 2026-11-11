import 'dart:developer' as developer;

import '../models/sync_action.dart';
import 'mock_server_service.dart';
import 'sync_queue_service.dart';

class SyncManager {
  final SyncQueueService queueService;
  final MockServerService serverService;

  bool isOffline = false;
  bool isSyncing = false;

  SyncManager({required this.queueService, required this.serverService});

  static const List<int> retryDelays = [2, 4, 8];

  void setOffline(bool offline) {
    isOffline = offline;

    developer.log(offline ? 'Offline mode enabled' : 'Online mode enabled');
  }

  Future<void> syncPendingActions() async {
    if (isOffline || isSyncing) return;

    isSyncing = true;

    try {
      final queue = await queueService.getQueue();

      queue.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final action in queue) {
        if (isOffline) break;

        if (action.syncStatus == 'Retrying') {
          action.syncStatus = 'Pending';
          await queueService.updateAction(action);
        }

        if (action.syncStatus == 'Synced' ||
            action.syncStatus == 'Needs attention') {
          continue;
        }

        await processAction(action);
      }
    } finally {
      isSyncing = false;
    }
  }

  Future<void> processAction(SyncAction action) async {
    while (!isOffline) {
      action.syncStatus = 'Retrying';
      await queueService.updateAction(action);

      final success = await serverService.sendUpdate(
        requestId: action.requestId,
        deliveryId: action.deliveryId,
        action: action.action,
      );

      if (success) {
        action.syncStatus = 'Synced';
        await queueService.updateAction(action);

        developer.log('Successfully synced ${action.deliveryId}');

        return;
      }

      action.attempts++;

      if (action.attempts > retryDelays.length) {
        action.syncStatus = 'Needs attention';
        await queueService.updateAction(action);

        developer.log('Manual attention required for ${action.deliveryId}');

        return;
      }

      action.syncStatus = 'Retrying';
      await queueService.updateAction(action);

      final delaySeconds = retryDelays[action.attempts - 1];

      developer.log('Retrying ${action.deliveryId} in $delaySeconds seconds');

      await Future.delayed(Duration(seconds: delaySeconds));
    }

    action.syncStatus = 'Pending';
    await queueService.updateAction(action);
  }

  Future<void> retryNeedsAttention(String requestId) async {
    if (isOffline || isSyncing) return;

    final queue = await queueService.getQueue();

    final index = queue.indexWhere((action) => action.requestId == requestId);

    if (index == -1) return;

    final action = queue[index];

    if (action.syncStatus != 'Needs attention') return;

    action.attempts = 0;
    action.syncStatus = 'Pending';

    await queueService.updateAction(action);

    await syncPendingActions();
  }
}
