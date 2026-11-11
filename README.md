# NEXU RouteRunner
### Offline-First Delivery Management Application

NEXU RouteRunner is a Flutter-based mobile application designed to help delivery agents manage their daily delivery operations efficiently.

The application provides delivery tracking, package confirmation, delivery status management, and an offline-first synchronization mechanism. It allows delivery agents to continue recording delivery activities even when internet connectivity is unavailable.

---

## 1. Project Overview

Delivery agents often work in areas where internet connectivity is unstable. This can interrupt delivery updates and cause information to be lost or delayed.

NEXU RouteRunner addresses this problem by providing an offline-first approach.

The application stores delivery information locally and maintains a synchronization queue. When connectivity is restored, pending delivery actions can be synchronized with the simulated server.

### Main Objectives

- Manage daily delivery stops.
- Track delivery status.
- Validate recipient and package information.
- Support offline delivery operations.
- Synchronize pending actions when connectivity returns.
- Prevent duplicate requests.
- Provide a simple interface for delivery agents.

---

## 2. Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Mobile application development |
| Dart | Application programming language |
| SharedPreferences | Local data storage |
| JSON | Delivery data management |
| Android | Mobile application platform |
| Mock Server | Simulated server communication |
| VS Code | Development environment |

---

## 3. Application Features

### 3.1 Agent Login

The application provides a simple login screen.

The agent enters:
- Agent name
- Four-digit PIN

After entering valid inputs, the application navigates to the delivery dashboard.

### 3.2 Delivery Management

The application contains 12 sample delivery stops loaded from a local JSON file.

Each delivery includes:

- Delivery ID
- Customer name
- Delivery address
- Package count
- Delivery time window
- Priority level
- Delivery status

The application supports the following delivery statuses:

- Pending
- Arrived
- Delivered
- Failed
- Retry
- Returned to Hub

### 3.3 Delivery Priority

Deliveries are classified into two priority levels:

- **Urgent:** Higher-priority deliveries.
- **Normal:** Regular deliveries.

The dashboard organizes deliveries based on priority and delivery time.

### 3.4 Search and Filtering

The dashboard provides search and filtering options to help agents find deliveries.

Agents can search for delivery information and filter stops based on their status or priority.

### 3.5 Delivery Completion

Before completing a delivery, the application validates the required information.

The agent must provide:

- Recipient name (minimum two characters).
- Confirmed package count matching the expected package count.

The delivery cannot be completed if the required information is invalid.

### 3.6 Failed Delivery Handling

When a delivery cannot be completed, the agent can select a failure reason.

Available reasons:

- Customer absent
- Wrong address
- Refused
- Access problem
- Other

For the Other option, an additional explanation is required.

A failed delivery is moved to the retry stage.

The application supports a maximum of two failures. After the second failure, the delivery is marked as Returned to Hub.

### 3.7 Time Window Management

Each delivery has a specified time window.

The application uses time-window logic to identify delivery conditions such as:

- Upcoming
- At Risk
- Late
- Normal

Urgent deliveries also have an additional restriction: they cannot be marked as failed for Customer absent before their delivery window starts.

---

## 4. Offline-First Synchronization

One of the main features of NEXU RouteRunner is its offline-first synchronization approach.

The application uses a local synchronization queue to maintain delivery actions when network connectivity is unavailable.

### How It Works

1. The agent performs a delivery action.
2. The application saves the action locally.
3. The action is added to the synchronization queue.
4. If the simulated server is unavailable, the action remains pending.
5. When the connection is restored, the application attempts synchronization.
6. Successfully processed actions are marked as Synced.

### Synchronization Status

| Status | Description |
|---|---|
| Synced | Action successfully processed |
| Pending | Waiting for synchronization |
| Retrying | Synchronization is being attempted again |
| Needs Attention | Automatic attempts have failed and manual action is required |

### Retry Mechanism

The synchronization manager uses increasing retry delays:

- First retry: 2 seconds
- Second retry: 4 seconds
- Third retry: 8 seconds

After the automatic retry attempts are exhausted, the action is marked as Needs Attention.

Manual retry is also supported.

### Duplicate Request Handling

