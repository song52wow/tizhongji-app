import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import '../services/weight_api_service.dart';
import 'record_page.dart';
import 'history_page.dart';
import 'trend_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String unit;

  HomePage({super.key, required this.userId, this.unit = 'kg'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final WeightApiService _apiService = WeightApiService();
  List<WeightRecord> _records = [];
  bool _loading = true;
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 7));
  final DateTime _rangeEnd = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final records = await _apiService.getWeightRecords(
        userId: widget.userId,
        startDate: _formatDate(_rangeStart),
        endDate: _formatDate(_rangeEnd),
        pageSize: 200,
      );
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  WeightRecord? get _todayMorningRecord {
    final today = _formatDate(DateTime.now());
    try {
      return _records.firstWhere((r) => r.date == today && r.period == WeightPeriod.morning);
    } catch (_) {
      return null;
    }
  }

  WeightRecord? get _todayEveningRecord {
    final today = _formatDate(DateTime.now());
    try {
      return _records.firstWhere((r) => r.date == today && r.period == WeightPeriod.evening);
    } catch (_) {
      return null;
    }
  }

  List<WeightRecord> get _recentRecords {
    final sorted = [..._records]..sort((a, b) => b.date.compareTo(a.date));
    final uniqueDates = <String>{};
    final result = <WeightRecord>[];
    for (final r in sorted) {
      if (uniqueDates.add(r.date)) {
        result.add(r);
        if (result.length >= 5) break;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final todayMorning = _todayMorningRecord;
    final todayEvening = _todayEveningRecord;
    final now = DateTime.now();
    final dateFormat = DateFormat('M月d日, EEEE');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: const Color(0x1A000000),
        title: const Text('体重管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('今天', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Color(0xFF191C1D))),
                      Text(dateFormat.format(now), style: const TextStyle(fontSize: 16, color: Color(0xFF41474F))),
                    ],
                  ),
                  const SizedBox(height: 39),

                  // Weight Cards Grid
                  _buildWeightCards(todayMorning, todayEvening),
                  const SizedBox(height: 24),

                  // 7-day Trend
                  _buildTrendSection(),
                ],
              ),
            ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF106399),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _navigateToRecord(_formatDate(DateTime.now())),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildWeightCards(WeightRecord? todayMorning, WeightRecord? todayEvening) {
    return Column(
      children: [
        // Morning Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 25.1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E3E4)),
            boxShadow: const [BoxShadow(color: Color(0x145A9BD5), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: const Color(0xFFFFDBC9), borderRadius: BorderRadius.circular(999)),
                    child: const Icon(Icons.wb_sunny, size: 16.5, color: Color(0xFF106399)),
                  ),
                  const SizedBox(width: 8),
                  const Text('早晨体重', style: TextStyle(fontSize: 12, color: Color(0xFF41474F))),
                  const Spacer(),
                  Text(todayMorning != null ? DateFormat('HH:mm').format(DateTime.now()) : '--:--',
                       style: const TextStyle(fontSize: 12, color: Color(0xFF717880))),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    todayMorning?.weight.toStringAsFixed(1) ?? '--',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600, color: Color(0xFF191C1D), letterSpacing: -0.96),
                  ),
                  const SizedBox(width: 4),
                  const Text('kg', style: TextStyle(fontSize: 18, color: Color(0xFF41474F))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.arrow_downward, size: 10.67, color: Color(0xFF106399)),
                  const SizedBox(width: 4),
                  Text(
                    _getMorningChange(),
                    style: const TextStyle(fontSize: 16, color: Color(0xFF106399)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Evening Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 25.1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E3E4)),
            boxShadow: const [BoxShadow(color: Color(0x145A9BD5), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: const Color(0xFFE6DEFF), borderRadius: BorderRadius.circular(999)),
                        child: const Icon(Icons.nightlight, size: 13.5, color: Color(0xFF6042D6)),
                      ),
                      const SizedBox(width: 8),
                      const Text('晚上体重', style: TextStyle(fontSize: 12, color: Color(0xFF41474F))),
                      const Spacer(),
                      Text(todayEvening != null ? DateFormat('HH:mm').format(DateTime.now()) : '--:--',
                           style: const TextStyle(fontSize: 12, color: Color(0xFF717880))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        todayEvening?.weight.toStringAsFixed(1) ?? '--',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600, color: Color(0xFF191C1D), letterSpacing: -0.96),
                      ),
                      const SizedBox(width: 4),
                      const Text('kg', style: TextStyle(fontSize: 18, color: Color(0xFF41474F))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.balance, size: 13.33, color: Color(0xFF41474F)),
                      const SizedBox(width: 4),
                      Text(
                        _getEveningChange(),
                        style: const TextStyle(fontSize: 16, color: Color(0xFF41474F)),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [const Color(0xFFE6DEFF).withValues(alpha: 0.2), const Color(0xFFE6DEFF).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMorningChange() {
    final records = _recentRecords.where((r) => r.period == WeightPeriod.morning).toList();
    if (records.length < 2) return '暂无对比数据';
    final yesterday = records[1].weight;
    final today = records[0].weight;
    final diff = today - yesterday;
    return '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}kg 较昨日';
  }

  String _getEveningChange() {
    if (_todayMorningRecord == null || _todayEveningRecord == null) return '暂无对比数据';
    final diff = _todayEveningRecord!.weight - _todayMorningRecord!.weight;
    return '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}kg 较早晨';
  }

  Widget _buildTrendSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 26, 25, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E3E4)),
        boxShadow: const [BoxShadow(color: Color(0x145A9BD5), blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('近7天趋势', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Color(0xFF191C1D))),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF717880)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: _buildSparkline(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_getDateRange(), style: const TextStyle(fontSize: 12, color: Color(0xFF717880))),
              const Text('今天', style: TextStyle(fontSize: 12, color: Color(0xFF717880))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline() {
    final morningRecords = _records.where((r) => r.period == WeightPeriod.morning).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (morningRecords.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < morningRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), morningRecords[i].weight));
    }

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF106399),
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 5,
                color: const Color(0xFF106399),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF106399).withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }

  String _getDateRange() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    return DateFormat('M/d').format(weekAgo);
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: const [BoxShadow(color: Color(0x145A9BD5), blurRadius: 6, offset: Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, '总览', 'assets/icons/overview.png', true),
          _buildNavItem(1, '记录', 'assets/icons/record.png', false),
          _buildNavItem(2, '趋势', 'assets/icons/trend.png', false),
          _buildNavItem(3, '动态', 'assets/icons/feed.png', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconPath, bool isActive) {
    return Expanded(
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecordPage(userId: widget.userId, initialDate: _formatDate(DateTime.now()), unit: widget.unit),
            )).then((_) => _loadData());
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => TrendPage(userId: widget.userId, unit: widget.unit),
            )).then((_) => _loadData());
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => HistoryPage(userId: widget.userId, unit: widget.unit),
            )).then((_) => _loadData());
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              index == 0 ? Icons.dashboard : (index == 1 ? Icons.edit_note : (index == 2 ? Icons.show_chart : Icons.dynamic_feed)),
              size: index == 3 ? 20 : 18,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRecord(String? date) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordPage(userId: widget.userId, initialDate: date, unit: widget.unit),
      ),
    );
    _loadData();
  }
}