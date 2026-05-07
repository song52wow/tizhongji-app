import 'dart:io';
import 'dart:async';

class ErrorHandler {
  /// 根据异常类型返回用户友好的中文错误信息
  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return '网络连接失败，请检查网络设置';
    }
    if (error is TimeoutException) {
      return '连接超时，请检查网络后重试';
    }
    if (error is HttpException) {
      return '服务器连接异常';
    }
    if (error is FormatException) {
      return '数据解析错误，请稍后重试';
    }

    final message = error.toString();

    // 网络相关关键词检测
    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Connection reset')) {
      return '网络连接失败，请检查网络设置';
    }
    if (message.contains('timeout') || message.contains('Timeout')) {
      return '连接超时，请检查网络后重试';
    }

    // 服务端返回的错误信息
    if (message.startsWith('Exception:')) {
      final trimmed = message.substring(10).trim();
      if (trimmed.contains('(') && trimmed.endsWith(')')) {
        final parenIndex = trimmed.indexOf('(');
        final code = trimmed.substring(parenIndex + 1, trimmed.length - 1);
        final codeNum = int.tryParse(code);
        if (codeNum != null) {
          if (codeNum >= 500) {
            return '服务器繁忙，请稍后重试 ($code)';
          } else if (codeNum == 404) {
            return '请求的资源不存在 (404)';
          } else if (codeNum >= 400) {
            return '请求出错，请检查输入 ($code)';
          }
        }
        return trimmed.substring(0, parenIndex).trim();
      }
      return trimmed;
    }

    return message;
  }

  /// 判断是否属于网络层面的错误（可离线处理的）
  static bool isNetworkError(dynamic error) {
    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException) {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('timeout') ||
        message.contains('connection refused') ||
        message.contains('connection reset');
  }
}
