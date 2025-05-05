import 'package:flutter/material.dart';
import '../models/trade_state.dart';

class TradeLogWidget extends StatelessWidget {
  final List<TradeLog> tradeHistory;
  final bool showTitle;

  const TradeLogWidget({
    super.key,
    required this.tradeHistory,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            'Trade Log',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
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
                  padding: EdgeInsets.zero,
                  itemCount: tradeHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (context, index) {
                    final trade = tradeHistory[index];
                    final tradeNumber = index + 1;
                    final mutedGreen = Colors.green[400];
                    final mutedRed = Colors.red[400];
                    final isWin = trade.gain != null && trade.gain! > 0;
                    final isLoss = trade.loss != null && trade.loss! > 0;
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
                                    if (isWin)
                                      Text(
                                        '+\$${trade.gain!.round()}',
                                        style: TextStyle(
                                          color: mutedGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      )
                                    else if (isLoss)
                                      Text(
                                        '-\$${trade.loss!.round()}',
                                        style: TextStyle(
                                          color: mutedRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Trade: \$${trade.tradeBalance.round()} | Reserve: \$${trade.reserveBalance.round()}',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (trade.transferredFromReserve != null && trade.transferredFromReserve! > 0)
                                  Text(
                                    'Restored trade balance: +\$${trade.transferredFromReserve!.round()} from reserve',
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
      ],
    );
  }
} 