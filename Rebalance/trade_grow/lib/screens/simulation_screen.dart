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
  double? targetAmount;
  List<TradeLog>? simulationLog;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _onSimulateToTarget() {
    if (targetAmount == null || targetAmount! <= 0) return;
    final simState = TradeState(initialCapital: widget.startingCapital);
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

  Widget _buildSummary() {
    if (simulationLog == null || simulationLog!.isEmpty) return const SizedBox.shrink();
    final trades = simulationLog!.length;
    final finalCapital = simulationLog!.last.totalCapital;
    final totalGain = finalCapital - widget.startingCapital;
    final rebalances = simulationLog!.where((log) => log.wasRebalanced).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _summaryItem('Trades', trades.toString()),
          _summaryItem('Final', '\u0024${finalCapital.toStringAsFixed(2)}'),
          _summaryItem('Gain', '\u0024${totalGain.toStringAsFixed(2)}'),
          _summaryItem('Rebalances', rebalances.toString()),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulate to Target'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Target Amount',
                            prefixText: '\u0024',
                          ),
                          onChanged: (val) {
                            setState(() {
                              targetAmount = double.tryParse(val);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: (targetAmount != null && targetAmount! > 0)
                            ? _onSimulateToTarget
                            : null,
                        child: const Text('Simulate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSummary(),
                  if (simulationLog != null) ...[
                    const Text('Simulation Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TradeLogWidget(tradeHistory: simulationLog!),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 