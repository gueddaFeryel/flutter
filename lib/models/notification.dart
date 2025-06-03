class AppNotification {
  final String id;
  final String userId;
  final String? interventionId;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.userId,
    this.interventionId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Handle Firestore timestamp format
    dynamic timestamp = json['timestamp'];
    DateTime parsedTimestamp;
    
    if (timestamp is Map && timestamp['_seconds'] != null) {
      // Firestore timestamp format
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    } else if (timestamp is String) {
      // ISO string format
      parsedTimestamp = DateTime.parse(timestamp);
    } else {
      // Fallback to current time
      parsedTimestamp = DateTime.now();
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      interventionId: json['interventionId']?.toString(),
      type: json['type']?.toString() ?? 'INFO',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      read: json['read'] == true,
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'interventionId': interventionId,
      'type': type,
      'title': title,
      'message': message,
      'read': read,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  AppNotification copyWith({
    bool? read,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      interventionId: interventionId,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      timestamp: timestamp,
    );
  }
}