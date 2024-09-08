import ccxt
import pandas as pd
import time

def fetch_crypto_data(exchange, symbol, timeframe, limit):
    ohlcv = exchange.fetch_ohlcv(symbol, timeframe, limit=limit)
    df = pd.DataFrame(ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
    return df

def calculate_percentage_move(start_price, end_price):
    return ((end_price - start_price) / start_price) * 100

def identify_significant_moves(df, min_percent=2, max_percent=4):
    significant_moves = []
    start_index = 0
    
    for i in range(1, len(df)):
        move = calculate_percentage_move(df['close'].iloc[start_index], df['close'].iloc[i])
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
                direction = "Uptrend" if trend == 1 else "Downtrend"
                zigzag_points.append((last_extreme_index, i, last_extreme, current_price, direction))
                trend *= -1
                last_extreme = current_price
                last_extreme_index = i
        elif (trend == 1 and current_price > last_extreme) or (trend == -1 and current_price < last_extreme):
            last_extreme = current_price
            last_extreme_index = i

    return zigzag_points

def analyze_pair(exchange, symbol, timeframes):
    results = {}
    for timeframe in timeframes:
        limit = 300  # Fetch enough data
        df = fetch_crypto_data(exchange, symbol, timeframe, limit)
        
        significant_moves = identify_significant_moves(df)
        zigzag_points = identify_zigzag(df)
        
        results[timeframe] = {
            'significant_moves': significant_moves,
            'zigzag_points': zigzag_points,
            'df': df
        }
    return results

def check_alignment(pair, results):
    timeframes = ['1m', '5m', '15m', '1h']
    
    for tf in timeframes:
        moves = results[tf]['significant_moves']
        zigzags = results[tf]['zigzag_points']
        df = results[tf]['df']
        
        if moves and zigzags:
            last_move = moves[-1]
            last_zigzag = zigzags[-1]
            
            if len(zigzags) >= 3:  # Ensure we have at least 3 points for a zig-zag
                move_start_time = df['timestamp'].iloc[last_move[0]]
                move_end_time = df['timestamp'].iloc[last_move[1]]
                
                # Calculate 1-minute candle range
                one_min_range = df['high'].iloc[last_move[0]:last_move[1]+1].max() - df['low'].iloc[last_move[0]:last_move[1]+1].min()
                
                # Count the number of bars
                bar_count = last_move[1] - last_move[0] + 1
                
                message = (f"Significant move detected for {pair} on {tf} timeframe:\n"
                           f"  Move: {last_move[2]:.2f}%\n"
                           f"  Direction: {last_zigzag[4]}\n"
                           f"  Time range: {move_start_time} to {move_end_time}\n"
                           f"  1-min candle range: {one_min_range:.6f}\n"
                           f"  Number of bars: {bar_count}")
                print(message)
                print("-" * 50)

def main():
    exchange = ccxt.mexc()
    pairs = [
        'ADA/USDT', 'APT/USDT', 'ATOM/USDT', 'AVAX/USDT', 'FTM/USDT',
        'LINK/USDT', 'LTC/USDT', 'MATIC/USDT', 'SOL/USDT', 'BTC/USDT', 'MANA/USDT'
    ]
    timeframes = ['1m', '5m', '15m', '1h']
    
    while True:
        print(f"Analyzing pairs... {time.strftime('%Y-%m-%d %H:%M:%S')}")
        
        for pair in pairs:
            pair_results = analyze_pair(exchange, pair, timeframes)
            check_alignment(pair, pair_results)
        
        time.sleep(300)  # Wait for 5 minutes before the next check

if __name__ == "__main__":
    main()