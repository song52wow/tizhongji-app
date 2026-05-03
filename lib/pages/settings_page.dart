import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_settings.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  final String userId;

  SettingsPage({super.key, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  UserSettings? _settings;
  bool _loading = true;

  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _settings = settings;
      _targetWeightController.text = settings.targetWeightKg?.toStringAsFixed(1) ?? '';
      _nicknameController.text = settings.nickname ?? '';
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final targetText = _targetWeightController.text.trim();
    double? targetWeight;
    if (targetText.isNotEmpty) {
      targetWeight = double.tryParse(targetText);
      if (targetWeight != null && (targetWeight < 20 || targetWeight > 300)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目标体重需在 20.0~300.0 kg 范围内')),
        );
        return;
      }
    }

    final updated = _settings!.copyWith(
      nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      targetWeightKg: targetWeight,
      unit: _settings!.unit,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _settingsService.saveSettings(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('设置已保存')));
    }
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSection(
                  '基本信息',
                  [
                    ListTile(
                      title: const Text('昵称'),
                      subtitle: TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          hintText: '输入昵称',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('体重单位'),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'kg', label: Text('kg')),
                          ButtonSegment(value: 'lb', label: Text('lb')),
                        ],
                        selected: {_settings!.unit},
                        onSelectionChanged: (set) async {
                          final updated = _settings!.copyWith(
                            unit: set.first,
                            updatedAt: DateTime.now().toIso8601String(),
                          );
                          await _settingsService.saveSettings(updated);
                          setState(() => _settings = updated);
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('目标体重'),
                      subtitle: TextField(
                        controller: _targetWeightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                        ],
                        decoration: InputDecoration(
                          hintText: '输入目标体重',
                          suffixText: _settings!.unitLabel,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildSection(
                  '提醒',
                  [
                    SwitchListTile(
                      title: const Text('早晨体重提醒'),
                      subtitle: _settings!.morningReminderEnabled
                          ? Text(_settings!.morningReminderTime ?? '08:00')
                          : null,
                      value: _settings!.morningReminderEnabled,
                      onChanged: (v) async {
                        final updated = _settings!.copyWith(
                          morningReminderEnabled: v,
                          morningReminderTime: v ? (_settings!.morningReminderTime ?? '08:00') : null,
                          updatedAt: DateTime.now().toIso8601String(),
                        );
                        await _settingsService.saveSettings(updated);
                        setState(() => _settings = updated);
                      },
                    ),
                    if (_settings!.morningReminderEnabled)
                      ListTile(
                        title: const Text('提醒时间'),
                        trailing: TextButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _parseTime(_settings!.morningReminderTime ?? '08:00'),
                            );
                            if (time != null) {
                              final updated = _settings!.copyWith(
                                morningReminderTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                updatedAt: DateTime.now().toIso8601String(),
                              );
                              await _settingsService.saveSettings(updated);
                              setState(() => _settings = updated);
                            }
                          },
                          child: Text(_settings!.morningReminderTime ?? '08:00'),
                        ),
                      ),
                    SwitchListTile(
                      title: const Text('晚上体重提醒'),
                      subtitle: _settings!.eveningReminderEnabled
                          ? Text(_settings!.eveningReminderTime ?? '22:00')
                          : null,
                      value: _settings!.eveningReminderEnabled,
                      onChanged: (v) async {
                        final updated = _settings!.copyWith(
                          eveningReminderEnabled: v,
                          eveningReminderTime: v ? (_settings!.eveningReminderTime ?? '22:00') : null,
                          updatedAt: DateTime.now().toIso8601String(),
                        );
                        await _settingsService.saveSettings(updated);
                        setState(() => _settings = updated);
                      },
                    ),
                    if (_settings!.eveningReminderEnabled)
                      ListTile(
                        title: const Text('提醒时间'),
                        trailing: TextButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _parseTime(_settings!.eveningReminderTime ?? '22:00'),
                            );
                            if (time != null) {
                              final updated = _settings!.copyWith(
                                eveningReminderTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                updatedAt: DateTime.now().toIso8601String(),
                              );
                              await _settingsService.saveSettings(updated);
                              setState(() => _settings = updated);
                            }
                          },
                          child: Text(_settings!.eveningReminderTime ?? '22:00'),
                        ),
                      ),
                  ],
                ),
                _buildSection(
                  '数据管理',
                  [
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('导出CSV'),
                      subtitle: const Text('导出所有体重记录'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV导出功能开发中')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('保存设置'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}