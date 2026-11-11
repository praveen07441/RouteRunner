import 'package:flutter/material.dart';

import '../models/delivery_model.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final Delivery delivery;

  final Future<void> Function(Delivery delivery, String action) onUpdated;

  final bool canMarkArrived;

  const DeliveryDetailsScreen({
    super.key,
    required this.delivery,
    required this.onUpdated,
    required this.canMarkArrived,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final TextEditingController recipientController = TextEditingController();

  final TextEditingController packageController = TextEditingController();

  final TextEditingController noteController = TextEditingController();

  String? selectedFailureReason;

  final List<String> failureReasons = [
    'Customer absent',
    'Wrong address',
    'Refused',
    'Access problem',
    'Other',
  ];

  bool isSaving = false;

  @override
  void dispose() {
    recipientController.dispose();
    packageController.dispose();
    noteController.dispose();
    super.dispose();
  }

  // Converts the delivery start time into today's DateTime.
  DateTime getDeliveryStartTime() {
    final parts = widget.delivery.startTime.split(':');

    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  // Checks the urgent delivery restriction.
  bool isUrgentCustomerAbsentRestricted() {
    if (widget.delivery.priority != 'Urgent') {
      return false;
    }

    if (selectedFailureReason != 'Customer absent') {
      return false;
    }

    final currentTime = DateTime.now();
    final startTime = getDeliveryStartTime();

    return currentTime.isBefore(startTime);
  }

  Future<void> updateStatus(String status) async {
    if (isSaving) return;

    final previousStatus = widget.delivery.status;
    final previousFailureCount = widget.delivery.failureCount;

    setState(() {
      isSaving = true;
    });

    widget.delivery.status = status;

    try {
      await widget.onUpdated(widget.delivery, status);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delivery updated: $status')));

      Navigator.pop(context);
    } catch (error) {
      widget.delivery.status = previousStatus;
      widget.delivery.failureCount = previousFailureCount;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save delivery update')),
      );

      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> markDelivered() async {
    final recipient = recipientController.text.trim();

    final packages = int.tryParse(packageController.text.trim());

    if (recipient.length < 2) {
      showMessage('Enter a valid recipient name');
      return;
    }

    if (packages == null || packages != widget.delivery.expectedPackages) {
      showMessage(
        'Package count must equal ${widget.delivery.expectedPackages}',
      );
      return;
    }

    await updateStatus('Delivered');
  }

  Future<void> markFailed() async {
    if (selectedFailureReason == null) {
      showMessage('Please select a failure reason');
      return;
    }

    if (isUrgentCustomerAbsentRestricted()) {
      showMessage(
        'Urgent delivery cannot be marked Customer absent before its delivery window starts.',
      );
      return;
    }

    if (selectedFailureReason == 'Other' &&
        noteController.text.trim().length < 10) {
      showMessage('Other reason must contain at least 10 characters');
      return;
    }

    final nextFailureCount = widget.delivery.failureCount + 1;

    if (nextFailureCount >= 2) {
      widget.delivery.failureCount = nextFailureCount;
      await updateStatus('Returned to hub');
    } else {
      widget.delivery.failureCount = nextFailureCount;
      await updateStatus('Retry');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;

    final canStartDelivery =
        delivery.status == 'Pending' || delivery.status == 'Retry';

    final isLocked =
        delivery.status == 'Delivered' || delivery.status == 'Returned to hub';

    final urgentRestriction = isUrgentCustomerAbsentRestricted();

    return Scaffold(
      appBar: AppBar(
        title: Text(delivery.customerName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              delivery.customerName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text('Delivery ID: ${delivery.id}'),
            Text('Address: ${delivery.address}'),
            Text('Packages: ${delivery.expectedPackages}'),
            Text('Time: ${delivery.startTime} - ${delivery.endTime}'),
            Text('Priority: ${delivery.priority}'),
            Text('Failure attempts: ${delivery.failureCount}'),

            const SizedBox(height: 15),

            Text(
              'Current Status: ${delivery.status}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            if (canStartDelivery) ...[
              if (widget.canMarkArrived)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () => updateStatus('Arrived'),
                    child: Text(
                      delivery.status == 'Retry'
                          ? 'Retry Delivery - Mark Arrived'
                          : 'Mark as Arrived',
                    ),
                  ),
                )
              else
                const Text(
                  'Another delivery is currently active.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],

            if (delivery.status == 'Arrived') ...[
              const Text(
                'Delivery Confirmation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              buildTextField(
                label: 'Recipient Name',
                controller: recipientController,
              ),

              buildTextField(
                label: 'Confirmed Package Count',
                controller: packageController,
                keyboardType: TextInputType.number,
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : markDelivered,
                  child: const Text('Mark as Delivered'),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Failed Delivery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: selectedFailureReason,
                decoration: const InputDecoration(
                  labelText: 'Failure Reason',
                  border: OutlineInputBorder(),
                ),
                items: failureReasons.map((reason) {
                  return DropdownMenuItem(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFailureReason = value;
                  });
                },
              ),

              if (selectedFailureReason == 'Other')
                buildTextField(
                  label: 'Explain the reason (minimum 10 characters)',
                  controller: noteController,
                ),

              if (urgentRestriction)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Warning: Customer absent cannot be selected for this urgent delivery before its time window starts.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : markFailed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark as Failed'),
                ),
              ),
            ],

            if (delivery.status == 'Retry')
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  'This delivery can be attempted one more time.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (isLocked)
              const Text(
                'This delivery is completed and locked.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (isSaving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
