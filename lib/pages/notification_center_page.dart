import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../services/notification_api_service.dart';
import '../utils/error_handler.dart';
import '../utils/widgets.dart';
import 'home_page.dart';
import 'record_page.dart';
import 'trend_page.dart';

class NotificationCenterPage extends StatefulWidget {
  final String userId;
  final String unit;

  NotificationCenterPage({super.key, required this.userId, this.unit = 'kg'});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final NotificationApiService _apiService = NotificationApiService();
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _errorMsg;
  int _page = 1;
  bool _hasMore = true;
  final int _pageSize = 20;
  int _unreadCount = 0;

  static const _bluePrimary = Color(0xFF106399);
  static const _textDark = Color(0xFF191C1D);
  static const _textMuted = Color(0xFF41474F);
  static const _bgGray = Color(0xFFF8F9FA);
  static const _borderGray = Color(0xFFE1E3E4);
  static const _accentBlue = Color(0xFF2563EB);
  static const _systemGreen = Color(0xFF16A34A);
  static const _orderBlue = Color(0xFF2563EB);
  static const _messagePurple = Color(0xFF7C3AED);
  static const _campaignOrange = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final result = await _apiService.getNotifications(
        userId: widget.userId,
        page: _page,
        pageSize: _pageSize,
      );
      setState(() {
        if (_page == 1) {
          _notifications = result.items;
        } else {
          _notifications.addAll(result.items);
        }
        _hasMore = result.items.length >= _pageSize;
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page++;
    await _loadNotifications();
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await _apiService.markAsRead(notification.id, widget.userId);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notification.id);
        if (idx != -1) {
          _notifications[idx] = notification.copyWith(isRead: true);
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiService.markAllAsRead(widget.userId);
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
        _unreadCount = 0;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请重试')),
      );
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await _apiService.deleteNotification(notification.id, widget.userId);
      setState(() {
        if (!notification.isRead) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败，请重试')),
      );
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return _systemGreen;
      case NotificationType.order:
        return _orderBlue;
      case NotificationType.message:
        return _messagePurple;
      case NotificationType.campaign:
        return _campaignOrange;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.order:
        return Icons.receipt_long;
      case NotificationType.message:
        return Icons.mail;
      case NotificationType.campaign:
        return Icons.campaign;
    }
  }

  String _formatTime(String createdAt) {
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return DateFormat('M月d日').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withAlpha(13),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '通知中心',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _bluePrimary),
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                '全部已读',
                style: TextStyle(fontSize: 14, color: _accentBlue),
              ),
            ),
        ],
      ),
      body: _loading && _notifications.isEmpty
          ? const AppLoadingIndicator()
          : _errorMsg != null && _notifications.isEmpty
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationList(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      title: '暂无通知',
      subtitle: '这里将显示您的所有通知',
      icon: Icons.notifications_none,
    );
  }

  Widget _buildErrorState() {
    return AppErrorState(
      message: _errorMsg!,
      icon: Icons.error_outline,
      onRetry: () {
        setState(() {
          _errorMsg = null;
          _page = 1;
        });
        _loadNotifications();
      },
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _loadMore,
                      child: const Text('加载更多'),
                    ),
            ),
          );
        }
        return _buildNotificationItem(_notifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final typeColor = _getTypeColor(notification.type);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteNotification(notification);
        return false;
      },
      child: GestureDetector(
        onTap: () {
          _markAsRead(notification);
          _showNotificationDetail(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF0F7FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread ? _accentBlue.withAlpha(51) : _borderGray.withAlpha(128),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isUnread ? 10 : 5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  size: 18,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: _accentBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: _textMuted.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: _textMuted.withAlpha(179),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notification.typeLabel,
                            style: TextStyle(fontSize: 10, color: typeColor),
                          ),
                        ),
                        if (notification.priority == Priority.high) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(26),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '重要',
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _NotificationDetailSheet(
        notification: notification,
        typeColor: _getTypeColor(notification.type),
        typeIcon: _getTypeIcon(notification.type),
        timeStr: _formatTime(notification.createdAt),
        onDelete: () {
          Navigator.pop(context);
          _deleteNotification(notification);
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 6, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem('总览', Icons.dashboard_outlined, false, 0),
          _navItem('记录', Icons.edit_note, false, 1),
          _navItem('趋势', Icons.show_chart, false, 2),
          _navItem('动态', Icons.dynamic_feed, false, 3),
        ],
      ),
    );
  }

  Widget _navItem(String label, IconData icon, bool isActive, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => HomePage(userId: widget.userId, unit: widget.unit),
            ));
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecordPage(userId: widget.userId, unit: widget.unit),
            ));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => TrendPage(userId: widget.userId, unit: widget.unit),
            ));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? _accentBlue : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? _accentBlue : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final AppNotification notification;
  final Color typeColor;
  final IconData typeIcon;
  final String timeStr;
  final VoidCallback onDelete;

  const _NotificationDetailSheet({
    required this.notification,
    required this.typeColor,
    required this.typeIcon,
    required this.timeStr,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E3E4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(typeIcon, size: 18, color: typeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF191C1D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF41474F).withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              notification.content,
              style: const TextStyle(fontSize: 15, color: Color(0xFF191C1D)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  notification.typeLabel,
                  style: TextStyle(fontSize: 12, color: typeColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '优先级: ${notification.priorityLabel}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF41474F)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
