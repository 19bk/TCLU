import ccxt
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import pytz
import plotly.graph_objects as go
from plotly.subplots import make_subplots

def fetch_ohlcv_data(exchange, symbol, timeframe, since):
    ohlcv = exchange.fetch_ohlcv(symbol, timeframe, since)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms', utc=True).dt.tz_convert('Africa/Nairobi')
    return df

def find_price_move(df, min_move=0.017, max_move=0.025):
    for i in range(len(df) - 1, 0, -1):
        price_move = (df['close'].iloc[-1] / df['close'].iloc[i]) - 1
        if min_move <= abs(price_move) <= max_move:
            return i, price_move
    return None, None

def detect_zigzag(df, start_index, min_swing=0.003):
    window = df.iloc[start_index:]
    highs = window['high'].values
    lows = window['low'].values
    
    zigzag_points = []
    last_extreme = 0
    direction = 1 if window['close'].iloc[-1] > window['close'].iloc[0] else -1
    
    for i in range(1, len(window)):
        if direction == 1:
            if highs[i] > highs[last_extreme]:
                last_extreme = i
            elif (highs[last_extreme] / lows[i] - 1) >= min_swing:
                zigzag_points.append((start_index + last_extreme, highs[last_extreme]))
                last_extreme = i
                direction = -1
        else:
            if lows[i] < lows[last_extreme]:
                last_extreme = i
            elif (highs[i] / lows[last_extreme] - 1) >= min_swing:
                zigzag_points.append((start_index + last_extreme, lows[last_extreme]))
                last_extreme = i
                direction = 1

    # Add the last point
    zigzag_points.append((len(df) - 1, window['close'].iloc[-1]))
    
    return zigzag_points

def plot_zigzag_plotly(df, start_index, zigzag_points, symbol):
    fig = make_subplots(rows=2, cols=1, shared_xaxes=True, 
                        vertical_spacing=0.03, row_heights=[0.7, 0.3])

    # Candlestick chart
    fig.add_trace(go.Candlestick(x=df['timestamp'],
                                 open=df['open'],
                                 high=df['high'],
                                 low=df['low'],
                                 close=df['close'],
                                 name='Price'),
                  row=1, col=1)

    # Highlight the price move range
    fig.add_vrect(x0=df['timestamp'].iloc[start_index], x1=df['timestamp'].iloc[-1],
                  fillcolor="LightSalmon", opacity=0.5, layer="below", line_width=0)

    # Zig-zag pattern
    if zigzag_points:
        x = [df['timestamp'].iloc[i] for i, _ in zigzag_points]
        y = [price for _, price in zigzag_points]
        fig.add_trace(go.Scatter(x=x, y=y,
                                 mode='lines+markers',
                                 line=dict(color='blue', width=2),
                                 name='Zig-Zag'),
                      row=1, col=1)

    # Volume chart
    fig.add_trace(go.Bar(x=df['timestamp'], y=df['volume'], name='Volume'),
                  row=2, col=1)

    # Update layout
    fig.update_layout(title=f'Trend-Aligned Zig-Zag Pattern Detection for {symbol} (1-Minute Timeframe, EAT)',
                      xaxis_rangeslider_visible=False,
                      height=800, width=1200)

    fig.show()

def analyze_symbol(exchange, symbol, timeframe, lookback_hours, min_move, max_move, min_swing):
    eat = pytz.timezone('Africa/Nairobi')
    now = datetime.now(eat)
    since = int((now - timedelta(hours=lookback_hours)).timestamp() * 1000)
    
    print(f"\nAnalyzing {symbol} on {timeframe} timeframe for the last {lookback_hours} hours")
    print(f"Looking for price moves between {min_move*100:.1f}% and {max_move*100:.1f}%")
    
    try:
        df = fetch_ohlcv_data(exchange, symbol, timeframe, since)
        print(f"Fetched {len(df)} data points.")
        
        start_index, price_move = find_price_move(df, min_move, max_move)
        
        if start_index is None:
            print("No suitable price move found within the specified range.")
            return
        
        print(f"\nIdentified price move:")
        print(f"  Start: {df['timestamp'].iloc[start_index]}")
        print(f"  End: {df['timestamp'].iloc[-1]}")
        print(f"  Move: {price_move*100:.2f}%")
        
        zigzag_points = detect_zigzag(df, start_index, min_swing)
        
        if len(zigzag_points) < 3:
            print("No significant zig-zag pattern detected within the price move.")
            return
        
        print(f"\nDetected zig-zag pattern within the price move:")
        print(f"  Number of zig-zag points: {len(zigzag_points)}")
        
        for i, (idx, price) in enumerate(zigzag_points, 1):
            point_type = "Trough" if i % 2 == 0 else "Crest"
            print(f"    Point {i} ({point_type}): {df['timestamp'].iloc[idx]}, Price: {price:.4f}")
        
        plot_zigzag_plotly(df, start_index, zigzag_points, symbol)
        
    except Exception as e:
        print(f"Error analyzing {symbol}: {str(e)}")

def main():
    exchange = ccxt.mexc()
    symbols = [
        'ADA/USDT:USDT', 'APT/USDT:USDT', 'ATOM/USDT:USDT', 'AVAX/USDT:USDT', 'FTM/USDT:USDT',
        'LINK/USDT:USDT', 'LTC/USDT:USDT', 'SOL/USDT:USDT', 'BTC/USDT:USDT', 'MANA/USDT:USDT'
    ]
    timeframe = '1m'
    lookback_hours = 24
    min_move = 0.017  # 1.7% minimum move
    max_move = 0.025  # 2.5% maximum move
    min_swing = 0.003  # 0.3% minimum swing for zig-zag
    
    eat = pytz.timezone('Africa/Nairobi')
    now = datetime.now(eat)
    print(f"Analysis start time (EAT): {now}")
    
    for symbol in symbols:
        analyze_symbol(exchange, symbol, timeframe, lookback_hours, min_move, max_move, min_swing)
        print("\n" + "="*50)

if __name__ == "__main__":
    main()