import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double totalCapital;
  final double tradeBalance;
  final double reserveBalance;
  final int tradesCount;

  const BalanceCard({
    super.key,
    required this.totalCapital,
    required this.tradeBalance,
    required this.reserveBalance,
    required this.tradesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceRow(
              'Total Capital',
              totalCapital,
              Theme.of(context).textTheme.titleLarge,
              null,
            ),
            const SizedBox(height: 16),
            _buildBalanceRow(
              'Trade',
              tradeBalance,
              Theme.of(context).textTheme.titleMedium,
              '(${(tradeBalance / totalCapital * 100).toStringAsFixed(1)}%)',
            ),
            const SizedBox(height: 8),
            _buildBalanceRow(
              'Reserve',
              reserveBalance,
              Theme.of(context).textTheme.titleMedium,
              '(${(reserveBalance / totalCapital * 100).toStringAsFixed(1)}%)',
            ),
            const SizedBox(height: 16),
            Text(
              'Trades Made: $tradesCount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(
    String label,
    double amount,
    TextStyle? style,
    String? percentage,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Row(
          children: [
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: style,
            ),
            if (percentage != null) ...[
              const SizedBox(width: 4),
              Text(
                percentage,
                style: style?.copyWith(
                  fontSize: (style.fontSize ?? 14) * 0.8,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
} 