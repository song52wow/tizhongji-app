import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/weight_api_service.dart';
import '../utils/error_handler.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final SettingsService _settingsService = SettingsService();
  bool _loading = false;
  String? _errorMsg;

  static const _bluePrimary = Color(0xFF106399);
  static const _textDark = Color(0xFF191C1D);
  static const _textMuted = Color(0xFF41474F);
  static const _bgPage = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final settings = await _settingsService.loadSettings();
    if (settings.id.isNotEmpty && settings.id != 'default_user') {
      _userIdController.text = settings.id;
    }
  }

  Future<void> _login() async {
    final userId = _userIdController.text.trim();

    if (userId.isEmpty) {
      setState(() => _errorMsg = '请输入用户ID');
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(userId)) {
      setState(() => _errorMsg = '用户ID只能包含字母、数字、下划线和连字符');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      // Test the API connection and auth by fetching records
      await WeightApiService().getWeightRecords(userId: userId, page: 1, pageSize: 1);

      // Save user ID to settings
      final settings = await _settingsService.loadSettings();
      final updated = settings.copyWith(
        id: userId,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _settingsService.saveSettings(updated);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(userId: userId, unit: updated.unit),
          ),
        );
      }
    } catch (e) {
      // If API call fails (e.g., server not reachable), still allow login
      // This enables offline usage and first-time setup
      final settings = await _settingsService.loadSettings();
      final updated = settings.copyWith(
        id: userId,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _settingsService.saveSettings(updated);

      if (mounted) {
	        final isOffline = ErrorHandler.isNetworkError(e);
	        if (isOffline) {
	          ScaffoldMessenger.of(context).showSnackBar(
	            const SnackBar(
	              content: Text('已离线登录，部分功能可能暂时不可用'),
	              behavior: SnackBarBehavior.floating,
	            ),
	          );
	        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(userId: userId, unit: updated.unit),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo / App name
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _bluePrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _bluePrimary.withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.monitor_weight,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    const Text(
                      '体重管理',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '记录体重，追踪健康',
                      style: TextStyle(
                        fontSize: 16,
                        color: _textMuted.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),

              // User ID Input
              const Text(
                '用户ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _errorMsg != null
                        ? Colors.red.withAlpha(128)
                        : const Color(0xFFE1E3E4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _userIdController,
                  style: const TextStyle(fontSize: 16, color: _textDark),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '输入您的用户ID',
                    hintStyle: TextStyle(color: Color(0xFFC1C7D1)),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMsg!,
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                ),
              ],

              const SizedBox(height: 24),

              // Login Button
              GestureDetector(
                onTap: _loading ? null : _login,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _bluePrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _bluePrimary.withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '登录',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip / Guest mode
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          final settings = await _settingsService.loadSettings();
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomePage(
                                  userId: settings.id,
                                  unit: settings.unit,
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(
                    '跳过，直接使用',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textMuted.withAlpha(153),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Info text
              Center(
                child: Text(
                  '后端服务地址: http://120.25.223.237:3000',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textMuted.withAlpha(102),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
