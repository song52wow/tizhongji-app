import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import '../services/weight_api_service.dart';
import 'record_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String unit;

  HomePage({super.key, required this.userId, this.unit = 'kg'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeightApiService _apiService = WeightApiService();
  List<WeightRecord> _records = [];
  WeightStats? _stats;
  String _rangeLabel = '30天';
  bool _loading = true;
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _rangeEnd = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
    final todayMorning = _todayMorningRecord;
    final todayEvening = _todayEveningRecord;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy年M月d日').format(DateTime.now())),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _navigateToHistory(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTodaySection(todayMorning, todayEvening),
                  const SizedBox(height: 16),
                  _buildChart(),
                  const SizedBox(height: 16),
                  _buildStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildTodaySection(WeightRecord? todayMorning, WeightRecord? todayEvening) {
    final hasAny = todayMorning != null || todayEvening != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTodayWeightTile(
                    '早晨体重',
                    todayMorning?.weight,
                    Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTodayWeightTile(
                    '晚上体重',
                    todayEvening?.weight,
                    Icons.nightlight_outlined,
                  ),
                ),
              ],
            ),
            if (todayMorning?.note != null && todayMorning!.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(todayMorning.note!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
            if (todayEvening?.note != null && todayEvening!.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(todayEvening.note!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToRecord(_formatDate(DateTime.now())),
                icon: const Icon(Icons.edit),
                label: Text(hasAny ? '编辑记录' : '添加今日记录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayWeightTile(String label, double? weight, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            weight != null ? '${weight.toStringAsFixed(1)} ${widget.unit}' : '--',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final hasData = _records.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('体重趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    final now = DateTime.now();
                    setState(() {
                      _rangeLabel = v;
                      switch (v) {
                        case '7天':
                          _rangeStart = now.subtract(const Duration(days: 7));
                          _rangeEnd = now;
                          break;
                        case '30天':
                          _rangeStart = now.subtract(const Duration(days: 30));
                          _rangeEnd = now;
                          break;
                        case '90天':
                          _rangeStart = now.subtract(const Duration(days: 90));
                          _rangeEnd = now;
                          break;
                      }
                    });
                    _loadData();
                  },
                  itemBuilder: (context) => ['7天', '30天', '90天', '全部']
                      .map((v) => PopupMenuItem(value: v, child: Text(v)))
                      .toList(),
                  child: Row(
                    children: [
                      Text(_rangeLabel, style: const TextStyle(color: Colors.blue)),
                      const Icon(Icons.arrow_drop_down, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _legendItem('晨重', Colors.orange),
                const SizedBox(width: 16),
                _legendItem('晚重', Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: hasData ? _buildLineChart() : _buildEmptyChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLineChart() {
    // 收集所有日期用于 X 轴
    final dates = _records.map((r) => r.date).toSet().toList()..sort();
    final dateIndex = <String, int>{};
    for (int i = 0; i < dates.length; i++) {
      dateIndex[dates[i]] = i;
    }

    final morningSpots = <FlSpot>[];
    final eveningSpots = <FlSpot>[];

    for (final r in _records) {
      final x = (dateIndex[r.date] ?? 0).toDouble();
      if (r.period == WeightPeriod.morning) {
        morningSpots.add(FlSpot(x, r.weight));
      } else {
        eveningSpots.add(FlSpot(x, r.weight));
      }
    }

    double minY = 0, maxY = 100;
    final allWeights = [...morningSpots.map((s) => s.y), ...eveningSpots.map((s) => s.y)]
        .where((w) => w > 0)
        .toList();
    if (allWeights.isNotEmpty) {
      minY = allWeights.reduce((a, b) => a < b ? a : b) - 2;
      maxY = allWeights.reduce((a, b) => a > b ? a : b) + 2;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (dates.length / 5).ceilToDouble().clamp(1, 10),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < dates.length) {
                  return Text(dates[idx].substring(5), style: const TextStyle(fontSize: 10));
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: morningSpots,
            isCurved: true,
            color: Colors.orange,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: eveningSpots,
            isCurved: true,
            color: Colors.purple,
            dotData: const FlDotData(show: true),
          ),
        ],
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            if (event is! FlLongPressStart) return;
            if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) return;
            final spot = response.lineBarSpots!.first;
            final dateIdx = spot.x.toInt();
            final dates = _records.map((r) => r.date).toSet().toList()..sort();
            if (dateIdx >= 0 && dateIdx < dates.length) {
              _navigateToRecordWithLongPress(dates[dateIdx]);
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final dateIdx = spot.x.toInt();
                final dates = _records.map((r) => r.date).toSet().toList()..sort();
                final date = dateIdx < dates.length ? dates[dateIdx] : '';
                final label = spot.barIndex == 0 ? '晨' : '晚';
                return LineTooltipItem(
                  '$date\n$label: ${spot.y.toStringAsFixed(1)}${widget.unit}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('暂无数据', style: TextStyle(color: Colors.grey)),
          Text('记录第一天的体重吧', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (_stats == null) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('统计摘要', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statItem('平均晨重', '${_stats!.avgMorningWeight?.toStringAsFixed(1) ?? '--'} ${widget.unit}'),
                _statItem('平均晚重', '${_stats!.avgEveningWeight?.toStringAsFixed(1) ?? '--'} ${widget.unit}'),
                _statItem('最低体重', '${_stats!.minWeight?.toStringAsFixed(1) ?? '--'} ${widget.unit}'),
                _statItem('最高体重', '${_stats!.maxWeight?.toStringAsFixed(1) ?? '--'} ${widget.unit}'),
                _statItem('体重变化', '${(_stats!.change ?? 0) >= 0 ? '+' : ''}${( (_stats!.change ?? 0)).toStringAsFixed(1)} ${widget.unit}'),
                if (_stats!.avgWeightDiff != null)
                  _statItem('平均差值', '${(_stats!.avgWeightDiff ?? 0) >= 0 ? '+' : ''}${( _stats!.avgWeightDiff ?? 0).toStringAsFixed(1)} ${widget.unit}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
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

  void _navigateToRecordWithLongPress(String date) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordPage(userId: widget.userId, initialDate: date, unit: widget.unit),
      ),
    );
    _loadData();
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(userId: widget.userId, unit: widget.unit),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(userId: widget.userId),
      ),
    ).then((_) => _loadData());
  }
}