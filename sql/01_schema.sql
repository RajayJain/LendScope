-- =====================================================================
-- Bank Loan & Card Analytics — PostgreSQL Schema
-- =====================================================================
-- Run this first to create the database objects, then load the CSVs
-- with 02_load_data.sql (via psql \copy).
-- =====================================================================

DROP TABLE IF EXISTS card_transactions CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id         VARCHAR(12) PRIMARY KEY,
    first_name          VARCHAR(50),
    last_name           VARCHAR(50),
    gender              CHAR(1),
    date_of_birth       DATE,
    address_state       CHAR(2),
    city                VARCHAR(60),
    employment_title    VARCHAR(60),
    employment_length   VARCHAR(15),
    home_ownership      VARCHAR(15),
    annual_income        NUMERIC(12,2),
    credit_score          SMALLINT,
    signup_date            DATE
);

CREATE TABLE loans (
    loan_id                    VARCHAR(15) PRIMARY KEY,
    customer_id                VARCHAR(12) REFERENCES customers(customer_id),
    address_state              CHAR(2),
    application_type           VARCHAR(12),
    emp_length                 VARCHAR(15),
    emp_title                  VARCHAR(60),
    grade                      CHAR(1),
    sub_grade                  VARCHAR(3),
    home_ownership              VARCHAR(15),
    purpose                     VARCHAR(30),
    issue_date                  DATE,
    loan_status                 VARCHAR(15),   -- Fully Paid | Current | Charged Off
    term_months                  SMALLINT,      -- 36 | 60
    verification_status          VARCHAR(20),
    annual_income                 NUMERIC(12,2),
    dti                            NUMERIC(6,4),
    int_rate                        NUMERIC(6,4),
    installment                      NUMERIC(10,2),
    loan_amount                       NUMERIC(12,2),
    funded_amount                      NUMERIC(12,2),
    total_acc                           SMALLINT,
    total_payment                        NUMERIC(12,2),
    total_rec_prncp                       NUMERIC(12,2),
    total_rec_int                          NUMERIC(12,2),
    last_payment_date                       DATE,
    next_payment_date                        DATE,
    last_credit_pull_date                     DATE
);

CREATE TABLE card_transactions (
    transaction_id        VARCHAR(15) PRIMARY KEY,
    customer_id            VARCHAR(12) REFERENCES customers(customer_id),
    card_type                VARCHAR(6),     -- CREDIT | DEBIT
    card_last4                 SMALLINT,
    transaction_date             DATE,
    transaction_time               TIME,
    merchant_category                 VARCHAR(30),
    transaction_type                   VARCHAR(20),  -- PURCHASE | REFUND | TRANSFER | ATM_WITHDRAWAL | BILL_PAYMENT
    channel                             VARCHAR(10),  -- POS | ONLINE | MOBILE | ATM
    amount                               NUMERIC(10,2),
    state                                 CHAR(2),
    city                                   VARCHAR(60),
    is_international                        SMALLINT,     -- 0/1
    is_fraud                                 SMALLINT      -- 0/1
);

-- ---------------------------------------------------------------------
-- Indexes to support the business-question queries in 03_business_questions.sql
-- ---------------------------------------------------------------------
CREATE INDEX idx_loans_customer        ON loans(customer_id);
CREATE INDEX idx_loans_issue_date      ON loans(issue_date);
CREATE INDEX idx_loans_status          ON loans(loan_status);
CREATE INDEX idx_loans_state           ON loans(address_state);
CREATE INDEX idx_loans_purpose         ON loans(purpose);
CREATE INDEX idx_loans_grade           ON loans(grade);

CREATE INDEX idx_txn_customer          ON card_transactions(customer_id);
CREATE INDEX idx_txn_date              ON card_transactions(transaction_date);
CREATE INDEX idx_txn_card_type         ON card_transactions(card_type);
CREATE INDEX idx_txn_category          ON card_transactions(merchant_category);
CREATE INDEX idx_txn_fraud             ON card_transactions(is_fraud);


SELECT * FROM loans;