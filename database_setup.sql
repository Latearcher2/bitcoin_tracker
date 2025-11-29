CREATE DATABASE IF NOT EXISTS crypto_tracker;
USE crypto_tracker;

-- Table for storing historical Bitcoin prices
CREATE TABLE IF NOT EXISTS bitcoin_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    price_usd DECIMAL(10,2) NOT NULL,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
);
