

USE MoMo_SMS_data_processing_system;

-- Query 1: View all users with their information
SELECT 
    user_id,
    CONCAT(first_name, ' ', COALESCE(middle_name, ''), ' ', last_name) AS full_name,
    phone_number,
    account_type,
    created_at
FROM users
ORDER BY user_id;

-- Query 2: View all accounts with user information
SELECT 
    a.account_id,
    CONCAT(u.first_name, ' ', u.last_name) AS account_holder,
    a.miadn,
    a.provider,
    a.currency,
    a.first_seen_at
FROM accounts a
INNER JOIN users u ON a.user_id = u.user_id
ORDER BY a.account_id;

-- Query 3: View all transaction categories
SELECT 
    category_id,
    category_name,
    description
FROM transaction_categories
ORDER BY category_name;

-- Query 4: View all transactions with details
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

-- Query 5: View transactions with sender and receiver information
SELECT 
    t.tx_reference,
    CONCAT(sender.first_name, ' ', sender.last_name) AS sender,
    CONCAT(receiver.first_name, ' ', receiver.last_name) AS receiver,
    t.amount AS amount_rwf,
    t.fee AS fee_rwf,
    tc.category_name AS category,
    t.transaction_date
FROM transactions t
INNER JOIN transaction_participants tp_sender 
    ON t.transaction_id = tp_sender.transaction_id AND tp_sender.role = 'sender'
INNER JOIN users sender ON tp_sender.user_id = sender.user_id
LEFT JOIN transaction_participants tp_receiver 
    ON t.transaction_id = tp_receiver.transaction_id AND tp_receiver.role = 'receiver'
LEFT JOIN users receiver ON tp_receiver.user_id = receiver.user_id
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
ORDER BY t.transaction_date DESC;

-- Query 6: View transaction participants with roles
SELECT 
    tp.participant_id,
    t.tx_reference,
    CONCAT(u.first_name, ' ', u.last_name) AS participant_name,
    tp.role,
    t.amount,
    t.transaction_date
FROM transaction_participants tp
INNER JOIN transactions t ON tp.transaction_id = t.transaction_id
INNER JOIN users u ON tp.user_id = u.user_id
ORDER BY t.transaction_date DESC, tp.role;

-- Query 7: View all raw SMS messages
SELECT 
    sms_id,
    sender_address,
    LEFT(sms_body, 80) AS sms_preview,
    received_date,
    processed_status
FROM raw_sms
ORDER BY received_date DESC;

-- Query 8: View SMS messages with their linked transactions
SELECT 
    rs.sms_id,
    rs.sender_address,
    rs.received_date,
    rs.processed_status,
    t.tx_reference,
    t.amount
FROM raw_sms rs
LEFT JOIN transactions t ON rs.sms_id = t.raw_sms_id
ORDER BY rs.received_date DESC;

-- Query 9: Count SMS by processing status
SELECT 
    processed_status,
    COUNT(*) AS sms_count,
    MIN(received_date) AS earliest,
    MAX(received_date) AS latest
FROM raw_sms
GROUP BY processed_status;

-- Query 10: View recent system logs
SELECT 
    log_id,
    source,
    status,
    message,
    logged_at
FROM system_logs
ORDER BY logged_at DESC
LIMIT 10;

-- Query 11: System activity summary by source
SELECT 
    source,
    status,
    COUNT(*) AS event_count
FROM system_logs
GROUP BY source, status
ORDER BY event_count DESC;

-- Query 12: Transaction summary by category
SELECT 
    tc.category_name,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_amount,
    AVG(t.amount) AS average_amount,
    MIN(t.amount) AS min_amount,
    MAX(t.amount) AS max_amount,
    SUM(t.fee) AS total_fees
FROM transactions t
INNER JOIN transaction_categories tc ON t.category_id = tc.category_id
GROUP BY tc.category_id, tc.category_name
ORDER BY total_amount DESC;

-- Query 13: User transaction statistics
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS user_name,
    u.account_type,
    COUNT(DISTINCT t.transaction_id) AS total_transactions,
    SUM(CASE WHEN tp.role = 'sender' THEN t.amount ELSE 0 END) AS total_sent,
    SUM(CASE WHEN tp.role = 'receiver' THEN t.amount ELSE 0 END) AS total_received,
    SUM(CASE WHEN tp.role = 'sender' THEN t.fee ELSE 0 END) AS total_fees_paid
FROM users u
INNER JOIN transaction_participants tp ON u.user_id = tp.user_id
INNER JOIN transactions t ON tp.transaction_id = t.transaction_id
GROUP BY u.user_id, u.first_name, u.last_name, u.account_type
ORDER BY total_transactions DESC;

-- Query 14: Daily transaction summary
SELECT 
    DATE(transaction_date) AS transaction_day,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    SUM(fee) AS total_fees,
    AVG(amount) AS average_transaction
