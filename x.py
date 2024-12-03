<<<<<<< HEAD
import pandas as pd

# Load the data from the CSV file
file_path = 'wildberries_report.csv'  # Update this to your actual file path
df = pd.read_csv(file_path, delimiter=',')

# Display the first few rows and data types to understand the structure
print(df.head())
print(df.dtypes)

# Convert relevant columns to numeric, forcing errors to NaN
def to_numeric(column):
    # Ensure column is string type before replacing and converting
    column = column.astype(str).str.replace(',', '.', regex=False)
    return pd.to_numeric(column, errors='coerce')

# Apply conversion to necessary columns
df['Цена розничная'] = to_numeric(df['Цена розничная'])
df['Вознаграждение Вайлдберриз (ВВ), без НДС'] = to_numeric(df['Вознаграждение Вайлдберриз (ВВ), без НДС'])
df['Возмещение за выдачу и возврат товаров на ПВЗ'] = to_numeric(df['Возмещение за выдачу и возврат товаров на ПВЗ'])
df['Возмещение расходов по эквайрингу'] = to_numeric(df['Возмещение расходов по эквайрингу'])

# Calculate the cost of goods
df['Cost of Goods'] = df['Цена розничная'] * 0.60

# Group by 'Артикул поставщика' and aggregate data
grouped_df = df.groupby('Артикул поставщика').agg({
    'Кол-во': 'sum',
    'Вознаграждение Вайлдберриз (ВВ), без НДС': 'sum',
    'Возмещение за выдачу и возврат товаров на ПВЗ': 'sum',
    'Возмещение расходов по эквайрингу': 'sum',
    'Cost of Goods': 'sum'
}).reset_index()

# Calculate the total cost and revenue
grouped_df['Total Cost'] = (grouped_df['Cost of Goods'] +
                            grouped_df['Возмещение за выдачу и возврат товаров на ПВЗ'] +
                            grouped_df['Возмещение расходов по эквайрингу'])

grouped_df['Total Revenue'] = grouped_df['Кол-во'] * df['Цена розничная'].mean()  # Assuming average selling price for revenue calculation

# Save the transformed data to a new CSV file
output_file_path = 'transformed_report.csv'
grouped_df.to_csv(output_file_path, index=False)

print(f'Transformed report saved to {output_file_path}')
=======
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
>>>>>>> 8475f954632512e7b4e03c5f84b914f9a411fbd6
