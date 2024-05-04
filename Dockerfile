# Use an official Python runtime as the base image
FROM python:3.11-slim-buster

# Set the working directory in the container to /app
WORKDIR /app

# Copy the requirements.txt file to the container
COPY requirements.txt .

# Install the required packages from the requirements.txt file
RUN pip install -r requirements.txt

# Copy the current directory contents into the container at /app
COPY . .

# Set the environment variable for the API keys and secrets
ENV API_KEYS='{"Testnet": {"api_key": "UAD2faj813tVHtu5n4", "api_secret": "Nj7IlRSXPW3drJno53KzKzt8X2s3zi64Nbj8", "testnet": true}, "Sub-account": {"api_key": "LkBKjLHEoRwQTXwj7z", "api_secret": "PIyBgeezw5IemGmCLJzg0S4KK39aXKI2RXsY", "testnet": false}, "Main account TCLU": {"api_key": "d2PdeMd88jrONugpE7", "api_secret": "lem9OCVuggIMnN8gTna94FV2a9RWune4Z588", "testnet": false}}'

# Expose the port your application will run on (if applicable)
EXPOSE 8080

# Define the command to run the script
CMD ["python", "test.py"]
