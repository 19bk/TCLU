import ccxt
import pandas as pd
import numpy as np
import time
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from tabulate import tabulate

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

def fetch_data(exchange, symbol, timeframe, limit=1000):
    ohlcv = exchange.fetch_ohlcv(symbol, timeframe, limit=limit)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    return df

def calculate_ema(df, periods):
    for period in periods:
        df[f'EMA_{period}'] = df['close'].ewm(span=period, adjust=False).mean()
    return df

def detect_zigzag(df, deviation=5):
    pivot_points = []
    direction = 1
    last_pivot = df['close'].iloc[0]
    last_pivot_index = 0
    for i in range(1, len(df)):
        close = df['close'].iloc[i]
        if (direction == 1 and close < last_pivot * (1 - deviation / 100)) or \
           (direction == -1 and close > last_pivot * (1 + deviation / 100)):
            percent_move = (close - last_pivot) / last_pivot * 100
            candles_between = i - last_pivot_index
            time_range = (df['timestamp'].iloc[i] - df['timestamp'].iloc[last_pivot_index]).total_seconds() / 60  # in minutes
            pivot_points.append((i, close, direction, percent_move, candles_between, time_range))
            direction *= -1
            last_pivot = close
            last_pivot_index = i
        elif (direction == 1 and close > last_pivot) or (direction == -1 and close < last_pivot):
            last_pivot = close
            last_pivot_index = i
    return pivot_points

def check_ema_alignment(df):
    last_row = df.iloc[-1]
    if last_row['EMA_20'] > last_row['EMA_50'] > last_row['EMA_200']:
        return 'Bullish'
    elif last_row['EMA_20'] < last_row['EMA_50'] < last_row['EMA_200']:
        return 'Bearish'
    else:
        return 'Neutral'

def analyze_pair(exchange, symbol, timeframes):
    results = {}
    for tf in timeframes:
        df = fetch_data(exchange, symbol, tf)
        df = calculate_ema(df, [20, 50, 200])
        
        zigzag = detect_zigzag(df)
        ema_alignment = check_ema_alignment(df)
        
        results[tf] = {
            'zigzag': zigzag,
            'ema_alignment': ema_alignment,
            'df': df
        }
    
    return results

def calculate_move_info(df, start_index, end_index):
    start_price = df['close'].iloc[start_index]
    end_price = df['close'].iloc[end_index]
    move_percent = (end_price - start_price) / start_price * 100
    direction = "Uptrend" if end_price > start_price else "Downtrend"
    start_time = df['timestamp'].iloc[start_index]
    end_time = df['timestamp'].iloc[end_index]
    candle_range = df['high'].iloc[start_index:end_index+1].max() - df['low'].iloc[start_index:end_index+1].min()
    number_of_bars = end_index - start_index + 1
    
    return {
        "move_percent": move_percent,
        "direction": direction,
        "start_time": start_time,
        "end_time": end_time,
        "candle_range": candle_range,
        "number_of_bars": number_of_bars
    }
def main():
    exchange = ccxt.mexc()
    pairs = [
        'ADA/USDT', 'APT/USDT', 'ATOM/USDT', 'AVAX/USDT', 'FTM/USDT',
        'LINK/USDT', 'LTC/USDT', 'MATIC/USDT', 'SOL/USDT', 'BTC/USDT', 'MANA/USDT'
    ]
    timeframes = ['1m', '5m', '15m', '1h']
    
    while True:
        print(f"Analyzing pairs... {time.strftime('%Y-%m-%d %H:%M:%S')}")
        
        alerts = []
        ema_table = []
        
        for pair in pairs:
            try:
                pair_results = analyze_pair(exchange, pair, timeframes)
                
                ema_row = [pair]
                zigzag_alert = False
                ema_alert = True
                
                for tf in timeframes:
                    result = pair_results[tf]
                    ema_row.append(result['ema_alignment'])
                    
                    if tf == '1m' and len(result['zigzag']) >= 5:  # At least 3 peaks and 2 troughs
                        zigzag_alert = True
                    
                    if result['ema_alignment'] == 'Neutral':
                        ema_alert = False
                
                ema_table.append(ema_row)
                
                if zigzag_alert and ema_alert:
                    zigzag_points = pair_results['1m']['zigzag'][-5:]
                    df = pair_results['1m']['df']
                    if zigzag_points:
                        move_info = calculate_move_info(df, zigzag_points[0][0], zigzag_points[-1][0])
                        
                        alerts.append({
                            'symbol': pair,
                            'zigzag': zigzag_points,
                            'ema_alignment': ema_row[1:],
                            'move_info': move_info
                        })
            except Exception as e:
                print(f"Error analyzing {pair}: {str(e)}")
        
        if alerts:
            message = "Alerts detected:\n\n"
            for alert in alerts:
                message += f"Significant move detected for {alert['symbol']} on 1m timeframe:\n"
                message += f"  Move: {alert['move_info']['move_percent']:.2f}%\n"
                message += f"  Direction: {alert['move_info']['direction']}\n"
                message += f"  Time range: {alert['move_info']['start_time'].strftime('%Y-%m-%d %H:%M:%S')} to {alert['move_info']['end_time'].strftime('%Y-%m-%d %H:%M:%S')}\n"
                message += f"  Candle range: {alert['move_info']['candle_range']:.6f}\n"
                message += f"  Number of bars: {alert['move_info']['number_of_bars']}\n"
                message += "-" * 50 + "\n"
                
                message += f"Detailed Zigzag points:\n"
                for i, point in enumerate(alert['zigzag']):
                    if i > 0:
                        message += f"  Time: {alert['move_info']['df']['timestamp'].iloc[point[0]].strftime('%Y-%m-%d %H:%M:%S')}, Price: {point[1]:.8f}, Direction: {'Up' if point[2] == 1 else 'Down'}\n"
                        message += f"  Percent Move: {point[3]:.2f}%, Candles Between: {point[4]}, Time Range: {point[5]:.1f} minutes\n"
                    else:
                        message += f"  Start Point - Time: {alert['move_info']['df']['timestamp'].iloc[point[0]].strftime('%Y-%m-%d %H:%M:%S')}, Price: {point[1]:.8f}\n"
                message += f"EMA Alignments: {', '.join(alert['ema_alignment'])}\n"
                message += "=" * 50 + "\n"
            
            message += "\nEMA Alignment Table:\n"
            headers = ["Symbol"] + timeframes
            message += tabulate(ema_table, headers=headers, tablefmt="grid")
            
            print(message)
            send_email("Crypto Market Alerts", message)
        else:
            print("No alerts detected.")
        
        time.sleep(60)  # Wait for 1 minute before the next check

if __name__ == "__main__":
    main()