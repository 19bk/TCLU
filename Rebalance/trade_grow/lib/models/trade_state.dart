class TradeState {
  double totalCapital;
  double tradeBalance;
  double reserveBalance;
  int tradesCount;
  List<TradeLog> tradeHistory;

  static const double WIN_RATE = 0.95;
  static const double WIN_GAIN = 0.10;
  static const double LOSS_PERCENTAGE = 0.50;
  static const double TRADE_RATIO = 0.40;
  static const double RESERVE_RATIO = 0.60;

  TradeState({required double initialCapital})
      : totalCapital = initialCapital,
        tradeBalance = initialCapital * TRADE_RATIO,
        reserveBalance = initialCapital * RESERVE_RATIO,
        tradesCount = 0,
        tradeHistory = [];

  void simulateWin() {
    double gain = tradeBalance * WIN_GAIN;
    tradeBalance += gain;
    totalCapital += gain;
    tradesCount++;
    tradeHistory.add(
      TradeLog(
        isWin: true,
        tradeBalance: tradeBalance,
        reserveBalance: reserveBalance,
        totalCapital: totalCapital,
        wasRebalanced: false,
      ),
    );
    checkAndRebalance();
  }

  void simulateLoss() {
    double loss = tradeBalance * LOSS_PERCENTAGE;
    tradeBalance -= loss;
    totalCapital -= loss;
    tradesCount++;
    tradeHistory.add(
      TradeLog(
        isWin: false,
        tradeBalance: tradeBalance,
        reserveBalance: reserveBalance,
        totalCapital: totalCapital,
        wasRebalanced: false,
      ),
    );
    checkAndRebalance();
  }

  void manualRebalance() {
    rebalance();
  }

  void checkAndRebalance() {
    if (tradeBalance >= reserveBalance) {
      rebalance();
    }
  }

  void rebalance() {
    totalCapital = tradeBalance + reserveBalance;
    tradeBalance = totalCapital * TRADE_RATIO;
    reserveBalance = totalCapital * RESERVE_RATIO;
    
    if (tradeHistory.isNotEmpty) {
      tradeHistory.last.wasRebalanced = true;
      tradeHistory.last.tradeBalance = tradeBalance;
      tradeHistory.last.reserveBalance = reserveBalance;
    }
  }
}

class TradeLog {
  final bool isWin;
  double tradeBalance;
  double reserveBalance;
  final double totalCapital;
  bool wasRebalanced;

  TradeLog({
    required this.isWin,
    required this.tradeBalance,
    required this.reserveBalance,
    required this.totalCapital,
    required this.wasRebalanced,
  });
} 