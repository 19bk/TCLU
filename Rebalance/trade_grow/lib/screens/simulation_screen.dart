import 'package:flutter/material.dart';
import '../models/trade_state.dart';
import '../widgets/trade_log_widget.dart';

class SimulationScreen extends StatefulWidget {
  final double startingCapital;
  const SimulationScreen({super.key, required this.startingCapital});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _targetController = TextEditingController();
  final _startController = TextEditingController();
  final _numTradesController = TextEditingController();
  double? targetAmount;
  double? startAmount;
  int? numTrades;
  List<TradeLog>? simulationLog;

  @override
  void initState() {
    super.initState();
    startAmount = widget.startingCapital;
    _startController.text = widget.startingCapital.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _targetController.dispose();
    _startController.dispose();
    _numTradesController.dispose();
    super.dispose();
  }

  void _onSimulateToTarget() {
    if (targetAmount == null || targetAmount! <= 0 || startAmount == null || startAmount! <= 0) return;
    final simState = TradeState(initialCapital: startAmount!);
    final List<TradeLog> simLog = [];
    while (simState.totalCapital < targetAmount!) {
      simState.simulateWin();
      simLog.add(simState.tradeHistory.last);
      if (simLog.length > 1000) break;
    }
    setState(() {
      simulationLog = simLog;
    });
  }

  void _onSimulateNumTrades() {
    if (numTrades == null || numTrades! <= 0 || startAmount == null || startAmount! <= 0) return;
    final simState = TradeState(initialCapital: startAmount!);
    final List<TradeLog> simLog = [];
    for (int i = 0; i < numTrades!; i++) {
      simState.simulateWin();
      simLog.add(simState.tradeHistory.last);
    }
    setState(() {
      simulationLog = simLog;
    });
  }

  InputDecoration _inputDecoration(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildStatsBar() {
    final trade = (startAmount ?? 0) * 0.4;
    final reserve = (startAmount ?? 0) * 0.6;
    final mutedGreen = Colors.green[400];
    final mutedBlue = Colors.blue[300];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statsItem('Start', '\u0024${(startAmount ?? 0).toStringAsFixed(0)}'),
          _statsItem('Trade (40%)', '\u0024${trade.toStringAsFixed(0)}', valueColor: mutedGreen),
          _statsItem('Reserve (60%)', '\u0024${reserve.toStringAsFixed(0)}', valueColor: mutedBlue),
        ],
      ),
    );
  }

  Widget _statsItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildSummary() {
    if (simulationLog == null || simulationLog!.isEmpty) return const SizedBox.shrink();
    final trades = simulationLog!.length;
    final finalCapital = simulationLog!.last.totalCapital;
    final totalGain = finalCapital - (startAmount ?? 0);
    final rebalances = simulationLog!.where((log) => log.wasRebalanced).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statsItem('Trades', trades.toString()),
          _statsItem('Final', '\u0024${finalCapital.toStringAsFixed(0)}'),
          _statsItem('Gain', '\u0024${totalGain.toStringAsFixed(0)}'),
          _statsItem('Rebalances', rebalances.toString()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulate to Target'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatsBar(),
                    TextField(
                      controller: _startController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Starting Balance', prefix: '\u0024'),
                      onChanged: (val) {
                        setState(() {
                          startAmount = double.tryParse(val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Target Amount', prefix: '\u0024'),
                      onChanged: (val) {
                        setState(() {
                          targetAmount = double.tryParse(val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _numTradesController,
                      keyboardType: TextInputType.numberWithOptions(decimal: false),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Number of Trades (Wins)'),
                      onChanged: (val) {
                        setState(() {
                          numTrades = int.tryParse(val);
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: (targetAmount != null && targetAmount! > 0 && startAmount != null && startAmount! > 0)
                              ? _onSimulateToTarget
                              : null,
                          child: const Text('Simulate to Target'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: (numTrades != null && numTrades! > 0 && startAmount != null && startAmount! > 0)
                              ? _onSimulateNumTrades
                              : null,
                          child: const Text('Simulate Trades'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _buildSummary(),
                    if (simulationLog != null) ...[
                      const Text('Simulation Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TradeLogWidget(
                        tradeHistory: simulationLog!,
                        showTitle: false,
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 