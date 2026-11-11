import 'dart:developer' as developer;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MockServerService {
  static const String processedRequestsKey = 'processed_server_requests';

  // Simulate server failures during testing.
  bool simulateFailures = false;

  // Load previously processed request IDs.
  Future<Set<String>> getProcessedRequests() async {
    final preferences = await SharedPreferences.getInstance();

    final savedData = preferences.getString(processedRequestsKey);

    if (savedData == null) {
      return {};
    }

    final List<dynamic> decodedData = jsonDecode(savedData);

    return decodedData.cast<String>().toSet();
  }

  // Save processed request IDs.
  Future<void> saveProcessedRequests(Set<String> requests) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      processedRequestsKey,
      jsonEncode(requests.toList()),
    );
  }

  // Receive an update from the application.
  Future<bool> sendUpdate({
    required String requestId,
    required String deliveryId,
    required String action,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final processedRequests = await getProcessedRequests();

    // Prevent duplicate processing.
    if (processedRequests.contains(requestId)) {
      developer.log('Duplicate request ignored: $requestId');
      return true;
    }

    // Simulate server failure.
    if (simulateFailures) {
      developer.log('Simulated server failure: $requestId');
      return false;
    }

    // Store the request ID after successful processing.
    processedRequests.add(requestId);

    await saveProcessedRequests(processedRequests);

    developer.log('Server received update');
    developer.log('Request ID: $requestId');
    developer.log('Delivery ID: $deliveryId');
    developer.log('Action: $action');

    return true;
  }
}
