import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import '../services/weight_api_service.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'record_page.dart';

class TrendPage extends StatefulWidget {
  final String userId;
  final String unit;

  TrendPage({super.key, required this.userId, this.unit = 'kg'});

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  final WeightApiService _apiService = WeightApiService();
  List<WeightRecord> _records = [];
  WeightStats? _stats;
  bool _loading = true;
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 7));
  DateTime _rangeEnd = DateTime.now();
  int _selectedRangeIndex = 0;

  static const _bluePrimary = Color(0xFF106399);
  static const _textDark = Color(0xFF191C1D);
  static const _textMuted = Color(0xFF41474F);
  static const _bgGray = Color(0xFFF8F9FA);
  static const _borderGray = Color(0xFFE2E8F0);
  static const _morningOrange = Color(0xFFFC8A40);
  static const _eveningPurple = Color(0xFF9984FF);
  static const _accentBlue = Color(0xFF2563EB);

  final List<String> _rangeLabels = ['7天', '30天', '90天', '全部'];

  @override
  void initState() {
    super.initState();
    _loadData();
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
      final stats = await _apiService.getWeightStats(
        userId: widget.userId,
        startDate: _formatDate(_rangeStart),
        endDate: _formatDate(_rangeEnd),
      );
      setState(() {
        _records = records;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  void _onRangeChanged(int index) {
    final now = DateTime.now();
    setState(() {
      _selectedRangeIndex = index;
      switch (index) {
        case 0:
          _rangeStart = now.subtract(const Duration(days: 7));
          break;
        case 1:
          _rangeStart = now.subtract(const Duration(days: 30));
          break;
        case 2:
          _rangeStart = now.subtract(const Duration(days: 90));
          break;
        case 3:
          _rangeStart = DateTime(2000);
          break;
      }
      _rangeEnd = now;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: const Color(0x1A000000),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '体重管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _bluePrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: _textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    '趋势与统计',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.8,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '观察您的长期进展与规律',
                    style: TextStyle(fontSize: 16, color: _textMuted.withAlpha(179)),
                  ),
                  const SizedBox(height: 20),

                  // Time Range Filter
                  _buildRangeFilter(),
                  const SizedBox(height: 40),

                  // Line Chart
                  _buildChartSection(),
                  const SizedBox(height: 40),

                  // Statistics Grid
                  _buildStatsGrid(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildRangeFilter() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _bgGray,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderGray.withAlpha(128)),
      ),
      child: Row(
        children: List.generate(_rangeLabels.length, (index) {
          final isSelected = _selectedRangeIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onRangeChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _rangeLabels[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? _bluePrimary : _textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderGray.withAlpha(77)),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '体重变化趋势',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem(_morningOrange, '早晨'),
                  const SizedBox(width: 12),
                  _buildLegendItem(_eveningPurple, '夜晚'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: _buildDualLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _textMuted),
        ),
      ],
    );
  }

  Widget _buildDualLineChart() {
    final morningRecords = _records.where((r) => r.period == WeightPeriod.morning).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final eveningRecords = _records.where((r) => r.period == WeightPeriod.evening).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (morningRecords.isEmpty && eveningRecords.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }

    final allWeights = <double>[];
    morningRecords.forEach((r) => allWeights.add(r.weight));
    eveningRecords.forEach((r) => allWeights.add(r.weight));

    double minY = allWeights.isEmpty ? 0 : (allWeights.reduce((a, b) => a < b ? a : b) - 2);
    double maxY = allWeights.isEmpty ? 100 : (allWeights.reduce((a, b) => a > b ? a : b) + 2);

    final morningSpots = <FlSpot>[];
    for (int i = 0; i < morningRecords.length; i++) {
      morningSpots.add(FlSpot(i.toDouble(), morningRecords[i].weight));
    }

    final eveningSpots = <FlSpot>[];
    for (int i = 0; i < eveningRecords.length; i++) {
      eveningSpots.add(FlSpot(i.toDouble(), eveningRecords[i].weight));
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: _getChartInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0) return const SizedBox();
                if (morningRecords.isNotEmpty && index < morningRecords.length) {
                  final date = DateTime.parse(morningRecords[index].date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M月d日').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textMuted.withAlpha(179),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (morningSpots.isNotEmpty)
            LineChartBarData(
              spots: morningSpots,
              isCurved: true,
              color: _morningOrange,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 5,
                  color: _morningOrange,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _morningOrange.withValues(alpha: 0.08),
              ),
            ),
          if (eveningSpots.isNotEmpty)
            LineChartBarData(
              spots: eveningSpots,
              isCurved: true,
              color: _eveningPurple,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 5,
                  color: _eveningPurple,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _eveningPurple.withValues(alpha: 0.08),
              ),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final color = spot.bar.color ?? _bluePrimary;
                final label = color == _morningOrange ? '早' : '晚';
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} kg ($label)',
                  TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _getChartInterval() {
    if (morningRecords.isEmpty) return 1;
    final count = morningRecords.length;
    if (count <= 5) return 1;
    return ((count - 1) / 4).ceilToDouble();
  }

  List<WeightRecord> get morningRecords => _records
      .where((r) => r.period == WeightPeriod.morning)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<WeightRecord> get eveningRecords => _records
      .where((r) => r.period == WeightPeriod.evening)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  Widget _buildStatsGrid() {
    final stats = _stats;

    return Column(
      children: [
        // Top row: Avg Morning + Avg Evening
        Row(
          children: [
            Expanded(child: _buildStatCardAvgMorning()),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCardAvgEvening()),
          ],
        ),
        const SizedBox(height: 16),

        // Full width: Total Change
        _buildStatCardTotalChange(stats),
        const SizedBox(height: 16),

        // Bottom row: Min + Max
        Row(
          children: [
            Expanded(child: _buildStatCardMinWeight(stats)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCardMaxWeight(stats)),
          ],
        ),
        const SizedBox(height: 16),

        // Avg Diff
        _buildStatCardAvgDiff(stats),
      ],
    );
  }

  Widget _buildStatCardAvgMorning() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderGray.withAlpha(77)),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _morningOrange.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.wb_sunny, size: 14, color: _morningOrange),
              ),
              const SizedBox(width: 4),
              const Text(
                '平均早体重',
                style: TextStyle(
                  fontSize: 12,
                  color: _morningOrange,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _stats?.avgMorningWeight != null
                    ? _stats!.avgMorningWeight!.toStringAsFixed(1)
                    : '--',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.96,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Text('kg', style: TextStyle(fontSize: 16, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardAvgEvening() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderGray.withAlpha(77)),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _eveningPurple.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.nightlight, size: 14, color: _eveningPurple),
              ),
              const SizedBox(width: 4),
              const Text(
                '平均晚体重',
                style: TextStyle(
                  fontSize: 12,
                  color: _eveningPurple,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _stats?.avgEveningWeight != null
                    ? _stats!.avgEveningWeight!.toStringAsFixed(1)
                    : '--',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.96,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Text('kg', style: TextStyle(fontSize: 16, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardTotalChange(WeightStats? stats) {
    final change = stats?.change;
    final isNegative = change != null && change < 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 25),
      decoration: BoxDecoration(
        color: _bluePrimary.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bluePrimary.withAlpha(51)),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _bluePrimary.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  isNegative ? Icons.trending_down : Icons.trending_up,
                  size: 12,
                  color: _bluePrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '体重变化',
                style: TextStyle(
                  fontSize: 12,
                  color: _bluePrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                change != null
                    ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}'
                    : '--',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.96,
                  color: _bluePrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg',
                style: TextStyle(
                  fontSize: 16,
                  color: _bluePrimary.withAlpha(179),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardMinWeight(WeightStats? stats) {
    final minRecord = _getMinWeightRecord();

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderGray.withAlpha(77)),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _textMuted.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.arrow_downward, size: 8, color: _textMuted.withAlpha(179)),
              ),
              const SizedBox(width: 4),
              const Text(
                '最低体重',
                style: TextStyle(
                  fontSize: 12,
                  color: _textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                stats?.minWeight != null ? stats!.minWeight!.toStringAsFixed(1) : '--',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.64,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Text('kg', style: TextStyle(fontSize: 16, color: _textMuted)),
            ],
          ),
          if (minRecord != null) ...[
            const SizedBox(height: 4),
            Text(
              '${DateFormat('M月d日').format(DateTime.parse(minRecord.date))} 记录',
              style: TextStyle(fontSize: 12, color: _textMuted.withAlpha(153)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCardMaxWeight(WeightStats? stats) {
    final maxRecord = _getMaxWeightRecord();

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderGray.withAlpha(77)),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _textMuted.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.arrow_upward, size: 8, color: _textMuted.withAlpha(179)),
              ),
              const SizedBox(width: 4),
              const Text(
                '最高体重',
                style: TextStyle(
                  fontSize: 12,
                  color: _textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                stats?.maxWeight != null ? stats!.maxWeight!.toStringAsFixed(1) : '--',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.64,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Text('kg', style: TextStyle(fontSize: 16, color: _textMuted)),
            ],
          ),
          if (maxRecord != null) ...[
            const SizedBox(height: 4),
            Text(
              '${DateFormat('M月d日').format(DateTime.parse(maxRecord.date))} 记录',
              style: TextStyle(fontSize: 12, color: _textMuted.withAlpha(153)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCardAvgDiff(WeightStats? stats) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderGray.withAlpha(77)),
        boxShadow: const [
          BoxShadow(color: Color(0x145A9BD5), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 16,
                decoration: BoxDecoration(
                  color: _textMuted.withAlpha(26),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.balance, size: 12, color: _textMuted.withAlpha(179)),
              ),
              const SizedBox(width: 4),
              const Text(
                '平均早晚差值',
                style: TextStyle(
                  fontSize: 12,
                  color: _textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                stats?.avgWeightDiff != null
                    ? stats!.avgWeightDiff!.toStringAsFixed(1)
                    : '--',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.64,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Text('kg', style: TextStyle(fontSize: 16, color: _textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stats?.avgWeightDiff != null ? '处于健康波动范围内' : '暂无对比数据',
            style: TextStyle(fontSize: 12, color: _textMuted.withAlpha(153)),
          ),
        ],
      ),
    );
  }

  WeightRecord? _getMinWeightRecord() {
    if (_records.isEmpty) return null;
    final all = [..._records];
    all.sort((a, b) => a.weight.compareTo(b.weight));
    return all.first;
  }

  WeightRecord? _getMaxWeightRecord() {
    if (_records.isEmpty) return null;
    final all = [..._records];
    all.sort((a, b) => b.weight.compareTo(a.weight));
    return all.first;
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
          _navItem('趋势', Icons.show_chart, true, 2),
          _navItem('动态', Icons.dynamic_feed, false, 3),
        ],
      ),
    );
  }

  Widget _navItem(String label, IconData icon, bool isActive, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 2) return;
          Navigator.pop(context);
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => HomePage(userId: widget.userId, unit: widget.unit),
            ));
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecordPage(userId: widget.userId, unit: widget.unit),
            ));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => HistoryPage(userId: widget.userId, unit: widget.unit),
            ));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: index == 2 ? 20 : 18,
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
