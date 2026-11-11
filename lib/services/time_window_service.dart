class TimeWindowService {
  static String getDeliveryAlert({
    required String startTime,
    required String endTime,
    required DateTime currentTime,
  }) {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    final start = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final end = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    // Delivery window has passed
    if (currentTime.isAfter(end)) {
      return 'Late';
    }

    // Delivery window has not started
    if (currentTime.isBefore(start)) {
      return 'Upcoming';
    }

    // Calculate remaining time
    final remainingMinutes = end.difference(currentTime).inMinutes;

    if (remainingMinutes < 15) {
      return 'At Risk';
    }

    return 'Normal';
  }
}
