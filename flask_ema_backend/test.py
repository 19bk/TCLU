from flask import Flask, jsonify
import ccxt
import pandas as pd
import logging
from apscheduler.schedulers.background import BackgroundScheduler
import ta  # Import the ta library

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

def calculate_indicators(df):
    if len(df) < 200:
        logging.warning(f"Not enough data points for indicator calculation. Got {len(df)}, need at least 200.")
        return None

    # Calculate EMA using ta library
    df['EMA_20'] = ta.trend.EMAIndicator(df['close'], window=20).ema_indicator()
    df['EMA_50'] = ta.trend.EMAIndicator(df['close'], window=50).ema_indicator()
    df['EMA_200'] = ta.trend.EMAIndicator(df['close'], window=200).ema_indicator()

    # Calculate RSI using ta library
    df['RSI'] = ta.momentum.RSIIndicator(df['close'], window=14).rsi()

    return df

def determine_trend(df):
    if df is None or df.empty:
        return 'Insufficient Data'

    last_row = df.iloc[-1]
    
    # EMA trend
    ema_trend = (
        'Bullish' if last_row['EMA_20'] > last_row['EMA_50'] > last_row['EMA_200'] 
        else 'Bearish' if last_row['EMA_20'] < last_row['EMA_50'] < last_row['EMA_200'] 
        else 'Neutral'  # Ignore neutral EMA trends
    )
    
    # Price vs EMA
    price_vs_ema = 'Bullish' if last_row['close'] > last_row['EMA_20'] else 'Bearish'
    
    # Determine the overall trend by prioritizing EMA trend, else fallback to price vs EMA
    if ema_trend:
        return ema_trend
    else:
        return price_vs_ema


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

    app.run(host='0.0.0.0', port=5001)
