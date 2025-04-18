from pybit.unified_trading import HTTP
import time
import concurrent.futures
from tabulate import tabulate
from pybit.exceptions import FailedRequestError


# Set API keys and secrets
apis = [
    {
        "name": "Testnet",
        "api_key": "UAD2faj813tVHtu5n4",
        "api_secret": "Nj7IlRSXPW3drJno53KzKzt8X2s3zi64Nbj8",
        "testnet": True,
    },
    {
        "name": "MAIN1",
        "api_key": "d2PdeMd88jrONugpE7",
        "api_secret": "lem9OCVuggIMnN8gTna94FV2a9RWune4Z588",
        "testnet": False,
    }, 
    {
        "name": "TCLU1",
        "api_key": "LkBKjLHEoRwQTXwj7z",
        "api_secret": "PIyBgeezw5IemGmCLJzg0S4KK39aXKI2RXsY",
        "testnet": False,
    },
    {
        "name": "TCLU2",
        "api_key": "mqQhoJyyYk1jaSxDhX",
        "api_secret": "Y8kqfcWpeNSfFaNVHwgv7A67Q86EchDWYINs",
        "testnet": False,
    },
    {
        "name": "TCLU3",
        "api_key": "nypN6qzzCvlV7nfrZv",
        "api_secret": "jypO1FjqTMusEMCXMjYb3w4mZJLINSYqVgoL",
        "testnet": False,
    },
]

# Function to get open positions for a specific settle coin ("USDT")
def get_open_positions(api):
    session = HTTP(
        testnet=api["testnet"],
        api_key=api["api_key"],
        api_secret=api["api_secret"],
    )

    backoff_factor = 0.1  # Initial backoff time in seconds
    max_retries = 5       # Maximum number of retries

    for _ in range(max_retries):
        try:
            response = session.get_positions(category="linear", settleCoin="USDT")
            if response["retCode"] == 0:
                return [position["symbol"] for position in response["result"]["list"]]
            else:
                print("Failed to get open positions.")
                print("Error message:", response["retMsg"])
                return []
        except FailedRequestError as e:
            print(f"Failed request: {e}. Retrying in {backoff_factor} seconds...")
            time.sleep(backoff_factor)
            backoff_factor *= 2  # Double the backoff time for the next retry
        except Exception as e:
            print(f"Unexpected error: {e}. Retrying in {backoff_factor} seconds...")
            time.sleep(backoff_factor)
            backoff_factor *= 2  # Double the backoff time for the next retry

    print("Retries exceeded maximum. Aborting the request.")
    return []


# Function to cancel all orders for a list of symbols
def cancel_all_orders(api, symbols):
    session = HTTP(
        testnet=api["testnet"],
        api_key=api["api_key"],
        api_secret=api["api_secret"],
    )

    for symbol in symbols:
        response = session.cancel_all_orders(category="linear", symbol=symbol)
        if response["retCode"] == 0:
            print(f"All orders for {symbol} canceled successfully.")
        else:
            print(f"Failed to cancel orders for {symbol}.")
            print("Error message:", response["retMsg"])

# Function to continuously monitor open positions and cancel orders
def continuous_monitoring(interval_seconds):
    previous_positions = {api["name"]: frozenset(get_open_positions(api)) for api in apis}

    while True:
        with concurrent.futures.ThreadPoolExecutor() as executor:
            futures = {executor.submit(get_open_positions, api): api["name"] for api in apis}

            # Collect output data
            output_data = []

            for future in concurrent.futures.as_completed(futures):
                api_name = futures[future]
                current_positions = frozenset(future.result())

                # Find positions that no longer exist
                closed_positions = previous_positions[api_name] - current_positions

                # Cancel orders for closed positions
                if closed_positions:
                    cancel_all_orders(next(api for api in apis if api["name"] == api_name), list(closed_positions))

                previous_positions[api_name] = current_positions

                # Add output data for the table
                output_data.append([api_name, list(current_positions)])

            # Print the table
            print("\nCurrent open positions:")
            print(tabulate(output_data, headers=["API", "Positions"], tablefmt="grid"))

        time.sleep(interval_seconds)

# Start continuous monitoring
continuous_monitoring(5)  # Check every 60 seconds (adjust interval as needed)