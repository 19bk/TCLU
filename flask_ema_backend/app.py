from flask import Flask, jsonify
import ccxt
import pandas as pd
from apscheduler.schedulers.background import BackgroundScheduler

app = Flask(__name__)

# Global variables to store the latest results
latest_results = {}

def fetch_crypto_data(exchange, symbol, timeframe, limit):
    ohlcv = exchange.fetch_ohlcv(symbol, timeframe, limit=limit)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    return df

def calculate_ema(df, periods):
    for period in periods:
        df[f'EMA_{period}'] = df['close'].ewm(span=period, adjust=False).mean()
    return df

def check_trend(df):
    bullish = (df['EMA_20'] > df['EMA_50']) & (df['EMA_50'] > df['EMA_200']) & (df['close'] > df['EMA_20'])
    bearish = (df['EMA_20'] < df['EMA_50']) & (df['EMA_50'] < df['EMA_200']) & (df['close'] < df['EMA_20'])
    
    if bullish.iloc[-1]:
        return 'Bullish'
    elif bearish.iloc[-1]:
        return 'Bearish'
    else:
        return 'Neutral'

def analyze_pair(exchange, symbol, timeframes):
    results = {}
    for timeframe in timeframes:
        limit = 300  # Fetch enough data for 200 EMA
        df = fetch_crypto_data(exchange, symbol, timeframe, limit)
        df = calculate_ema(df, [20, 50, 200])
        trend = check_trend(df)
        results[timeframe] = trend
    return results

def update_trends():
    global latest_results
    exchange = ccxt.mexc()
    pairs = [
        'ADA/USDT', 'APT/USDT', 'ATOM/USDT', 'AVAX/USDT', 'FTM/USDT',
        'LINK/USDT', 'LTC/USDT', 'SOL/USDT', 'BTC/USDT', 'MANA/USDT'
    ]
    timeframes = ['1m', '5m', '15m', '1h']

    for pair in pairs:
        pair_results = analyze_pair(exchange, pair, timeframes)
        latest_results[pair] = pair_results

@app.route('/trends', methods=['GET'])
def get_trends():
    return jsonify(latest_results)

@app.route('/trend/<pair>', methods=['GET'])
def get_pair_trend(pair):
    if pair in latest_results:
        return jsonify(latest_results[pair])
    else:
        return jsonify({"error": "Pair not found"}), 404

if __name__ == "__main__":
    scheduler = BackgroundScheduler()
    scheduler.add_job(func=update_trends, trigger="interval", minutes=5)
    scheduler.start()

    app.run(host='0.0.0.0', port=5000)