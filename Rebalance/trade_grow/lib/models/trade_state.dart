class TradeState {
  double totalCapital;
  double tradeBalance;
  double reserveBalance;
  int tradesCount;
  List<TradeLog> tradeHistory;
  double peakCapital; // Track highest capital reached
  double baseTradeAmount; // The base amount we want to maintain for trading
  bool isRecovering = false; // Track if we're recovering from a loss

  static const double WIN_RATE = 0.95;
  static const double WIN_GAIN = 0.10;
  static const double LOSS_PERCENTAGE = 0.50;
  static const double TRADE_RATIO = 0.40;
  static const double RESERVE_RATIO = 0.60;

  TradeState({required double initialCapital})
      : totalCapital = initialCapital > 0 ? initialCapital : 1000.0,
        tradeBalance = (initialCapital > 0 ? initialCapital : 1000.0) * TRADE_RATIO,
        reserveBalance = (initialCapital > 0 ? initialCapital : 1000.0) * RESERVE_RATIO,
        tradesCount = 0,
        tradeHistory = [],
        peakCapital = initialCapital > 0 ? initialCapital : 1000.0,
        baseTradeAmount = (initialCapital > 0 ? initialCapital : 1000.0) * TRADE_RATIO;

  bool shouldRebalance() {
    // Rebalance if we're recovering and reached previous peak
    if (isRecovering && totalCapital >= peakCapital) {
      return true;
    }
    // Or if trade balance exceeds reserve
    if (tradeBalance >= reserveBalance) {
      return true;
    }
    return false;
  }

  void simulateWin() {
    try {
      double gain = tradeBalance * WIN_GAIN;
      if (gain.isNaN || gain.isInfinite) gain = 0;
      
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
          gain: gain,
        ),
      );

      if (shouldRebalance()) {
        rebalance();
        if (totalCapital >= peakCapital) {
          isRecovering = false; // Recovery complete
          peakCapital = totalCapital;
        }
      }
    } catch (e) {
      print('Error in simulateWin: $e');
    }
  }

  void simulateLoss() {
    try {
      // Calculate 50% loss of current trade balance
      double loss = tradeBalance * LOSS_PERCENTAGE;
      if (loss.isNaN || loss.isInfinite) loss = 0;
      
      // First apply the loss
      tradeBalance -= loss;
      totalCapital -= loss;
      
      // Calculate how much we need from reserve to restore trade balance
      double neededFromReserve = baseTradeAmount - tradeBalance;
      
      // Check if we have enough in reserve
      if (neededFromReserve > reserveBalance) {
        neededFromReserve = reserveBalance; // Take what we can
      }
      
      // Transfer from reserve to trade to maintain trading power
      if (neededFromReserve > 0 && reserveBalance >= neededFromReserve) {
        reserveBalance -= neededFromReserve;
        tradeBalance += neededFromReserve;
      }
      
      isRecovering = true; // Start recovery mode after loss
      tradesCount++;
      
      tradeHistory.add(
        TradeLog(
          isWin: false,
          tradeBalance: tradeBalance,
          reserveBalance: reserveBalance,
          totalCapital: totalCapital,
          wasRebalanced: false,
          transferredFromReserve: neededFromReserve,
          loss: loss,
        ),
      );
    } catch (e) {
      print('Error in simulateLoss: $e');
    }
  }

  void manualRebalance() {
    try {
      if (shouldRebalance()) {
        rebalance();
        if (totalCapital >= peakCapital) {
          isRecovering = false;
          peakCapital = totalCapital;
        }
      } else {
        if (isRecovering) {
          double remaining = peakCapital - totalCapital;
          print('Still recovering. Need \$${remaining.toStringAsFixed(2)} more to reach previous peak of \$${peakCapital.toStringAsFixed(2)}');
        } else {
          print('Can only rebalance when trade balance (\$${tradeBalance.toStringAsFixed(2)}) exceeds reserve (\$${reserveBalance.toStringAsFixed(2)})');
        }
      }
    } catch (e) {
      print('Error in manualRebalance: $e');
    }
  }

  void rebalance() {
    try {
      totalCapital = tradeBalance + reserveBalance;
      tradeBalance = totalCapital * TRADE_RATIO;
      reserveBalance = totalCapital * RESERVE_RATIO;
      baseTradeAmount = tradeBalance;
      
      if (tradeHistory.isNotEmpty) {
        tradeHistory.last.wasRebalanced = true;
        tradeHistory.last.tradeBalance = tradeBalance;
        tradeHistory.last.reserveBalance = reserveBalance;
      }
    } catch (e) {
      print('Error in rebalance: $e');
    }
  }
}

class TradeLog {
  final bool isWin;
  double tradeBalance;
  double reserveBalance;
  final double totalCapital;
  bool wasRebalanced;
  final double? transferredFromReserve;
  final double? gain;
  final double? loss;

  TradeLog({
    required this.isWin,
    required this.tradeBalance,
    required this.reserveBalance,
    required this.totalCapital,
    required this.wasRebalanced,
    this.transferredFromReserve,
    this.gain,
    this.loss,
  });
} 