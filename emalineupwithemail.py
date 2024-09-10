import ccxt
import pandas as pd
from tabulate import tabulate
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Email credentials
EMAIL_ADDRESS = "onchainurchin@gmail.com"
EMAIL_PASSWORD = "bqjt ulmj nsgk drat"
RECIPIENT_EMAIL = "onchainurchin@gmail.com"

def send_email(subject, body):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = RECIPIENT_EMAIL
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()  # Secure the connection
        server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        server.sendmail(EMAIL_ADDRESS, RECIPIENT_EMAIL, msg.as_string())
        print("Email sent successfully")
    except Exception as e:
        print(f"Failed to send email: {e}")
    finally:
        server.quit()

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

def analyze_pair(exchange, symbol, timeframes, previous_states):
    results = {}
    for timeframe in timeframes:
        limit = 300  # Fetch enough data for 200 EMA
        df = fetch_crypto_data(exchange, symbol, timeframe, limit)
        df = calculate_ema(df, [20, 50, 200])
        trend = check_trend(df)
        results[timeframe] = trend
        
        # Check for state change and send email if necessary
        if trend != previous_states[timeframe]:
            subject = f"Trend Change for {symbol} - {timeframe}"
            body = f"The trend for {symbol} in {timeframe} timeframe is now: {trend}"
            send_email(subject, body)
            previous_states[timeframe] = trend  # Update the previous state
    return results

def main():
    exchange = ccxt.binance()
    pairs = [
        'ADA/USDT', 'APT/USDT', 'ATOM/USDT', 'AVAX/USDT', 'FTM/USDT',
        'LINK/USDT', 'LTC/USDT', 'MATIC/USDT', 'SOL/USDT', 'BTC/USDT', 'MANA/USDT'
    ]
    timeframes = ['1m', '5m', '15m', '1h']
    
    previous_states = {pair: {tf: 'Neutral' for tf in timeframes} for pair in pairs}
    
    results = []
    for pair in pairs:
        pair_results = analyze_pair(exchange, pair, timeframes, previous_states[pair])
        row = [pair] + [pair_results[tf] for tf in timeframes]
        results.append(row)
    
    headers = ['Pair'] + timeframes
    print(tabulate(results, headers=headers, tablefmt='grid'))

if __name__ == "__main__":
    main()