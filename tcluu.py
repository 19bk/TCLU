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

def calculate_percentage_move(start_price, end_price):
    return ((end_price - start_price) / start_price) * 100

def identify_significant_moves(df, min_percent=2, max_percent=4):
    df['price_change'] = df['close'].pct_change()
    df['cumulative_change'] = df['price_change'].cumsum()
    
    significant_moves = []
    start_index = 0
    
    for i in range(1, len(df)):
        move = calculate_percentage_move(df['close'][start_index], df['close'][i])
        if abs(move) >= min_percent:
            if abs(move) <= max_percent:
                significant_moves.append((start_index, i, move))
            start_index = i
    
    return significant_moves

def identify_zigzag(df, threshold=1):
    zigzag_points = []
    last_extreme = df['close'].iloc[0]
    last_extreme_index = 0
    trend = 1  # 1 for uptrend, -1 for downtrend

    for i in range(1, len(df)):
        current_price = df['close'].iloc[i]
        move = calculate_percentage_move(last_extreme, current_price)

        if (trend == 1 and current_price < last_extreme) or (trend == -1 and current_price > last_extreme):
            if abs(move) >= threshold:
                zigzag_points.append((last_extreme_index, last_extreme))
                trend *= -1
                last_extreme = current_price
                last_extreme_index = i
        elif (trend == 1 and current_price > last_extreme) or (trend == -1 and current_price < last_extreme):
            last_extreme = current_price
            last_extreme_index = i

    zigzag_points.append((last_extreme_index, last_extreme))
    return zigzag_points

def analyze_pair(exchange, symbol, timeframes):
    results = {}
    for timeframe in timeframes:
        limit = 300  # Fetch enough data for 200 EMA
        df = fetch_crypto_data(exchange, symbol, timeframe, limit)
        df = calculate_ema(df, [20, 50, 200])
        trend = check_trend(df)
        
        significant_moves = identify_significant_moves(df)
        zigzag_points = identify_zigzag(df)
        
        results[timeframe] = {
            'trend': trend,
            'significant_moves': significant_moves,
            'zigzag_points': zigzag_points
        }
    return results

def check_alignment(pair, results):
    timeframes = ['1m', '5m', '15m', '1h']
    trends = [results[tf]['trend'] for tf in timeframes]
    
    # Check for trend alignment
    if all(trend == 'Bullish' for trend in trends) or all(trend == 'Bearish' for trend in trends):
        trend_type = 'Bullish' if trends[0] == 'Bullish' else 'Bearish'
        message = f"4/4 {trend_type} Match for {pair}: showing a 4/4 {trend_type} match across all timeframes!"
        print(message)
        send_email(f"4/4 {trend_type} Match for {pair}", message)
    elif trends[:3].count('Bullish') == 3:
        message = f"3/4 Bullish Match for {pair}: showing a 3/4 Bullish match (1m, 5m, 15m)!"
        print(message)
        send_email(f"3/4 Bullish Match for {pair}", message)
    elif trends[:3].count('Bearish') == 3:
        message = f"3/4 Bearish Match for {pair}: showing a 3/4 Bearish match (1m, 5m, 15m)!"
        print(message)
        send_email(f"3/4 Bearish Match for {pair}", message)
    
    # Check for significant moves with zig-zag pattern
    for tf in timeframes:
        moves = results[tf]['significant_moves']
        zigzags = results[tf]['zigzag_points']
        
        if moves and zigzags:
            last_move = moves[-1]
            if len(zigzags) >= 3:  # Ensure we have at least 3 points for a zig-zag
                message = f"Significant move detected for {pair} on {tf} timeframe: {last_move[2]:.2f}% with zig-zag pattern"
                print(message)
                send_email(f"Significant move for {pair} on {tf}", message)

def main():
    exchange = ccxt.mexc()
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
            row = [pair] + [pair_results[tf]['trend'] for tf in timeframes]
            results.append(row)
            check_alignment(pair, pair_results)
        
        headers = ['Pair'] + timeframes
        print(tabulate(results, headers=headers, tablefmt='grid'))
        
        time.sleep(300)  # Wait for 5 minutes before the next check

if __name__ == "__main__":
    main()