import 'package:flutter/material.dart';

import '../models/delivery_model.dart';
import '../models/sync_action.dart';

import '../services/storage_service.dart';
import '../services/time_window_service.dart';
import '../services/sync_queue_service.dart';
import '../services/mock_server_service.dart';
import '../services/sync_manager.dart';

import 'delivery_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String agentName;

  const DashboardScreen({super.key, required this.agentName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Delivery> deliveries = [];
  List<SyncAction> syncActions = [];

  bool isLoading = true;
  bool isOffline = false;

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All';

  final StorageService storageService = StorageService();
  final SyncQueueService queueService = SyncQueueService();
  final MockServerService serverService = MockServerService();

  late final SyncManager syncManager;

  @override
  void initState() {
    super.initState();

    syncManager = SyncManager(
      queueService: queueService,
      serverService: serverService,
    );

    loadDeliveries();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Retry deliveries are always placed at the end.
  void sortRoute() {
    deliveries.sort((a, b) {
      if (a.status == 'Retry' && b.status != 'Retry') {
        return 1;
      }

      if (a.status != 'Retry' && b.status == 'Retry') {
        return -1;
      }

      if (a.priority == 'Urgent' && b.priority != 'Urgent') {
        return -1;
      }

      if (a.priority != 'Urgent' && b.priority == 'Urgent') {
        return 1;
      }

      return a.startTime.compareTo(b.startTime);
    });
  }

  Future<void> loadDeliveries() async {
    final loadedDeliveries = await storageService.loadDeliveries();

    final loadedActions = await queueService.getQueue();

    deliveries = loadedDeliveries;
    sortRoute();

    if (!mounted) return;

    setState(() {
      syncActions = loadedActions;
      isLoading = false;
    });

    await syncManager.syncPendingActions();
    await refreshSyncActions();
  }

  Future<void> refreshSyncActions() async {
    final actions = await queueService.getQueue();

    if (!mounted) return;

    setState(() {
      syncActions = actions;
    });
  }

  Future<void> handleDeliveryUpdated(Delivery delivery, String action) async {
    sortRoute();

    await storageService.saveDeliveries(deliveries);

    await queueService.addAction(deliveryId: delivery.id, action: action);

    await refreshSyncActions();

    await syncManager.syncPendingActions();

    await refreshSyncActions();
  }

  Future<void> toggleOfflineMode(bool value) async {
    setState(() {
      isOffline = value;
    });

    syncManager.setOffline(value);

    if (!value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Online mode enabled. Sync started.')),
      );

      await syncManager.syncPendingActions();
      await refreshSyncActions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline mode enabled. Updates saved locally.'),
        ),
      );
    }
  }

  Future<void> retrySync(String requestId) async {
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please switch to Online mode first.')),
      );

      return;
    }

    await syncManager.retryNeedsAttention(requestId);

    await refreshSyncActions();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual synchronization attempt completed.'),
      ),
    );
  }

  Future<void> openDeliveryDetails(Delivery delivery) async {
    final anotherStopActive = deliveries.any(
      (item) => item.status == 'Arrived' && item.id != delivery.id,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailsScreen(
          delivery: delivery,
          canMarkArrived: !anotherStopActive,
          onUpdated: handleDeliveryUpdated,
        ),
      ),
    );

    if (mounted) {
      sortRoute();

      setState(() {});

      await storageService.saveDeliveries(deliveries);
      await refreshSyncActions();
    }
  }

  int get deliveredCount =>
      deliveries.where((d) => d.status == 'Delivered').length;

  int get pendingCount => deliveries.where((d) => d.status == 'Pending').length;

  int get failedCount => deliveries.where((d) => d.status == 'Failed').length;

  int get retryCount => deliveries.where((d) => d.status == 'Retry').length;

  int get returnedCount =>
      deliveries.where((d) => d.status == 'Returned to hub').length;

  SyncAction? getLatestSyncAction(String deliveryId) {
    final matchingActions = syncActions
        .where((action) => action.deliveryId == deliveryId)
        .toList();

    if (matchingActions.isEmpty) {
      return null;
    }

    matchingActions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return matchingActions.first;
  }

  String getSyncStatus(String deliveryId) {
    return getLatestSyncAction(deliveryId)?.syncStatus ?? 'Not synced';
  }

  Color getSyncColor(String status) {
    switch (status) {
      case 'Synced':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Retrying':
        return Colors.blue;
      case 'Needs attention':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color getAlertColor(String alert) {
    switch (alert) {
      case 'Late':
        return Colors.red;
      case 'At Risk':
        return Colors.orange;
      case 'Upcoming':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Widget buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  List<Delivery> get filteredDeliveries {
    List<Delivery> result = List.from(deliveries);

    final query = searchController.text.toLowerCase().trim();

    if (query.isNotEmpty) {
      result = result.where((delivery) {
        return delivery.customerName.toLowerCase().contains(query) ||
            delivery.id.toLowerCase().contains(query);
      }).toList();
    }

    if (selectedFilter == 'Urgent') {
      result = result
          .where((delivery) => delivery.priority == 'Urgent')
          .toList();
    } else if (selectedFilter != 'All') {
      result = result
          .where((delivery) => delivery.status == selectedFilter)
          .toList();
    }

    return result;
  }

  Widget buildDeliveryCard(Delivery delivery) {
    final alert = TimeWindowService.getDeliveryAlert(
      startTime: delivery.startTime,
      endTime: delivery.endTime,
      currentTime: DateTime.now(),
    );

    final latestAction = getLatestSyncAction(delivery.id);

    final syncStatus = latestAction?.syncStatus ?? 'Not synced';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: CircleAvatar(
          backgroundColor: delivery.priority == 'Urgent'
              ? Colors.red.shade100
              : Colors.blue.shade100,
          child: Icon(
            Icons.local_shipping,
            color: delivery.priority == 'Urgent' ? Colors.red : Colors.blue,
          ),
        ),

        title: Text(
          delivery.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),

            Text('ID: ${delivery.id}'),
            Text('Address: ${delivery.address}'),
            Text('Packages: ${delivery.expectedPackages}'),
            Text('Time: ${delivery.startTime} - ${delivery.endTime}'),

            const SizedBox(height: 6),

            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(delivery.status),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(delivery.priority),
                  backgroundColor: delivery.priority == 'Urgent'
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            Text(
              'Time Alert: $alert',
              style: TextStyle(
                color: getAlertColor(alert),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  size: 17,
                  color: getSyncColor(syncStatus),
                ),
                const SizedBox(width: 5),
                Text(
                  'Sync: $syncStatus',
                  style: TextStyle(
                    color: getSyncColor(syncStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            if (syncStatus == 'Needs attention' && latestAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: isOffline
                      ? null
                      : () => retrySync(latestAction.requestId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Sync'),
                ),
              ),
          ],
        ),

        trailing: const Icon(Icons.arrow_forward_ios),

        onTap: () => openDeliveryDetails(delivery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXU RouteRunner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Text(isOffline ? 'Offline' : 'Online'),
              Switch(value: isOffline, onChanged: toggleOfflineMode),
            ],
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Welcome, ${widget.agentName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Row(
                  children: [
                    buildSummaryCard('Total', deliveries.length, Colors.blue),
                    buildSummaryCard('Delivered', deliveredCount, Colors.green),
                    buildSummaryCard('Pending', pendingCount, Colors.orange),
                  ],
                ),

                Row(
                  children: [
                    buildSummaryCard('Failed', failedCount, Colors.red),
                    buildSummaryCard('Retry', retryCount, Colors.orange),
                    buildSummaryCard('Returned', returnedCount, Colors.purple),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search customer or delivery ID',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Filter:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedFilter,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items:
                              [
                                'All',
                                'Pending',
                                'Arrived',
                                'Delivered',
                                'Retry',
                                'Failed',
                                'Returned to hub',
                                'Urgent',
                              ].map((filter) {
                                return DropdownMenuItem(
                                  value: filter,
                                  child: Text(filter),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              selectedFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Delivery Route',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: filteredDeliveries.isEmpty
                      ? const Center(child: Text('No deliveries found'))
                      : ListView.builder(
                          itemCount: filteredDeliveries.length,
                          itemBuilder: (context, index) {
                            return buildDeliveryCard(filteredDeliveries[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
