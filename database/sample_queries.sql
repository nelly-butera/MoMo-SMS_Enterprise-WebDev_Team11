USE MoMo_SMS_data_processing_system;

-- 1.creating a new customer
INSERT INTO users (first_name, last_name, phone_number, account_type) 
VALUES ('Eric', 'Nsengimana', '+250780111222', 'customer');

-- 2.verifying if the user exist
SELECT * FROM users WHERE phone_number = '+250780111222';

-- 3. testing security rule file by trying to add a user with an invalid account_type (it should fail if the constraint is working)
INSERT INTO users (first_name, last_name, phone_number, account_type) 
VALUES ('Test', 'Failure', '+250780000000', 'superuser'); 

-- 4. testing transaction logic, seeing if join command works
SELECT 
    t.tx_reference, 
    u.first_name AS sender, 
    t.amount, 
    tc.category_name
FROM transactions t
JOIN transaction_participants tp ON t.transaction_id = tp.transaction_id
JOIN users u ON tp.user_id = u.user_id
JOIN transaction_categories tc ON t.category_id = tc.category_id
WHERE tp.role = 'sender';

-- 5. testing updating user info
UPDATE users 
SET phone_number = '+250780999888' 
WHERE last_name = 'Nsengimana';

-- 6. accuracy testing by trying to insert a negative transaction amount
INSERT INTO transactions (tx_reference, amount, transaction_date)
VALUES ('ERROR_TXN', -500.00, NOW());

-- 7. viewing system logs for errorz
SELECT * FROM system_logs WHERE status = 'error';

-- 8. report gen, checking to see total money by each category
SELECT 
    category_id, 
    SUM(amount) as total_volume, 
    COUNT(*) as num_tx
FROM transactions 
GROUP BY category_id;

-- 9. deleting a log record
DELETE FROM system_logs WHERE message LIKE '%test%';

-- 10. showing all table's record counts
SELECT 'Users' as TableName, COUNT(*) FROM users
UNION
SELECT 'Transactions', COUNT(*) FROM transactions
UNION
SELECT 'Logs', COUNT(*) FROM system_logs;