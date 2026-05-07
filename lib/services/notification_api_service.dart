import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../config/api_config.dart';
import '../models/notification.dart';

class NotificationApiService {
  final String baseUrl = ApiConfig.baseUrl;

  static const String _authSecret = 'dev-secret-change-in-production';

  String _generateSignature(String userId) {
    final key = utf8.encode(_authSecret);
    final bytes = utf8.encode(userId);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  Map<String, String> _headers(String userId) => {
    'Content-Type': 'application/json',
    'X-User-Id': userId,
    'X-User-Signature': _generateSignature(userId),
  };

  Future<PaginatedNotifications> getNotifications({
    required String userId,
    NotificationType? type,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      if (type != null) 'type': _typeToString(type),
      if (isRead != null) 'isRead': isRead.toString(),
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers(userId));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PaginatedNotifications.fromJson(data);
    } else {
      throw Exception('获取通知失败 (${response.statusCode})');
    }
  }

  Future<AppNotification> getNotificationById(String id, String userId) async {
    final uri = Uri.parse('$baseUrl/notifications/$id');
    final response = await http.get(uri, headers: _headers(userId));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AppNotification.fromJson(data);
    } else {
      throw Exception('获取通知详情失败');
    }
  }

  Future<bool> markAsRead(String id, String userId) async {
    final uri = Uri.parse('$baseUrl/notifications/$id');
    final response = await http.post(uri, headers: _headers(userId));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('标记已读失败');
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    final uri = Uri.parse('$baseUrl/notifications/read-all');
    final response = await http.post(uri, headers: _headers(userId));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('全部已读失败');
    }
  }

  Future<bool> deleteNotification(String id, String userId) async {
    final uri = Uri.parse('$baseUrl/notifications/$id');
    final response = await http.delete(uri, headers: _headers(userId));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('删除通知失败');
    }
  }

  String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return 'system';
      case NotificationType.order:
        return 'order';
      case NotificationType.message:
        return 'message';
      case NotificationType.campaign:
        return 'campaign';
    }
  }
}
