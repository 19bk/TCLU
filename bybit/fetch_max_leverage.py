import requests

# Bybit API endpoint for futures market info
URL = "https://api.bybit.com/v5/market/instruments-info?category=linear"

def get_max_leverage():
    try:
        # Send a request to the Bybit API to get symbols data
        response = requests.get(URL)
        response.raise_for_status()
        
        data = response.json()
        
        if data.get("retCode") != 0:
            print("Error fetching data from Bybit API:", data.get("retMsg"))
            return
        
        symbols = data.get("result", {}).get("list", [])
        leverage_info = []

        # Extract maximum leverage for each trading pair
        for symbol in symbols:
            trading_pair = symbol.get("symbol")
            max_leverage = symbol.get("leverageFilter", {}).get("maxLeverage", "N/A")
            leverage_info.append((trading_pair, max_leverage))
        
        # Display the results
        print(f"{'Trading Pair':<15} | {'Max Leverage':<10}")
        print("-" * 30)
        for pair, leverage in leverage_info:
            print(f"{pair:<15} | {leverage:<10}")
        
    except requests.exceptions.RequestException as e:
        print("An error occurred while fetching data:", e)

if __name__ == "__main__":
    get_max_leverage()