Every synchronization action is assigned a unique request ID.

The mock server maintains a record of processed request IDs.

If the same request ID is received again, the server ignores the duplicate instead of processing the same action twice.

### Mock Server

The project uses a simulated server to demonstrate synchronization behaviour.

It supports:
- Simulated server communication.
- Offline mode.
- Failed synchronization attempts.
- Duplicate request detection.
- Automatic retry handling.

**Note:** This is a local mock-server implementation, not a connection to a real remote backend.

---

## 5. Project Structure

```text
nexu_routerunner/
│
├── assets/
│   └── data/
│       └── deliveries.json
│
├── lib/
│   ├── main.dart
│   │
│   ├── models/
│   │   ├── delivery_model.dart
│   │   └── sync_action.dart
│   │
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   └── delivery_details_screen.dart
│   │
│   └── services/
│       ├── storage_service.dart
│       ├── time_window_service.dart
│       ├── sync_queue_service.dart
│       ├── mock_server_service.dart
│       └── sync_manager.dart
│
├── test/
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### Main Components

| Component | Responsibility |
|---|---|
| delivery_model.dart | Defines delivery information and status |
| sync_action.dart | Defines synchronization actions |
| login_screen.dart | Handles agent login |
| dashboard_screen.dart | Displays delivery list and dashboard controls |
| delivery_details_screen.dart | Handles delivery operations and validation |
| storage_service.dart | Manages local delivery data |
| time_window_service.dart | Evaluates delivery time windows |
| sync_queue_service.dart | Stores pending synchronization actions |
| mock_server_service.dart | Simulates server processing |
| sync_manager.dart | Manages synchronization and retries |

---

## 6. Installation and Setup

### Prerequisites

Install the following:

- Flutter SDK
- Dart SDK
- Android Studio or Android SDK
- Visual Studio Code

### Clone the Repository

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
```

Navigate to the project:

```bash
cd nexu_routerunner
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

### Build APK

To generate a debug APK:

```bash
flutter build apk --debug
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

---

## 7. Testing

The application requires testing of its delivery workflow and synchronization behaviour.

The planned automated test cases include:

| Test Case | Expected Result |
|---|---|
| Recipient validation | Delivery should not complete without a valid recipient name |
| Package validation | Incorrect package count should be rejected |
| Retry mechanism | Failed requests should retry after 2, 4 and 8 seconds |
| Duplicate request handling | The same request ID should not be processed twice |

Automated tests will be added and executed using:

```bash
flutter test
```

The final testing results will be documented after execution.

---

## 8. Current Implementation Status

The following table distinguishes implemented functionality from remaining work.

| Feature | Status |
|---|---|
| Agent login screen | Implemented |
| Local JSON delivery data | Implemented |
| 12 sample delivery stops | Implemented |
| Delivery dashboard | Implemented |
| Search and filtering | Implemented |
| Delivery status management | Implemented |
| Recipient validation | Implemented |
| Package count validation | Implemented |
| Failed delivery handling | Implemented |
| Retry and Returned to Hub flow | Implemented |
| Time-window evaluation | Implemented |
| Local synchronization queue | Implemented |
| Offline mode simulation | Implemented |
| Automatic retry mechanism | Implemented |
| Duplicate request protection | Implemented in mock server |
| Only one Arrived stop at a time | Requires final verification |
| 60-second Undo functionality | Pending |
| About screen | Pending |
| Automated test suite | Pending |
| Final demonstration video | Pending |

---

## 9. Future Improvements

Potential improvements include:

- Integration with a real backend server.
- GPS-based delivery tracking.
- Map-based route navigation.
- Real-time delivery updates.
- Improved reporting and analytics.
- Enhanced authentication.
- Additional automated testing.

---

## 10. Conclusion

NEXU RouteRunner demonstrates how an offline-first delivery management application can be developed using Flutter.

The application focuses on delivery workflow management, local data storage, delivery validation, and reliable synchronization through a simulated server.

The project demonstrates the importance of maintaining delivery information even when network connectivity is unavailable.

---

**Project:** NEXU RouteRunner  
**Platform:** Android  
**Framework:** Flutter  
**Language:** Dart
