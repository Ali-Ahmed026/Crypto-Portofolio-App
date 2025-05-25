import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/coingecko_service.dart';

class HistoricalScreen extends StatefulWidget {
  const HistoricalScreen({Key? key}) : super(key: key);

  @override
  State<HistoricalScreen> createState() => _HistoricalScreenState();
}

class _HistoricalScreenState extends State<HistoricalScreen> {
  String _selectedCoin = 'bitcoin';
  String _selectedTimeframe = '7d';
  List<FlSpot> _priceData = [];
  bool _isLoading = true;
  String? _error;
  double _minY = 0;
  double _maxY = 0;

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await CoinGeckoService.getHistoricalPrices(
        _selectedCoin,
        _selectedTimeframe,
      );

      if (data.isEmpty) {
        setState(() {
          _error = 'No data available';
          _isLoading = false;
        });
        return;
      }

      // Convert data to chart points
      final points = data.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value);
      }).toList();

      // Calculate min and max Y values for chart scaling
      _minY = data.reduce((curr, next) => curr < next ? curr : next);
      _maxY = data.reduce((curr, next) => curr > next ? curr : next);

      // Add some padding to min/max
      final padding = (_maxY - _minY) * 0.1;
      _minY -= padding;
      _maxY += padding;

      setState(() {
        _priceData = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load historical data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coin Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Coin',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCoin,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.currency_bitcoin),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'bitcoin',
                          child: Text('Bitcoin (BTC)'),
                        ),
                        DropdownMenuItem(
                          value: 'ethereum',
                          child: Text('Ethereum (ETH)'),
                        ),
                        DropdownMenuItem(
                          value: 'binancecoin',
                          child: Text('Binance Coin (BNB)'),
                        ),
                        DropdownMenuItem(
                          value: 'ripple',
                          child: Text('Ripple (XRP)'),
                        ),
                        DropdownMenuItem(
                          value: 'cardano',
                          child: Text('Cardano (ADA)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCoin = value;
                          });
                          _loadHistoricalData();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeframe Selection
            Row(
              children: [
                _TimeframeButton(
                  label: '7D',
                  isSelected: _selectedTimeframe == '7d',
                  onTap: () {
                    setState(() {
                      _selectedTimeframe = '7d';
                    });
                    _loadHistoricalData();
                  },
                ),
                const SizedBox(width: 8),
                _TimeframeButton(
                  label: '30D',
                  isSelected: _selectedTimeframe == '30d',
                  onTap: () {
                    setState(() {
                      _selectedTimeframe = '30d';
                    });
                    _loadHistoricalData();
                  },
                ),
                const SizedBox(width: 8),
                _TimeframeButton(
                  label: '90D',
                  isSelected: _selectedTimeframe == '90d',
                  onTap: () {
                    setState(() {
                      _selectedTimeframe = '90d';
                    });
                    _loadHistoricalData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price Chart
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _loadHistoricalData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price History',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: LineChart(
                                    LineChartData(
                                      gridData: const FlGridData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      minX: 0,
                                      maxX: _priceData.length.toDouble() - 1,
                                      minY: _minY,
                                      maxY: _maxY,
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _priceData,
                                          isCurved: true,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          barWidth: 2,
                                          dotData: FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Color.fromRGBO(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .red,
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .green,
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .blue,
                                              0.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeframeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeframeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
