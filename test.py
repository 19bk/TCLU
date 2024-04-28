from pybit.unified_trading import HTTP
import time

# Set API key and secret
api_key = "UAD2faj813tVHtu5n4"
api_secret = "Nj7IlRSXPW3drJno53KzKzt8X2s3zi64Nbj8"

# Function to get open positions for a specific settle coin ("USDT")
def get_open_positions():
    session = HTTP(
        testnet=True,
        api_key=api_key,
        api_secret=api_secret,
    )

    response = session.get_positions(category="linear", settleCoin="USDT")
    if response["retCode"] == 0:
        return response["result"]["list"]
    else:
        print("Failed to get open positions.")
        print("Error message:", response["retMsg"])
        return []

# Function to cancel all orders for a symbol
def cancel_orders(symbol):
    session = HTTP(
        testnet=True,
        api_key=api_key,
        api_secret=api_secret,
    )

    response = session.cancel_all_orders(category="linear", symbol=symbol)
    if response["retCode"] == 0:
        print(f"All orders for {symbol} canceled successfully.")
    else:
        print(f"Failed to cancel orders for {symbol}.")
        print("Error message:", response["retMsg"])

# Function to continuously monitor open positions and cancel orders
def continuous_monitoring(interval_seconds):
    previous_positions = set()

    while True:
        current_positions = set(position["symbol"] for position in get_open_positions())
        print(f"Current open positions: {current_positions}")

        # Find positions that no longer exist
        closed_positions = previous_positions - current_positions

        # Cancel orders for closed positions
        for symbol in closed_positions:
            cancel_orders(symbol)

        previous_positions = current_positions
        time.sleep(interval_seconds)

# Start continuous monitoring
continuous_monitoring(0.25)  # Check every 60 seconds (adjust interval as needed)


