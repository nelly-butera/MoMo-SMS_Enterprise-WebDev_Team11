
DROP DATABASE IF EXISTS MoMo_SMS_data_processing_system;
CREATE DATABASE MoMo_SMS_data_processing_system;
USE MoMo_SMS_data_processing_system;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT COMMENT 'Unique user identifier (UserId in ERD)',
    first_name VARCHAR(50) NOT NULL COMMENT 'User first name (FirstName in ERD)',
    middle_name VARCHAR(50) NULL COMMENT 'User middle name (MiddleName in ERD)',
    last_name VARCHAR(50) NOT NULL COMMENT 'User last name (LastName in ERD)',
    phone_number VARCHAR(15) NOT NULL COMMENT 'Contact phone number (PhoneNumber in ERD)',
    account_type VARCHAR(20) NOT NULL DEFAULT 'customer' COMMENT 'Type of user account (AccountType in ERD)',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Account creation timestamp (created_at in ERD)',
    
    PRIMARY KEY (user_id),
    UNIQUE KEY uk_phone_number (phone_number),
    INDEX idx_account_type (account_type),
    INDEX idx_created_at (created_at),
    INDEX idx_last_name (last_name),
    CHECK (account_type IN ('customer', 'merchant', 'agent', 'admin'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User and participant information';


CREATE TABLE accounts (
    account_id INT AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT 'Reference to the account owner',
    miadn VARCHAR(15) NOT NULL COMMENT 'Mobile account identifier',
    provider VARCHAR(20) NOT NULL COMMENT 'Service provider name',
    currency CHAR(3) NOT NULL DEFAULT 'RWF' COMMENT 'Currency code (ISO 4217)',
    first_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'First time account was detected',
    
    PRIMARY KEY (account_id),
    UNIQUE KEY uk_miadn (miadn),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_provider (provider),
    INDEX idx_currency (currency),
    CHECK (currency IN ('RWF', 'USD', 'EUR', 'KES', 'UGX', 'TZS'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User account information';


CREATE TABLE transaction_categories (
    category_id INT AUTO_INCREMENT,
    category_name VARCHAR(30) NOT NULL COMMENT 'Name of the category',
    description VARCHAR(255) NULL COMMENT 'Detailed description of category',
    
    PRIMARY KEY (category_id),
    UNIQUE KEY uk_category_name (category_name),
    INDEX idx_category_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Transaction categorization';


CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT COMMENT 'Unique transaction identifier (TransactionId in ERD)',
    tx_reference VARCHAR(30) NOT NULL COMMENT 'Unique transaction reference (TxRef in ERD)',
    category_id INT NULL COMMENT 'Transaction category (CategoryId in ERD)',
    raw_sms_id INT NULL COMMENT 'Reference to source SMS if applicable (RawSmsId in ERD)',
    amount DECIMAL(15,2) NOT NULL COMMENT 'Transaction amount (Amount in ERD)',
    fee DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Transaction fee charged (Fee in ERD)',
    balance_after DECIMAL(15,2) NULL COMMENT 'Account balance after transaction (BalanceAfter in ERD)',
    transaction_date DATETIME NOT NULL COMMENT 'When transaction occurred (TransactionDate in ERD)',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp (created_at in ERD)',
    
    PRIMARY KEY (transaction_id),
    UNIQUE KEY uk_tx_reference (tx_reference),
    FOREIGN KEY (category_id) REFERENCES transaction_categories(category_id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_transaction_date (transaction_date),
    INDEX idx_amount (amount),
    INDEX idx_created_at (created_at),
    CHECK (amount > 0),
    CHECK (fee >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Financial transaction records';


CREATE TABLE transaction_participants (
    participant_id INT AUTO_INCREMENT COMMENT 'Unique participant record identifier (ParticipantId in ERD)',
    transaction_id INT NOT NULL COMMENT 'Reference to transaction (TransactionId in ERD)',
    user_id INT NOT NULL COMMENT 'Reference to user involved (UserId in ERD)',
    role VARCHAR(20) NOT NULL COMMENT 'User role in transaction (Role in ERD)',
    
    PRIMARY KEY (participant_id),
    UNIQUE KEY uk_transaction_user (transaction_id, user_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_user_id (user_id),
    INDEX idx_role (role),
    CHECK (role IN ('sender', 'receiver', 'merchant', 'agent'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Transaction-Participant relationship mapping';


CREATE TABLE raw_sms (
    sms_id INT AUTO_INCREMENT COMMENT 'Unique SMS identifier (SmsId in ERD)',
    sms_protocol TINYINT NOT NULL COMMENT 'SMS protocol type (SmsProtocol in ERD)',
    sender_address VARCHAR(50) NOT NULL COMMENT 'SMS sender identifier (SenderAddress in ERD)',
    service_center VARCHAR(20) NULL COMMENT 'SMS service center (ServiceCenter in ERD)',
    sms_body TEXT(65535) NOT NULL COMMENT 'Raw SMS message content (SmsBody in ERD)',
    received_date DATETIME NOT NULL COMMENT 'When SMS was received (ReceivedDate in ERD)',
    processed_status VARCHAR(20) DEFAULT 'pending' COMMENT 'Processing status (ProcessedStatus in ERD)',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp (created_at in ERD)',
    
    PRIMARY KEY (sms_id),
    INDEX idx_sender_address (sender_address),
    INDEX idx_received_date (received_date),
    INDEX idx_processed_status (processed_status),
    INDEX idx_created_at (created_at),
    CHECK (processed_status IN ('pending', 'processing', 'completed', 'failed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Raw SMS message storage';


ALTER TABLE transactions 
ADD CONSTRAINT fk_raw_sms_id 
FOREIGN KEY (raw_sms_id) REFERENCES raw_sms(sms_id) ON DELETE SET NULL ON UPDATE CASCADE;

CREATE TABLE system_logs (
    log_id INT AUTO_INCREMENT COMMENT 'Unique log identifier (LogId in ERD)',
    status VARCHAR(20) NOT NULL DEFAULT 'info' COMMENT 'Log status (Status in ERD)',
    source VARCHAR(50) NOT NULL COMMENT 'Source of the log entry (Source in ERD)',
    message TEXT(65535) NULL COMMENT 'Detailed log message (Message in ERD)',
    logged_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Log entry timestamp (LoggedAt in ERD)',
    
    PRIMARY KEY (log_id),
    INDEX idx_status (status),
    INDEX idx_source (source),
    INDEX idx_logged_at (logged_at),
    CHECK (status IN ('success', 'warning', 'error', 'info', 'pending', 'failed', 'completed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='System activity logging';


CREATE INDEX idx_transactions_category_date ON transactions(category_id, transaction_date);
CREATE INDEX idx_accounts_user_provider ON accounts(user_id, provider);
CREATE INDEX idx_raw_sms_processed_date ON raw_sms(processed_status, received_date);


INSERT INTO users (first_name, middle_name, last_name, phone_number, account_type, created_at) VALUES
('John', NULL, 'Mugisha', '+250788123456', 'customer', '2025-01-01 10:00:00'),
('Sarah', NULL, 'Uwamahoro', '+250788234567', 'customer', '2025-01-02 11:30:00'),
('Tech Shop', NULL, 'Rwanda', '+250788345678', 'merchant', '2025-01-03 09:15:00'),
('MTN Agent', NULL, 'Kigali', '+250788456789', 'agent', '2025-01-04 14:20:00'),
('Alice', NULL, 'Mutoni', '+250788567890', 'customer', '2025-01-05 16:45:00'),
('Bob', NULL, 'Niyonzima', '+250788678901', 'customer', '2025-01-06 08:30:00'),
('Super Market', NULL, 'Ltd', '+250788789012', 'merchant', '2025-01-07 10:00:00'),
('System', NULL, 'Admin', '+250788890123', 'admin', '2025-01-01 08:00:00');

INSERT INTO accounts (user_id, miadn, provider, currency, first_seen_at) VALUES
(1, '788123456', 'MTN', 'RWF', '2025-01-01 10:00:00'),
(2, '788234567', 'Airtel', 'RWF', '2025-01-02 11:30:00'),
(3, '788345678', 'MTN', 'RWF', '2025-01-03 09:15:00'),
(4, '788456789', 'MTN', 'RWF', '2025-01-04 14:20:00'),
(5, '788567890', 'Airtel', 'RWF', '2025-01-05 16:45:00'),
(6, '788678901', 'MTN', 'RWF', '2025-01-06 08:30:00'),
(7, '788789012', 'Airtel', 'RWF', '2025-01-07 10:00:00');


INSERT INTO transaction_categories (category_name, description) VALUES
('Transfer', 'Money transfer between accounts'),
('Payment', 'Payment for goods and services'),
('Deposit', 'Cash deposit to mobile money'),
('Withdrawal', 'Cash withdrawal from mobile money'),
('Airtime', 'Airtime purchase'),
('Utility', 'Utility bill payments'),
('Salary', 'Salary payment'),
('Refund', 'Transaction refund');


INSERT INTO raw_sms (sms_protocol, sender_address, service_center, sms_body, received_date, processed_status, created_at) VALUES
(0, 'MTN', '+250780000000', 'Transaction successful. You have sent RWF 50,000 to 788234567. Fee: RWF 500. Balance: RWF 149,500. Ref: TXN001', '2025-01-15 10:30:00', 'completed', '2025-01-15 10:30:05'),
(0, 'Airtel', '+250780000001', 'You have received RWF 50,000 from 788123456. Balance: RWF 250,000. Ref: TXN001', '2025-01-15 10:30:10', 'completed', '2025-01-15 10:30:15'),
(0, 'MTN', '+250780000000', 'Payment of RWF 30,000 to Tech Shop Rwanda successful. Fee: RWF 300. Balance: RWF 119,200. Ref: TXN002', '2025-01-16 14:20:00', 'completed', '2025-01-16 14:20:05'),
(0, 'MTN', '+250780000000', 'Airtime purchase of RWF 5,000 successful. Balance: RWF 114,200. Ref: TXN003', '2025-01-17 09:15:00', 'completed', '2025-01-17 09:15:05'),
(0, 'Airtel', '+250780000001', 'Cash deposit of RWF 100,000 successful. Balance: RWF 350,000. Ref: TXN004', '2025-01-18 11:45:00', 'completed', '2025-01-18 11:45:05'),
(0, 'MTN', '+250780000000', 'Withdrawal of RWF 20,000 at Agent 788456789. Fee: RWF 200. Balance: RWF 94,000. Ref: TXN005', '2025-01-19 16:30:00', 'completed', '2025-01-19 16:30:05'),
(0, 'Airtel', '+250780000001', 'You have sent RWF 75,000 to 788678901. Fee: RWF 750. Balance: RWF 274,250. Ref: TXN006', '2025-01-20 13:10:00', 'completed', '2025-01-20 13:10:05');


INSERT INTO transactions (tx_reference, category_id, raw_sms_id, amount, fee, balance_after, transaction_date, created_at) VALUES
('TXN001', 1, 1, 50000.00, 500.00, 149500.00, '2025-01-15 10:30:00', '2025-01-15 10:30:05'),
('TXN002', 2, 3, 30000.00, 300.00, 119200.00, '2025-01-16 14:20:00', '2025-01-16 14:20:05'),
('TXN003', 5, 4, 5000.00, 0.00, 114200.00, '2025-01-17 09:15:00', '2025-01-17 09:15:05'),
('TXN004', 3, 5, 100000.00, 0.00, 350000.00, '2025-01-18 11:45:00', '2025-01-18 11:45:05'),
('TXN005', 4, 6, 20000.00, 200.00, 94000.00, '2025-01-19 16:30:00', '2025-01-19 16:30:05'),
('TXN006', 1, 7, 75000.00, 750.00, 274250.00, '2025-01-20 13:10:00', '2025-01-20 13:10:05');


INSERT INTO transaction_participants (transaction_id, user_id, role) VALUES
(1, 1, 'sender'),
(1, 2, 'receiver'),
(2, 1, 'sender'),
(2, 3, 'merchant'),
(3, 1, 'sender'),
(4, 5, 'receiver'),
(4, 4, 'agent'),
(5, 1, 'sender'),
(5, 4, 'agent'),
(6, 2, 'sender'),
(6, 6, 'receiver');


INSERT INTO system_logs (source, status, message, logged_at) VALUES
('SMS_PROCESSOR', 'success', 'SMS received and queued for processing', '2025-01-15 10:30:05'),
('SMS_PARSER', 'success', 'Transaction data extracted successfully from SMS', '2025-01-15 10:30:06'),
('TRANSACTION_ENGINE', 'success', 'Transaction TXN001 created in database', '2025-01-15 10:30:07'),
('SMS_PROCESSOR', 'success', 'SMS received from MTN', '2025-01-16 14:20:05'),
('TRANSACTION_ENGINE', 'success', 'Payment transaction TXN002 recorded', '2025-01-16 14:20:06'),
('SMS_PROCESSOR', 'success', 'Airtime purchase SMS received', '2025-01-17 09:15:05'),
('SMS_PROCESSOR', 'success', 'Deposit transaction SMS received', '2025-01-18 11:45:05'),
('SYSTEM', 'info', 'Financial management system initialized', '2025-01-01 08:00:00'),
('BACKUP_SERVICE', 'success', 'Daily database backup completed', '2025-01-20 02:00:00'),
('REPORT_SERVICE', 'completed', 'Monthly transaction report generated', '2025-01-20 06:00:00');


SELECT 'Testing CREATE Operations...' AS Test_Section;

INSERT INTO users (first_name, middle_name, last_name, phone_number, account_type) VALUES
('Test', NULL, 'User', '+250788999999', 'customer');


SELECT 'New User Created:' AS Result;
SELECT * FROM users WHERE phone_number = '+250788999999';

SELECT 'Testing READ Operations...' AS Test_Section;

SELECT 'Users with Accounts:' AS Result;
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', COALESCE(u.middle_name, ''), ' ', u.last_name) AS full_name,
    u.phone_number,
    u.account_type,
    a.miadn,
    a.provider,
    a.currency
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id
ORDER BY u.user_id;

SELECT 'Transaction Details:' AS Result;
SELECT 
    t.transaction_id,
    t.tx_reference,
    t.amount,
    t.fee,
    t.balance_after,
    tc.category_name,
    t.transaction_date
FROM transactions t
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
ORDER BY t.transaction_date DESC;

SELECT 'Transaction Flow (Sender -> Receiver):' AS Result;
SELECT 
    t.tx_reference,
    CONCAT(sender.first_name, ' ', sender.last_name) AS sender_name,
    sender.phone_number AS sender_phone,
    CONCAT(receiver.first_name, ' ', receiver.last_name) AS receiver_name,
    receiver.phone_number AS receiver_phone,
    t.amount,
    t.transaction_date
FROM transactions t
INNER JOIN transaction_participants tp_sender ON t.transaction_id = tp_sender.transaction_id AND tp_sender.role = 'sender'
INNER JOIN users sender ON tp_sender.user_id = sender.user_id
LEFT JOIN transaction_participants tp_receiver ON t.transaction_id = tp_receiver.transaction_id AND tp_receiver.role = 'receiver'
LEFT JOIN users receiver ON tp_receiver.user_id = receiver.user_id
ORDER BY t.transaction_date;


SELECT 'Testing UPDATE Operations...' AS Test_Section;


UPDATE users 
SET first_name = 'John', 
    last_name = 'Mugisha (Updated)', 
    phone_number = '+250788123999'
WHERE user_id = 1;

SELECT 'Updated User Information:' AS Result;
SELECT * FROM users WHERE user_id = 1;

UPDATE transactions 
SET category_id = 8 
WHERE transaction_id = 1;

SELECT 'Updated Transaction:' AS Result;
SELECT 
    t.transaction_id,
    t.tx_reference,
    tc.category_name AS updated_category
FROM transactions t
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
WHERE t.transaction_id = 1;


SELECT 'Testing DELETE Operations...' AS Test_Section;


DELETE FROM users WHERE phone_number = '+250788999999';

SELECT 'User Count After Deletion:' AS Result;
SELECT COUNT(*) AS remaining_users FROM users;


SELECT 'Advanced Query Tests...' AS Test_Section;


SELECT 'Transaction Summary by Category:' AS Result;
SELECT 
    tc.category_name,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS average_amount,
    SUM(t.fee) AS total_fees
FROM transactions t
INNER JOIN transaction_categories tc ON t.category_id = tc.category_id
GROUP BY tc.category_id, tc.category_name
ORDER BY total_amount DESC;


SELECT 'User Transaction Statistics:' AS Result;
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    u.account_type,
    COUNT(DISTINCT t.transaction_id) AS transaction_count,
    SUM(CASE WHEN tp.role = 'sender' THEN t.amount ELSE 0 END) AS total_sent,
    SUM(CASE WHEN tp.role = 'receiver' THEN t.amount ELSE 0 END) AS total_received
FROM users u
INNER JOIN transaction_participants tp ON u.user_id = tp.user_id
INNER JOIN transactions t ON tp.transaction_id = t.transaction_id
GROUP BY u.user_id, u.first_name, u.last_name, u.account_type
ORDER BY transaction_count DESC;


SELECT 'System Activity Summary:' AS Result;
SELECT 
    source,
    status,
    COUNT(*) AS occurrence_count
FROM system_logs
GROUP BY source, status
ORDER BY occurrence_count DESC;

SELECT 'Recent Transactions (Last 5):' AS Result;
SELECT 
    t.tx_reference,
    t.amount,
    t.fee,
    tc.category_name,
    t.transaction_date
FROM transactions t
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
ORDER BY t.transaction_date DESC
LIMIT 5;



SELECT 'Database Summary Statistics' AS Summary_Section;

SELECT 'Total Records per Table:' AS Result;
SELECT 
    'Users' AS table_name, COUNT(*) AS record_count FROM users
UNION ALL
SELECT 'Accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'Transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'Transaction Categories', COUNT(*) FROM transaction_categories
UNION ALL
SELECT 'Transaction Participants', COUNT(*) FROM transaction_participants
UNION ALL
SELECT 'Raw SMS', COUNT(*) FROM raw_sms
UNION ALL
SELECT 'System Logs', COUNT(*) FROM system_logs;


SELECT '============================================' AS Message;
SELECT 'Database Setup Complete!' AS Message;
SELECT 'All tables created with constraints and indexes' AS Message;
SELECT 'Sample data inserted successfully' AS Message;
SELECT 'CRUD operations tested' AS Message;
SELECT '============================================' AS Message;
