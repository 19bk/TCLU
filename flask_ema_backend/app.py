from flask import Flask, jsonify
import ccxt
import pandas as pd
import numpy as np
from apscheduler.schedulers.background import BackgroundScheduler
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Global variables to store the latest results
latest_results = {}

def fetch_crypto_data(exchange, symbol, timeframe, limit):
    try:
        ohlcv = exchange.fetch_ohlcv(symbol, timeframe, limit=limit)
        df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
        df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
        return df
    except Exception as e:
        logging.error(f"Error fetching data for {symbol} on {timeframe}: {str(e)}")
        return None

def calculate_ema(data, period, column='close'):
    return data[column].ewm(span=period, adjust=False).mean()

def calculate_rsi(data, period=14, column='close'):
    delta = data[column].diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
    
    rs = gain / loss
    rsi = 100 - (100 / (1 + rs))
    return rsi

def calculate_indicators(df):
    if len(df) < 200:
        logging.warning(f"Not enough data points for EMA calculation. Got {len(df)}, need at least 200.")
        return None

    df['EMA_20'] = calculate_ema(df, 20)
    df['EMA_50'] = calculate_ema(df, 50)
    df['EMA_200'] = calculate_ema(df, 200)
    df['RSI'] = calculate_rsi(df)
    return df

def determine_trend(df):
    if df is None or df.empty:
        return 'Insufficient Data'

    last_row = df.iloc[-1]
    
    # EMA trend
    ema_trend = (
        'Bullish' if last_row['EMA_20'] > last_row['EMA_50'] > last_row['EMA_200'] 
        else 'Bearish' if last_row['EMA_20'] < last_row['EMA_50'] < last_row['EMA_200'] 
        else 'Neutral'
    )
    
    # RSI trend
    rsi_trend = (
        'Overbought' if last_row['RSI'] > 70 
        else 'Oversold' if last_row['RSI'] < 30 
        else 'Neutral'
    )

    # Price vs EMA
    price_vs_ema = (
        'Above' if last_row['close'] > last_row['EMA_20'] 
        else 'Below'
    )

    # Combine trends
    if ema_trend == 'Bullish' and price_vs_ema == 'Above':
        return 'Strong Bullish'
    elif ema_trend == 'Bearish' and price_vs_ema == 'Below':
        return 'Strong Bearish'
    elif ema_trend == 'Bullish' or (ema_trend == 'Neutral' and price_vs_ema == 'Above'):
        return 'Moderately Bullish'
    elif ema_trend == 'Bearish' or (ema_trend == 'Neutral' and price_vs_ema == 'Below'):
        return 'Moderately Bearish'
    else:
        return 'Neutral'

def analyze_pair(exchange, symbol, timeframes):
    results = {}
    for timeframe in timeframes:
        limit = 300  # Fetch enough data for 200 EMA
        df = fetch_crypto_data(exchange, symbol, timeframe, limit)
        if df is not None:
            df = calculate_indicators(df)
            trend = determine_trend(df)
            results[timeframe] = trend
        else:
            results[timeframe] = 'Data Fetch Error'
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
    
    logging.info("Trends updated successfully")

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

    # Run update_trends once immediately
    update_trends()

    app.run(host='0.0.0.0', port=5000)