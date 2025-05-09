import 'package:flutter/material.dart';

class TradeButtons extends StatelessWidget {
  final VoidCallback onWin;
  final VoidCallback onLoss;
  final VoidCallback onManualRebalance;

  const TradeButtons({
    super.key,
    required this.onWin,
    required this.onLoss,
    required this.onManualRebalance,
  });

  @override
  Widget build(BuildContext context) {
    final darkButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onWin,
                style: darkButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(Colors.green[700]),
                ),
                child: const Text(
                  '+',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onLoss,
                style: darkButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(Colors.red[700]),
                ),
                child: const Text(
                  '-',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onManualRebalance,
          style: darkButtonStyle,
          child: const Text(
            'Manual Rebalance',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
} 