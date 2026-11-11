import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery_model.dart';

class StorageService {
  static const String deliveryKey = 'saved_deliveries';

  // Load deliveries from local storage or JSON asset
  Future<List<Delivery>> loadDeliveries() async {
    final preferences = await SharedPreferences.getInstance();

    final savedData = preferences.getString(deliveryKey);

    // If saved data exists, load it
    if (savedData != null) {
      final List<dynamic> jsonData = jsonDecode(savedData);

      return jsonData.map((item) {
        return Delivery.fromJson(item);
      }).toList();
    }

    // Otherwise, load the original JSON file
    final jsonString = await rootBundle.loadString(
      'assets/data/deliveries.json',
    );

    final List<dynamic> jsonData = jsonDecode(jsonString);

    final deliveries = jsonData.map((item) {
      return Delivery.fromJson(item);
    }).toList();

    // Save initial deliveries locally
    await saveDeliveries(deliveries);

    return deliveries;
  }

  // Save updated deliveries on the device
  Future<void> saveDeliveries(List<Delivery> deliveries) async {
    final preferences = await SharedPreferences.getInstance();

    final jsonData = deliveries.map((delivery) {
      return delivery.toJson();
    }).toList();

    final encodedData = jsonEncode(jsonData);

    await preferences.setString(deliveryKey, encodedData);
  }
}
