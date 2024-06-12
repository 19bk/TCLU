import ccxt
import pandas as pd
import ta

def get_ohlcv(exchange, symbol, timeframe):
    ohlcv = exchange.fetch_ohlcv(symbol, timeframe)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    return df

def calculate_trend(data):
    data['sma50'] = ta.trend.sma_indicator(data['close'], window=50)
    data['sma200'] = ta.trend.sma_indicator(data['close'], window=200)
    
    if data['close'].iloc[-1] > data['sma50'].iloc[-1] > data['sma200'].iloc[-1]:
        return "Bullish"
    elif data['close'].iloc[-1] < data['sma50'].iloc[-1] < data['sma200'].iloc[-1]:
        return "Bearish"
    else:
        return "Sideways"

def main():
    exchange = ccxt.mexc()
    symbol = 'BTC/USDT'
    
    timeframes = ['1m', '5m', '15m', '1h']

    trends = {}
    for timeframe in timeframes:
        data = get_ohlcv(exchange, symbol, timeframe)
        trend = calculate_trend(data)
        trends[timeframe] = trend

    for timeframe, trend in trends.items():
        print(f'Timeframe: {timeframe}, Trend: {trend}')

if __name__ == "__main__":
    main()
