DROP DATABASE IF EXISTS MoMo_SMS_system;
CREATE DATABASE MoMo_SMS_system;
USE MoMo_SMS_system;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50),
    middle_name VARCHAR(50),
    last_name VARCHAR(50),
    phone_number VARCHAR(15) UNIQUE,
    account_type VARCHAR(20) DEFAULT 'customer',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transaction_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(30),
    description VARCHAR(255)
);

CREATE TABLE raw_sms (
    sms_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_address VARCHAR(50),
    sms_body TEXT,
    received_date DATETIME,
    processed_status VARCHAR(20) DEFAULT 'pending'
);

CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    tx_reference VARCHAR(30) UNIQUE,
    category_id INT,
    raw_sms_id INT,
    amount DECIMAL(12,2),
    fee DECIMAL(12,2),
    balance_after DECIMAL(12,2),
    transaction_date DATETIME,
    FOREIGN KEY (category_id) REFERENCES transaction_categories(category_id),
    FOREIGN KEY (raw_sms_id) REFERENCES raw_sms(sms_id)
);

CREATE TABLE transaction_participants (
    transaction_id INT,
    user_id INT,
    role VARCHAR(20),
    PRIMARY KEY (transaction_id, user_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE system_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(20),
    message TEXT,
    logged_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (first_name, last_name, phone_number, account_type) VALUES
('John', 'Mugisha', '+250788123456', 'customer'),
('Sarah', 'Uwamahoro', '+250788234567', 'customer'),
('Tech Shop', 'Rwanda', '+250788345678', 'merchant');

INSERT INTO transaction_categories (category_name) VALUES
('Transfer'), ('Payment'), ('Deposit');

INSERT INTO raw_sms (sender_address, sms_body, received_date, processed_status) VALUES
('MTN', 'Sent 50000 to 788234567. Ref: TXN001', '2025-01-15 10:30:00', 'completed');

INSERT INTO transactions (tx_reference, category_id, raw_sms_id, amount, fee, balance_after, transaction_date) VALUES
('TXN001', 1, 1, 50000.00, 500.00, 149500.00, '2025-01-15 10:30:00');

INSERT INTO transaction_participants VALUES (1, 1, 'sender'), (1, 2, 'receiver');

SELECT * FROM users;

SELECT tx_reference, amount, transaction_date 
FROM transactions 
WHERE amount > 1000;

-- join query
SELECT t.tx_reference, u.first_name, tp.role
FROM transactions t
JOIN transaction_participants tp ON t.transaction_id = tp.transaction_id
JOIN users u ON tp.user_id = u.user_id;