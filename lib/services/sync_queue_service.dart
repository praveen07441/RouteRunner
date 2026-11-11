import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sync_action.dart';

class SyncQueueService {
  static const String queueKey = 'sync_queue';

  String generateRequestId() {
    final random = Random.secure();
    final randomNumber = random.nextInt(1000000);

    return '${DateTime.now().microsecondsSinceEpoch}-$randomNumber';
  }

  // Load saved actions
  Future<List<SyncAction>> getQueue() async {
    final preferences = await SharedPreferences.getInstance();

    final savedData = preferences.getString(queueKey);

    if (savedData == null) {
      return [];
    }

    final List<dynamic> jsonData = jsonDecode(savedData);

    return jsonData.map((item) {
      return SyncAction.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  // Save actions
  Future<void> saveQueue(List<SyncAction> actions) async {
    final preferences = await SharedPreferences.getInstance();

    final jsonData = actions.map((action) {
      return action.toJson();
    }).toList();

    await preferences.setString(queueKey, jsonEncode(jsonData));
  }

  // Add new action
  Future<SyncAction> addAction({
    required String deliveryId,
    required String action,
  }) async {
    final queue = await getQueue();

    final newAction = SyncAction(
      requestId: generateRequestId(),
      deliveryId: deliveryId,
      action: action,
      createdAt: DateTime.now(),
    );

    queue.add(newAction);

    await saveQueue(queue);

    return newAction;
  }

  // Update action
  Future<void> updateAction(SyncAction updatedAction) async {
    final queue = await getQueue();

    final index = queue.indexWhere(
      (item) => item.requestId == updatedAction.requestId,
    );

    if (index != -1) {
      queue[index] = updatedAction;
      await saveQueue(queue);
    }
  }

  // Remove action
  Future<void> removeAction(String requestId) async {
    final queue = await getQueue();

    queue.removeWhere((item) => item.requestId == requestId);

    await saveQueue(queue);
  }
}
