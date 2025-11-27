CREATE DATABASE IF NOT EXISTS crypto_tracker;
USE crypto_tracker;

CREATE TABLE IF NOT EXISTS bitcoin_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    price_usd DECIMAL(10,2),
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
);
