import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../config/api_config.dart';
import '../models/weight_record.dart';

class WeightApiService {
  final String baseUrl = ApiConfig.baseUrl;

  // 开发环境密钥，生产环境需从安全渠道获取
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

  Future<List<WeightRecord>> getWeightRecords({
    required String userId,
    String? startDate,
    String? endDate,
    String? period,
    int page = 1,
    int pageSize = 100,
  }) async {
    final queryParams = {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (period != null) 'period': period,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse('$baseUrl/weight-records').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers(userId));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((item) => WeightRecord.fromJson(item)).toList();
    } else {
      throw Exception('获取体重记录失败 (${response.statusCode})');
    }
  }

  Future<WeightRecord> createWeightRecord({
    required String userId,
    required String date,
    required WeightPeriod period,
    required double weight,
    String? note,
  }) async {
    final uri = Uri.parse('$baseUrl/weight-records');
    final response = await http.post(
      uri,
      headers: _headers(userId),
      body: json.encode({
        'date': date,
        'period': period == WeightPeriod.evening ? 'evening' : 'morning',
        'weight': weight,
        if (note != null) 'note': note,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return WeightRecord.fromJson(data);
    } else {
      throw Exception(data['error'] ?? '创建失败 (${response.statusCode})');
    }
  }

  Future<WeightStats> getWeightStats({
    required String userId,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };

    final uri = Uri.parse('$baseUrl/weight-records/stats').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers(userId));

    if (response.statusCode == 200) {
      return WeightStats.fromJson(json.decode(response.body));
    } else {
      throw Exception('获取统计数据失败');
    }
  }

  Future<bool> deleteWeightRecord(String id, String userId) async {
    final uri = Uri.parse('$baseUrl/weight-records/$id');
    final response = await http.delete(uri, headers: _headers(userId));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    } else {
      throw Exception('删除失败');
    }
  }
}