FROM transactions
GROUP BY DATE(transaction_date)
ORDER BY transaction_day DESC;

-- Query 15: Provider transaction analysis
SELECT 
    a.provider,
    COUNT(DISTINCT a.account_id) AS active_accounts,
    COUNT(DISTINCT u.user_id) AS unique_users
FROM accounts a
INNER JOIN users u ON a.user_id = u.user_id
GROUP BY a.provider
ORDER BY active_accounts DESC;

-- Query 16: Complete transaction history with all details
SELECT 
    t.tx_reference,
    DATE_FORMAT(t.transaction_date, '%Y-%m-%d %H:%i') AS date_time,
    CONCAT(sender.first_name, ' ', sender.last_name) AS sender,
    CONCAT(receiver.first_name, ' ', receiver.last_name) AS receiver,
    tc.category_name AS category,
    t.amount,
    t.fee,
    t.balance_after,
    rs.sender_address AS sms_source,
    t.created_at
FROM transactions t
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
LEFT JOIN raw_sms rs ON t.raw_sms_id = rs.sms_id
LEFT JOIN transaction_participants tp_sender 
    ON t.transaction_id = tp_sender.transaction_id AND tp_sender.role = 'sender'
LEFT JOIN users sender ON tp_sender.user_id = sender.user_id
LEFT JOIN transaction_participants tp_receiver 
    ON t.transaction_id = tp_receiver.transaction_id AND tp_receiver.role = 'receiver'
LEFT JOIN users receiver ON tp_receiver.user_id = receiver.user_id
ORDER BY t.transaction_date DESC;

-- Query 17: User account overview
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    u.phone_number,
    u.account_type,
    a.miadn,
    a.provider,
    a.currency,
    COUNT(DISTINCT tp.transaction_id) AS transaction_count,
    MAX(t.transaction_date) AS last_transaction
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id
LEFT JOIN transaction_participants tp ON u.user_id = tp.user_id
LEFT JOIN transactions t ON tp.transaction_id = t.transaction_id
GROUP BY u.user_id, u.first_name, u.last_name, u.phone_number, 
         u.account_type, a.miadn, a.provider, a.currency
ORDER BY transaction_count DESC;

-- Query 18: Find transactions above a certain amount
SELECT 
    t.tx_reference,
    t.amount,
    t.fee,
    tc.category_name,
    t.transaction_date,
    CONCAT(u.first_name, ' ', u.last_name) AS sender
FROM transactions t
INNER JOIN transaction_categories tc ON t.category_id = tc.category_id
INNER JOIN transaction_participants tp ON t.transaction_id = tp.transaction_id AND tp.role = 'sender'
INNER JOIN users u ON tp.user_id = u.user_id
WHERE t.amount >= 30000
ORDER BY t.amount DESC;

-- Query 19: Find transactions by date range
SELECT 
    tx_reference,
    amount,
    fee,
    transaction_date
FROM transactions
WHERE transaction_date BETWEEN '2025-01-15' AND '2025-01-20'
ORDER BY transaction_date;

-- Query 20: Search SMS messages by content
SELECT 
    sms_id,
    sender_address,
    sms_body,
    received_date,
    processed_status
FROM raw_sms
WHERE sms_body LIKE '%RWF%'
ORDER BY received_date DESC;

-- Query 21: Database summary statistics
SELECT 
    'Users' AS table_name, 
    COUNT(*) AS record_count,
    'Active participants in the system' AS description
FROM users
UNION ALL
SELECT 'Accounts', COUNT(*), 'Mobile money accounts'
FROM accounts
UNION ALL
SELECT 'Transactions', COUNT(*), 'Financial transactions processed'
FROM transactions
UNION ALL
SELECT 'Categories', COUNT(*), 'Transaction categories'
FROM transaction_categories
UNION ALL
SELECT 'Participants', COUNT(*), 'Transaction participant records'
FROM transaction_participants
UNION ALL
SELECT 'SMS Messages', COUNT(*), 'Raw SMS messages received'
FROM raw_sms
UNION ALL
SELECT 'System Logs', COUNT(*), 'System activity logs'
FROM system_logs;

-- Query 22: Transaction volume and value overview
SELECT 
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_value,
    AVG(amount) AS average_value,
    MIN(amount) AS min_transaction,
    MAX(amount) AS max_transaction,
    SUM(fee) AS total_fees_collected,
    MIN(transaction_date) AS first_transaction,
    MAX(transaction_date) AS last_transaction
FROM transactions;

-- Query 23: INSERT - Add a new user
INSERT INTO users (first_name, middle_name, last_name, phone_number, account_type) 
VALUES ('David', NULL, 'Habimana', '+250788555666', 'customer');

-- Verify the insert
SELECT 
    user_id,
    CONCAT(first_name, ' ', COALESCE(middle_name, ''), ' ', last_name) AS full_name,
    phone_number,
    account_type,
    created_at
FROM users 
WHERE phone_number = '+250788555666';

