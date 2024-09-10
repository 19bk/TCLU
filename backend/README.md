# Crypto Trend Analyzer

A Flask-based backend for analyzing cryptocurrency trends using the CCXT library.

## Setup

1. Clone the repository.
2. Build the Docker image:
   ```bash
   docker-compose build
   ```
3. Run the application:
   ```bash
   docker-compose up
   ```
4. Access the API at `http://localhost:5000/trends/<symbol>`.