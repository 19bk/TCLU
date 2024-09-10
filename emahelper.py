import ccxt
import pandas as pd
from tabulate import tabulate
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import time
import os

# Email configuration
EMAIL_ADDRESS = "onchainurchin@gmail.com"
EMAIL_PASSWORD = "bqjt ulmj nsgk drat"
RECIPIENT_EMAIL = "onchainurchin@gmail.com"

def send_email(subject, body):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = RECIPIENT_EMAIL
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    with smtplib.SMTP('smtp.gmail.com', 587) as server:
        server.starttls()
        server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        server.send_message(msg)

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

def check_alignment(pair, results):
    timeframes = ['1m', '5m', '15m', '1h']
    trends = [results.get(tf, 'Neutral') for tf in timeframes]
    
    if all(trend == 'Bullish' for trend in trends):
        message = f"4/4 Bullish Match for {pair}: showing a 4/4 Bullish match across all timeframes!"
        print(message)
        send_email(f"4/4 Bullish Match for {pair}", message)
    elif all(trend == 'Bearish' for trend in trends):
        message = f"4/4 Bearish Match for {pair}: showing a 4/4 Bearish match across all timeframes!"
        print(message)
        send_email(f"4/4 Bearish Match for {pair}", message)
    elif trends[:3].count('Bullish') == 3:
        message = f"3/4 Bullish Match for {pair}: showing a 3/4 Bullish match (1m, 5m, 15m)!"
        print(message)
        send_email(f"3/4 Bullish Match for {pair}", message)
    elif trends[:3].count('Bearish') == 3:
        message = f"3/4 Bearish Match for {pair}: showing a 3/4 Bearish match (1m, 5m, 15m)!"
        print(message)
        send_email(f"3/4 Bearish Match for {pair}", message)

def main():
    exchange = ccxt.mexc()
    
    # Print available markets for debugging
    markets = exchange.load_markets()
    print("Available markets:", markets.keys())
    
    pairs = [
        'ADA/USDT', 'APT/USDT', 'ATOM/USDT', 'AVAX/USDT', 'FTM/USDT',
        'LINK/USDT', 'LTC/USDT', 'MATIC/USDT', 'SOL/USDT', 'BTC/USDT', 'MANA/USDT'
    ]
    timeframes = ['1m', '5m', '15m', '1h']
    
    while True:
        os.system('cls' if os.name == 'nt' else 'clear')  # Clear console
        print(f"Analyzing pairs... {time.strftime('%Y-%m-%d %H:%M:%S')}")
        
        results = []
        for pair in pairs:
            pair_results = analyze_pair(exchange, pair, timeframes)
            row = [pair] + [pair_results[tf] for tf in timeframes]
            results.append(row)
            check_alignment(pair, pair_results)
        
        headers = ['Pair'] + timeframes
        print(tabulate(results, headers=headers, tablefmt='grid'))
        
        time.sleep(300)  # Wait for 5 minutes before the next check

if __name__ == "__main__":
    main()