import ccxt
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def fetch_bitcoin_data(exchange, symbol, timeframe, limit):
    ohlcv = exchange.fetch_ohlcv(symbol, timeframe, limit=limit)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    return df

def detect_price_movement(df, threshold):
    df['price_change'] = df['close'].pct_change()
    df['cumulative_change'] = (1 + df['price_change']).cumprod() - 1
    df['movement'] = np.where(abs(df['cumulative_change']) >= threshold, 1, 0)
    return df

def detect_zigzag(df, column='close'):
    df['direction'] = np.where(df[column] > df[column].shift(1), 1, 
                               np.where(df[column] < df[column].shift(1), -1, 0))
    df['zigzag'] = ((df['direction'] != df['direction'].shift(1)) & 
                    (df['direction'] != 0)).astype(int)
    return df

def main():
    exchange = ccxt.binance()
    symbol = 'BTC/USDT'
    timeframe = '1m'
    limit = 1000  # Fetch last 1000 minutes of data
    threshold = 0.02  # 2% threshold

    # Fetch data
    df = fetch_bitcoin_data(exchange, symbol, timeframe, limit)

    # Detect price movements
    df = detect_price_movement(df, threshold)

    # Detect zigzag pattern
    df = detect_zigzag(df)

    # Find significant movements with zigzag pattern
    significant_moves = df[(df['movement'] == 1) & (df['zigzag'] == 1)]

    print(f"Detected {len(significant_moves)} significant price movements with zigzag pattern:")
    for idx, row in significant_moves.iterrows():
        print(f"Time: {row['timestamp']}, Close: {row['close']}, Cumulative Change: {row['cumulative_change']:.2%}")

if __name__ == "__main__":
    main()