-- Query 24: INSERT - Add a new transaction category
INSERT INTO transaction_categories (category_name, description) 
VALUES ('Loan', 'Loan payment or disbursement');

-- Verify the insert
SELECT * FROM transaction_categories WHERE category_name = 'Loan';

-- Query 25: INSERT - Add a new account for a user
INSERT INTO accounts (user_id, miadn, provider, currency) 
VALUES (2, '788555777', 'MTN', 'RWF');

-- Verify the insert
SELECT 
    a.account_id,
    CONCAT(u.first_name, ' ', u.last_name) AS account_holder,
    a.miadn,
    a.provider,
    a.currency,
    a.first_seen_at
FROM accounts a
INNER JOIN users u ON a.user_id = u.user_id
WHERE a.miadn = '788555777';

-- Query 26: UPDATE - Update user information
UPDATE users 
SET phone_number = '+250788123777', 
    account_type = 'merchant'
WHERE user_id = 6;

-- Verify the update
SELECT 
    user_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    phone_number,
    account_type
FROM users 
WHERE user_id = 6;

-- Query 27: UPDATE - Update transaction category
UPDATE transactions 
SET category_id = 1 
WHERE tx_reference = 'TXN003';

-- Verify the update
SELECT 
    t.tx_reference,
    t.amount,
    tc.category_name,
    t.transaction_date
FROM transactions t
LEFT JOIN transaction_categories tc ON t.category_id = tc.category_id
WHERE t.tx_reference = 'TXN003';

-- Query 28: UPDATE - Update SMS processing status
UPDATE raw_sms 
SET processed_status = 'pending' 
WHERE sms_id = 1;

-- Verify the update
SELECT 
    sms_id,
    sender_address,
    processed_status,
    received_date
FROM raw_sms 
WHERE sms_id = 1;

-- Query 29: DELETE - Remove a system log entry
DELETE FROM system_logs 
WHERE log_id = 10;

-- Verify the deletion
SELECT COUNT(*) AS remaining_logs FROM system_logs;

-- Query 30: DELETE - Remove a user (with CASCADE)
-- First, let's see the user and related data
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    COUNT(DISTINCT a.account_id) AS account_count,
    COUNT(DISTINCT tp.transaction_id) AS transaction_count
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id
LEFT JOIN transaction_participants tp ON u.user_id = tp.user_id
WHERE u.phone_number = '+250788555666'
GROUP BY u.user_id, u.first_name, u.last_name;

-- Now delete the user (CASCADE will delete related accounts and participants)
DELETE FROM users WHERE phone_number = '+250788555666';

-- Verify the deletion
SELECT COUNT(*) AS remaining_users FROM users;

-- Query 31: INSERT multiple records at once
INSERT INTO system_logs (source, status, message) VALUES
('DATA_MIGRATION', 'info', 'Starting data migration process'),
('DATA_MIGRATION', 'success', 'Data migration completed successfully'),
('BACKUP_SERVICE', 'completed', 'Weekly backup completed');

-- Verify multiple inserts
SELECT * FROM system_logs WHERE source = 'DATA_MIGRATION';

-- Query 32: UPDATE with calculated values
UPDATE transactions 
SET balance_after = balance_after + 1000 
WHERE transaction_id IN (1, 2, 3);

-- Verify the update
SELECT 
    transaction_id,
    tx_reference,
    amount,
    balance_after
FROM transactions 
WHERE transaction_id IN (1, 2, 3);

-- Query 33: UPDATE using JOIN (update based on related table)
UPDATE users u
INNER JOIN accounts a ON u.user_id = a.user_id
SET u.account_type = 'premium_customer'
WHERE a.provider = 'MTN' AND u.account_type = 'customer';

-- Verify the update
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    u.account_type,
    a.provider
FROM users u
INNER JOIN accounts a ON u.user_id = a.user_id
WHERE u.account_type = 'premium_customer';

-- Query 34: DELETE with condition based on date
DELETE FROM system_logs 
WHERE logged_at < '2025-01-15 00:00:00' AND status = 'info';

-- Verify the deletion
SELECT 
    MIN(logged_at) AS earliest_log,
    MAX(logged_at) AS latest_log,
    COUNT(*) AS total_logs
FROM system_logs;

-- Query 35: Conditional UPDATE (using CASE)
UPDATE raw_sms 
SET processed_status = CASE 
    WHEN received_date < '2025-01-18' THEN 'completed'
    WHEN received_date >= '2025-01-18' THEN 'processing'
    ELSE processed_status
END;

-- Verify the update
SELECT 
    sms_id,
    sender_address,
    received_date,
    processed_status
FROM raw_sms 
ORDER BY received_date;


SELECT '============================================' AS '';
SELECT 'All Sample Queries Executed Successfully!' AS '';
SELECT 'Database: MoMo_SMS_data_processing_system' AS '';
SELECT '============================================' AS '';
