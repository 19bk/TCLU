import ccxt
import pandas as pd
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from rich.console import Console
from rich.table import Table
from rich.text import Text

# Email credentials
EMAIL_ADDRESS = "onchainurchin@gmail.com"
EMAIL_PASSWORD = "bqjt ulmj nsgk drat"
RECIPIENT_EMAIL = "onchainurchin@gmail.com"

# Create a console instance
console = Console()

def send_email(subject, body, pair, combined_trend):
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
        
        # Add details about the email sent
        print(f"Email sent successfully for {pair}, where combined trend is {combined_trend}.")
        
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

def analyze_pair(exchange, symbol, timeframes):
    results = {}
    for timeframe in timeframes:
        limit = 300  # Fetch enough data for 200 EMA
        df = fetch_crypto_data(exchange, symbol, timeframe, limit)
        df = calculate_ema(df, [20, 50, 200])
        trend = check_trend(df)
        results[timeframe] = trend
    return results

def main():
    exchange = ccxt.mexc()
    pairs = [
        'ADA/USDT', 'APT/USDT', 'ATOM/USDT', 'AVAX/USDT', 'FTM/USDT',
        'LINK/USDT', 'LTC/USDT', 'SOL/USDT', 'BTC/USDT', 'MANA/USDT'
    ]
    timeframes = ['1m', '5m', '15m', '1h']  # Include 1h in the timeframes for display
    previous_alert_states = {pair: None for pair in pairs}  # Track previous alert states for each pair

    while True:  # Loop indefinitely
        for pair in pairs:
            pair_results = analyze_pair(exchange, pair, timeframes)
            
            # Check combined trend for alerts
            trends = [pair_results[tf] for tf in ['1m', '5m', '15m']]  # Only check these for alerts
            combined_trend = None
            
            if all(trend == 'Bullish' for trend in trends):
                combined_trend = 'Bullish'
            elif all(trend == 'Bearish' for trend in trends):
                combined_trend = 'Bearish'
            else:
                combined_trend = 'Neutral'  # If not all bullish or bearish

            # Send alert if the combined trend changes and is not neutral
            if combined_trend != 'Neutral' and combined_trend != previous_alert_states[pair]:
                # Get the 1-hour trend for additional information
                one_hour_trend = pair_results['1h']  # Assuming '1h' is included in pair_results

                subject = f"Trend Alert for {pair}"
                body = f"The trend for {pair} is now: {combined_trend} in 1m, 5m, and 15m timeframes.\n" \
                       f"1-hour trend status: {one_hour_trend}."
                send_email(subject, body, pair, combined_trend)  # Pass pair and combined_trend
                previous_alert_states[pair] = combined_trend  # Update the previous alert state

        # Create a rich table for results
        table = Table(title="Trend Analysis Results", style="bold green")
        table.add_column("Pair", style="cyan", no_wrap=True)
        for timeframe in timeframes:
            table.add_column(timeframe, justify="center")

        # Add rows to the table
        for pair in pairs:
            row = [pair] + [pair_results[tf] for tf in timeframes]
            table.add_row(*row)

        # Print the table
        console.print(table)

        # Color-coded output for trends
        for pair in pairs:
            combined_trend = previous_alert_states[pair]  # Get the latest trend for the pair
            if combined_trend is not None:  # Ensure combined_trend is not None
                if combined_trend == 'Bullish':
                    console.print(f"{pair}: {Text(combined_trend, style='bold green')}")
                elif combined_trend == 'Bearish':
                    console.print(f"{pair}: {Text(combined_trend, style='bold red')}")
                else:
                    console.print(f"{pair}: {Text(combined_trend, style='bold yellow')}")
            else:
                console.print(f"{pair}: {Text('No trend available', style='bold yellow')}")

if __name__ == "__main__":
    main()