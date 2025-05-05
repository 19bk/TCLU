import 'package:flutter/material.dart';
import '../models/trade_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/trade_buttons.dart';
import '../widgets/trade_log_widget.dart';
import 'simulation_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<double>? onCapitalChanged;
  const HomeScreen({super.key, this.onCapitalChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TradeState tradeState;
  late double initialCapital;
  final _initialCapitalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initialCapital = 3000.0;
    _resetTradeState();
  }

  @override
  void dispose() {
    _initialCapitalController.dispose();
    super.dispose();
  }

  void _resetTradeState() {
    setState(() {
      tradeState = TradeState(initialCapital: initialCapital);
    });
    widget.onCapitalChanged?.call(initialCapital);
  }

  void _onWin() {
    setState(() {
      tradeState.simulateWin();
    });
    widget.onCapitalChanged?.call(tradeState.totalCapital);
  }

  void _onLoss() {
    setState(() {
      tradeState.simulateLoss();
    });
    widget.onCapitalChanged?.call(tradeState.totalCapital);
  }

  void _onManualRebalance() {
    setState(() {
      tradeState.manualRebalance();
    });
    widget.onCapitalChanged?.call(tradeState.totalCapital);
  }

  Future<void> _showInitialCapitalDialog() async {
    _initialCapitalController.text = initialCapital.toString();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Initial Capital', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _initialCapitalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Initial Capital',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(_initialCapitalController.text);
              if (newValue != null && newValue > 0) {
                setState(() {
                  initialCapital = newValue;
                  _resetTradeState();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _goToSimulation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SimulationScreen(
          startingCapital: tradeState.totalCapital,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('TradeGrow 40/60 Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showInitialCapitalDialog,
            tooltip: 'Set Initial Capital',
          ),
        ],
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
                  BalanceCard(
                    totalCapital: tradeState.totalCapital,
                    tradeBalance: tradeState.tradeBalance,
                    reserveBalance: tradeState.reserveBalance,
                    tradesCount: tradeState.tradesCount,
                  ),
                  const SizedBox(height: 24),
                  TradeButtons(
                    onWin: _onWin,
                    onLoss: _onLoss,
                    onManualRebalance: _onManualRebalance,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _goToSimulation,
                    child: const Text('Simulate to Target'),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: TradeLogWidget(
                      tradeHistory: tradeState.tradeHistory,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 