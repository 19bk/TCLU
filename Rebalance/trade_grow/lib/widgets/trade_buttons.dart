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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onWin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simulate Win',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onLoss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Loss',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onManualRebalance,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Manual Rebalance',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
} 