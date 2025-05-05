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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Capital',
                style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '\u0024${totalCapital.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildBalanceColumn('Trade (40%)', tradeBalance, totalCapital),
              const SizedBox(width: 10),
              _buildBalanceColumn('Reserve (60%)', reserveBalance, totalCapital),
            ],
          ),
          const SizedBox(height: 14),
          Text('Trades Made: $tradesCount', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBalanceColumn(String label, double value, double total) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              '\u0024${value.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
            const SizedBox(height: 1),
            Text(
              '(${(value / total * 100).round()}%)',
              style: TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
} 