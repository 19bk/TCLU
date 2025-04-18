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
          'Trade Log:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: tradeHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No trades yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tradeHistory.length,
                    itemBuilder: (context, index) {
                      final trade = tradeHistory[index];
                      final tradeNumber = index + 1;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: trade.isWin ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  tradeNumber.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Trade $tradeNumber: ${trade.isWin ? "Win" : "Loss"}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (trade.gain != null)
                                        Text(
                                          '+\$${trade.gain!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else if (trade.loss != null)
                                        Text(
                                          '-\$${trade.loss!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trade: \$${trade.tradeBalance.toStringAsFixed(2)} | Reserve: \$${trade.reserveBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (trade.transferredFromReserve != null && trade.transferredFromReserve! > 0)
                                    Text(
                                      '↑ Restored trade balance: +\$${trade.transferredFromReserve!.toStringAsFixed(2)} from reserve',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  if (trade.wasRebalanced)
                                    Text(
                                      '↺ Rebalanced to 40/60 split',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 13,
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