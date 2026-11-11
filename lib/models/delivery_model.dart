class Delivery {
  final String id;
  final String customerName;
  final String address;
  final int expectedPackages;
  final String startTime;
  final String endTime;
  final String priority;

  String status;
  int failureCount;

  Delivery({
    required this.id,
    required this.customerName,
    required this.address,
    required this.expectedPackages,
    required this.startTime,
    required this.endTime,
    required this.priority,
    this.status = 'Pending',
    this.failureCount = 0,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      address: json['address'] ?? '',
      expectedPackages: json['expectedPackages'] ?? 0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      priority: json['priority'] ?? 'Normal',
      status: json['status'] ?? 'Pending',
      failureCount: json['failureCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'address': address,
      'expectedPackages': expectedPackages,
      'startTime': startTime,
      'endTime': endTime,
      'priority': priority,
      'status': status,
      'failureCount': failureCount,
    };
  }

  bool get canRetry {
    return status == 'Retry' && failureCount < 2;
  }

  bool get isLocked {
    return status == 'Delivered' || status == 'Returned to hub';
  }
}
