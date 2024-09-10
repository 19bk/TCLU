import ccxt

def get_mexc_symbols():
    # Create an instance of the MEXC exchange
    exchange = ccxt.mexc()

    # Load markets from the exchange
    markets = exchange.load_markets()

    # Extract and print all trading symbols
    symbols = list(markets.keys())
    print("Available MEXC Trading Symbols:")
    for symbol in symbols:
        print(symbol)

if __name__ == "__main__":
    get_mexc_symbols()