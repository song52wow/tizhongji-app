import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import '../services/weight_api_service.dart';
import 'home_page.dart';
import 'record_page.dart';
import 'trend_page.dart';

class HistoryPage extends StatefulWidget {
  final String userId;
  final String unit;

  HistoryPage({super.key, required this.userId, this.unit = 'kg'});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final WeightApiService _apiService = WeightApiService();
  List<WeightRecord> _records = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  final int _pageSize = 30;
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
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
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page++;
    await _loadRecords();
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
          IconButton(
            icon: const Icon(Icons.more_horiz, color: _textDark),
            onPressed: () {},
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
    return _loading && _records.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _records.isEmpty
            ? const Center(child: Text('暂无记录'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: _records.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _records.length) {
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
                  return _buildRecordItem(_records[index]);
                },
              );
  }

  Widget _buildRecordItem(WeightRecord record) {
    final date = DateTime.parse(record.date);
    final isMorning = record.period == WeightPeriod.morning;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordPage(
              userId: widget.userId,
              initialDate: record.date,
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
                  'kg',
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

  Widget _buildNotificationsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_outlined, size: 64, color: _textMuted.withAlpha(102)),
          const SizedBox(height: 16),
          Text(
            '暂无通知',
            style: TextStyle(fontSize: 16, color: _textMuted.withAlpha(153)),
          ),
        ],
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
