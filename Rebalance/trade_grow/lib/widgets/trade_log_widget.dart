import 'package:flutter/material.dart';
import '../models/trade_state.dart';

class TradeLogWidget extends StatelessWidget {
  final List<TradeLog> tradeHistory;

  const TradeLogWidget({
    super.key,
    required this.tradeHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Trade Log',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: tradeHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No trades yet',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: tradeHistory.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, index) {
                      final trade = tradeHistory[index];
                      final tradeNumber = index + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tradeNumber.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Trade $tradeNumber: ${trade.isWin ? "Win" : "Loss"}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: trade.isWin ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (trade.gain != null)
                                        Text(
                                          '+\u0024${trade.gain!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        )
                                      else if (trade.loss != null)
                                        Text(
                                          '-\u0024${trade.loss!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Trade: \u0024${trade.tradeBalance.toStringAsFixed(2)} | Reserve: \u0024${trade.reserveBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (trade.transferredFromReserve != null && trade.transferredFromReserve! > 0)
                                    Text(
                                      'Restored trade balance: +\u0024${trade.transferredFromReserve!.toStringAsFixed(2)} from reserve',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  if (trade.wasRebalanced)
                                    Text(
                                      'Rebalanced to 40/60 split',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
} 