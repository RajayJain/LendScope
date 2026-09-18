-- =====================================================================
-- 02_load_data.sql
-- Loads the generated CSVs into PostgreSQL.
--
-- IMPORTANT: \copy is a psql *client-side* meta-command (not plain SQL),
-- so run this file with psql, not through a generic SQL runner:
--
--   psql -U postgres -d bank_analytics -f sql/02_load_data.sql
--
-- Adjust the file paths below if you place the CSVs somewhere else.
-- Run 01_schema.sql first.
-- =====================================================================

\copy customers FROM 'data/customers.csv' WITH (FORMAT csv, HEADER true);
\copy loans FROM 'data/loans.csv' WITH (FORMAT csv, HEADER true);
\copy card_transactions FROM 'data/card_transactions.csv' WITH (FORMAT csv, HEADER true);

-- Quick sanity check after loading
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'loans', COUNT(*) FROM loans
UNION ALL
SELECT 'card_transactions', COUNT(*) FROM card_transactions;
