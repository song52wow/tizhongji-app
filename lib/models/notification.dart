enum NotificationType {
  system,
  order,
  message,
  campaign,
}

enum Priority {
  low,
  normal,
  high,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String content;
  final bool isRead;
  final Priority priority;
  final String createdAt;
  final String? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.content,
    required this.isRead,
    required this.priority,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: _parseType(json['type']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      priority: _parsePriority(json['priority']),
      createdAt: json['createdAt'] ?? '',
      readAt: json['readAt'],
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'order':
        return NotificationType.order;
      case 'message':
        return NotificationType.message;
      case 'campaign':
        return NotificationType.campaign;
      default:
        return NotificationType.system;
    }
  }

  static Priority _parsePriority(String? priority) {
    switch (priority) {
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.normal;
    }
  }

  AppNotification copyWith({bool? isRead, String? readAt}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      content: content,
      isRead: isRead ?? this.isRead,
      priority: priority,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.system:
        return '系统通知';
      case NotificationType.order:
        return '订单通知';
      case NotificationType.message:
        return '消息';
      case NotificationType.campaign:
        return '活动';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case Priority.high:
        return '高';
      case Priority.low:
        return '低';
      default:
        return '普通';
    }
  }
}

class PaginatedNotifications {
  final List<AppNotification> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedNotifications({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) {
    return PaginatedNotifications(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => AppNotification.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }
}
