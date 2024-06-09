import ccxt
import pandas as pd
import numpy as np

def get_ohlcv(exchange, symbol, timeframe):
    ohlcv = exchange.fetch_ohlcv(symbol, timeframe)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    return df

def calculate_sma(data, window):
    return data['close'].rolling(window=window).mean()

def determine_trend(data):
    sma = calculate_sma(data, window=14)
    current_price = data['close'].iloc[-1]
    current_sma = sma.iloc[-1]

    if current_price > current_sma:
        return "Bullish"
    else:
        return "Bearish"

def main():
    exchange = ccxt.binance()
    symbol = 'BTC/USDT'
    timeframes = ['1m', '5m', '15m', '1h']

    trends = {}
    for timeframe in timeframes:
        data = get_ohlcv(exchange, symbol, timeframe)
        trend = determine_trend(data)
        trends[timeframe] = trend

    for timeframe, trend in trends.items():
        print(f'Timeframe: {timeframe}, Trend: {trend}')

if __name__ == "__main__":
    main()
