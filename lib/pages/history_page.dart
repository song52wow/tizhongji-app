import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import '../models/notification.dart';
import '../services/weight_api_service.dart';
import '../services/notification_api_service.dart';
import '../utils/error_handler.dart';
import '../utils/widgets.dart';
import 'home_page.dart';
import 'record_page.dart';
import 'trend_page.dart';
import 'notification_center_page.dart';

class HistoryPage extends StatefulWidget {
  final String userId;
  final String unit;

  HistoryPage({super.key, required this.userId, this.unit = 'kg'});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final WeightApiService _apiService = WeightApiService();
  final NotificationApiService _notifService = NotificationApiService();
  List<WeightRecord> _records = [];
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _recordsErrorMsg;
  bool _notifLoading = true;
  int _page = 1;
  int _notifPage = 1;
  bool _hasMore = true;
  bool _notifHasMore = true;
  final int _pageSize = 30;
  final int _notifPageSize = 20;
  int _unreadCount = 0;
  late TabController _tabController;

  static const _bluePrimary = Color(0xFF106399);
  static const _textDark = Color(0xFF191C1D);
  static const _textMuted = Color(0xFF41474F);
  static const _bgGray = Color(0xFFF8F9FA);
  static const _borderGray = Color(0xFFE1E3E4);
  static const _morningOrange = Color(0xFFFFDBC9);
  static const _eveningPurple = Color(0xFFE6DEFF);
  static const _morningText = Color(0xFF9B4500);
  static const _eveningText = Color(0xFF6042D6);
  static const _accentBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecords();
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      if (_page == 1) _recordsErrorMsg = null;
    });
    try {
      final records = await _apiService.getWeightRecords(
        userId: widget.userId,
        page: _page,
        pageSize: _pageSize,
      );
      setState(() {
        if (_page == 1) {
          _records = records;
        } else {
          _records.addAll(records);
        }
        _hasMore = records.length >= _pageSize;
        _loading = false;
        _recordsErrorMsg = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _recordsErrorMsg = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _notifLoading = true);
    try {
      final result = await _notifService.getNotifications(
        userId: widget.userId,
        page: _notifPage,
        pageSize: _notifPageSize,
      );
      setState(() {
        if (_notifPage == 1) {
          _notifications = result.items;
        } else {
          _notifications.addAll(result.items);
        }
        _notifHasMore = result.items.length >= _notifPageSize;
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        _notifLoading = false;
      });
    } catch (e) {
      setState(() => _notifLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page++;
    await _loadRecords();
  }

  Future<void> _loadMoreNotifications() async {
    if (_notifLoading || !_notifHasMore) return;
    _notifPage++;
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notifService.markAllAsRead(widget.userId);
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
        _unreadCount = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败：${ErrorHandler.getErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await _notifService.markAsRead(notification.id, widget.userId);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notification.id);
        if (idx != -1) {
          _notifications[idx] = notification.copyWith(isRead: true);
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
      });
    } catch (_) {}
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await _notifService.deleteNotification(notification.id, widget.userId);
      setState(() {
        if (!notification.isRead) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：${ErrorHandler.getErrorMessage(e)}')),
        );
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          '体重管理',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _bluePrimary),
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accentBlue.withAlpha(26),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$_unreadCount条未读',
                style: const TextStyle(fontSize: 12, color: _accentBlue),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: _textDark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationCenterPage(
                    userId: widget.userId,
                    unit: widget.unit,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // Console Title
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '中心控制台',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '查看您的活动足迹与系统提醒',
                        style: TextStyle(fontSize: 16, color: _textMuted.withAlpha(179)),
                      ),
                      const SizedBox(height: 20),
                      // Tab Bar
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _bgGray,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(0),
                                child: ListenableBuilder(
                                  listenable: _tabController,
                                  builder: (context, child) {
                                    final isHistory = _tabController.index == 0;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isHistory ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: isHistory
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withAlpha(15),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '历史记录',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isHistory ? _textDark : _textMuted,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(1),
                                child: ListenableBuilder(
                                  listenable: _tabController,
                                  builder: (context, child) {
                                    final isNotifications = _tabController.index == 1;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isNotifications ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: isNotifications
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withAlpha(15),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '通知中心',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isNotifications ? _textDark : _textMuted,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryTab(),
                      _buildNotificationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loading && _records.isEmpty) {
      return const ListItemSkeleton();
    }
    if (_recordsErrorMsg != null && _records.isEmpty) {
      return AppErrorState(
        message: _recordsErrorMsg!,
        onRetry: () {
          setState(() => _page = 1);
          _loadRecords();
        },
      );
    }
    if (_records.isEmpty) {
      return const AppEmptyState(
        title: '暂无记录',
        subtitle: '开始记录您的第一条体重数据吧',
        icon: Icons.monitor_weight_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _records.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _records.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: AppLoadingIndicator(size: 24),
          );
        }
        return _buildRecordItem(_records[index]);
      },
    );
  }


  Widget _buildNotificationsTab() {
    if (_notifLoading && _notifications.isEmpty) {
      return const NotificationItemSkeleton();
    }
    if (_notifications.isEmpty) {
      return const AppEmptyState(
        title: '暂无通知',
        subtitle: '这里将显示您的所有通知',
        icon: Icons.notifications_none,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: _notifications.length + (_notifHasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: AppLoadingIndicator(size: 24),
          );
        }
        return _buildNotificationItem(_notifications[index]);
      },
    );
  }
  Widget _buildRecordItem(WeightRecord record) {
    final date = DateTime.tryParse(record.date) ?? DateTime.now();
    final isMorning = record.period == WeightPeriod.morning;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordPage(
              userId: widget.userId,
              initialDate: record.date,
              initialPeriod: record.period,
              unit: widget.unit,
            ),
          ),
        );
        setState(() => _page = 1);
        _loadRecords();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _bgGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isMorning ? _morningOrange : _eveningPurple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMorning ? Icons.wb_sunny : Icons.nightlight,
                size: 20,
                color: isMorning ? _morningText : _eveningText,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('M月d日').format(date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  if (record.note != null && record.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      record.note!,
                      style: TextStyle(fontSize: 12, color: _textMuted.withAlpha(179)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record.weight.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMorning ? _morningText : _eveningText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        onTap: () => _markAsRead(notification),
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
                          style: TextStyle(fontSize: 12, color: _textMuted.withAlpha(153)),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return const Color(0xFF16A34A);
      case NotificationType.order:
        return const Color(0xFF2563EB);
      case NotificationType.message:
        return const Color(0xFF7C3AED);
      case NotificationType.campaign:
        return const Color(0xFFEA580C);
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
          if (index == 3) return;
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
