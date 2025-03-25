import 'package:flutter/material.dart';
import '../models/trade_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/trade_buttons.dart';
import '../widgets/trade_log_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  }

  void _onWin() {
    setState(() {
      tradeState.simulateWin();
    });
  }

  void _onLoss() {
    setState(() {
      tradeState.simulateLoss();
    });
  }

  void _onManualRebalance() {
    setState(() {
      tradeState.manualRebalance();
    });
  }

  Future<void> _showInitialCapitalDialog() async {
    _initialCapitalController.text = initialCapital.toString();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Initial Capital'),
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
          TextButton(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('TradeGrow - 40/60 Simulator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showInitialCapitalDialog,
          ),
        ],
      ),
      body: SafeArea(
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
              Expanded(
                child: TradeLogWidget(
                  tradeHistory: tradeState.tradeHistory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 