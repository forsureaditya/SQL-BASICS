/* ==========================================================
   MySQL NOTES — Basics to Triggers
   Tip: run each section separately, not the whole file at once
   (some commands here are destructive on purpose, for demo).
   ========================================================== */


/* ==========================================================
   1. DATABASE
   ========================================================== */

CREATE DATABASE myDB;   -- create a new database
USE myDB;               -- select it; all next queries run on this DB
DROP DATABASE myDB;     -- delete DB permanently (tables + data gone)

-- READ ONLY mode: protects DB from accidental changes/deletion
ALTER DATABASE myDB READ ONLY = 1;
DROP DATABASE myDB;     -- ERROR: DB is READ ONLY, so drop is blocked
ALTER DATABASE myDB READ ONLY = 0;  -- turn protection off again


/* ==========================================================
   2. TABLES (CREATE / RENAME / DROP)
   ========================================================== */

CREATE TABLE employees (
    employee_id INT,
    first_name  VARCHAR(50),    -- 50 = max characters allowed
    last_name   VARCHAR(50),
    hourly_pay  DECIMAL(5, 2),  -- 5 = total digits, 2 = digits after the point (max 999.99)
    hire_date   DATE            -- format: 'YYYY-MM-DD'
);

SELECT * FROM employees;        -- view everything in the table

RENAME TABLE employees TO workers;   -- rename table
RENAME TABLE workers TO employees;   -- rename back (rest of the notes use `employees`)

DROP TABLE employees;           -- delete table + its data (can't undo)


/* ==========================================================
   3. ALTER TABLE (change structure of an existing table)
   (assume `employees` is created again before running these)
   ========================================================== */

-- add a column (goes at the end by default)
ALTER TABLE employees
ADD phone_number VARCHAR(15);

-- rename a column
ALTER TABLE employees
RENAME COLUMN phone_number TO email;

-- change the data type / size of a column
ALTER TABLE employees
MODIFY COLUMN email VARCHAR(100);

-- move a column to a different position
ALTER TABLE employees
MODIFY email VARCHAR(100)
AFTER last_name;                -- use FIRST instead of AFTER to make it the first column

-- remove a column (its data is lost)
ALTER TABLE employees
DROP COLUMN email;


/* ==========================================================
   4. INSERT (adding rows)
   ========================================================== */

-- single row, all columns
-- no column list => you MUST give a value for EVERY column, in table order
INSERT INTO employees
VALUES (1, "Eugene", "Krabs", 25.50, "2023-01-02");

-- multiple rows at once (cheaper than many separate INSERTs)
-- every row must have all columns, otherwise ERROR
INSERT INTO employees
VALUES
    (2, "Squidward", "Tentacles", 15.00, "2023-01-03"),
    (3, "Spongebob", "Squarepants", 12.50, "2023-01-04"),
    (4, "Patrick", "Star", 17.50, "2023-01-05");
    -- (5, "Sheldon", "Plankton")   <- would ERROR: values missing

-- partial row: name the columns you are filling
-- the remaining columns become NULL (or their DEFAULT)
INSERT INTO employees (employee_id, first_name, last_name)
VALUES (5, "Sheldon", "Plankton");


/* ==========================================================
   5. SELECT (reading data) + WHERE (filtering)
   ========================================================== */

-- only specific columns
SELECT first_name, last_name
FROM employees;

-- filter rows with WHERE
SELECT * FROM employees WHERE employee_id = 1;     -- equal
SELECT * FROM employees WHERE hourly_pay >= 15;    -- comparison (<, >, <=, >=)
SELECT * FROM employees WHERE employee_id != 1;    -- not equal (<> also works)

-- NULL check: use IS NULL / IS NOT NULL
-- "= NULL" never works, because NULL is "unknown", not a value
SELECT * FROM employees WHERE hire_date IS NOT NULL;


/* ==========================================================
   6. UPDATE & DELETE
   ========================================================== */

-- UPDATE: change existing data
-- WARNING: without WHERE, EVERY row gets updated!
UPDATE employees
SET hourly_pay = 10.99,
    hire_date  = "2023-01-07"
WHERE employee_id = 3;

-- DELETE all rows (table structure stays, data is gone)
DELETE FROM employees;

-- DELETE specific row(s) — always use WHERE
DELETE FROM employees
WHERE employee_id = 4;


/* ==========================================================
   7. TRANSACTIONS (AUTOCOMMIT, COMMIT, ROLLBACK)
   By default MySQL saves every change instantly (AUTOCOMMIT = ON).
   Turn it OFF to get an "undo" safety net.
   ========================================================== */

SET AUTOCOMMIT = OFF;   -- changes are NOT saved until you COMMIT

COMMIT;                 -- save point: everything before this is permanent

DELETE FROM employees;  -- oops, deleted everything (not saved yet)

ROLLBACK;               -- undo back to the last COMMIT; data is restored

SET AUTOCOMMIT = ON;    -- back to normal behaviour


/* ==========================================================
   8. DATE & TIME
   ========================================================== */

CREATE TABLE test (
    my_date     DATE,       -- 'YYYY-MM-DD'
    my_time     TIME,       -- 'HH:MM:SS'
    my_datetime DATETIME    -- both together
);

-- current date / time / both
INSERT INTO test
VALUES (CURRENT_DATE(), CURRENT_TIME(), NOW());

-- date math examples:
--   CURRENT_DATE() + 1   -> tomorrow
--   CURRENT_TIME() - 2000 -> 2000 seconds ago (approx, as a number)
-- (for cleaner date math use DATE_ADD / INTERVAL)

SELECT * FROM test;


/* ==========================================================
   9. CONSTRAINTS (rules on what data a column can hold)
   ========================================================== */

-- ---------- UNIQUE: no duplicate values in the column ----------

-- at table creation
CREATE TABLE products (
    product_id   INT,
    product_name VARCHAR(25) UNIQUE,
    price        DECIMAL(4, 2)
);

-- on an existing table
ALTER TABLE products
ADD CONSTRAINT UNIQUE (product_name);

-- ---------- NOT NULL: value is mandatory ----------

-- at table creation
CREATE TABLE products (
    product_id   INT,
    product_name VARCHAR(25),
    price        DECIMAL(4, 2) NOT NULL
);

-- on an existing table
ALTER TABLE products
MODIFY price DECIMAL(4, 2) NOT NULL;

-- ---------- CHECK: value must satisfy a condition ----------

-- at table creation
CREATE TABLE employees (
    employee_id INT,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    hourly_pay  DECIMAL(5, 2),
    hire_date   DATE,
    -- CHECK (hourly_pay >= 10.00)                              -- unnamed version
    CONSTRAINT chk_hourly_pay CHECK (hourly_pay >= 10.00)       -- named version (easier to drop later)
);

-- on an existing table
ALTER TABLE employees
ADD CONSTRAINT chk_hourly_pay CHECK (hourly_pay >= 10.00);

-- remove a CHECK constraint (needs its name)
ALTER TABLE employees
DROP CHECK chk_hourly_pay;

-- ---------- DEFAULT: value used when none is given ----------

-- at table creation
CREATE TABLE products (
    product_id   INT,
    product_name VARCHAR(25),
    price        DECIMAL(4, 2) DEFAULT 0.00,
    insert_date  DATETIME DEFAULT NOW()     -- auto timestamp of insertion
);

-- on an existing table (one ALTER per column)
ALTER TABLE products
ALTER price SET DEFAULT 0.00;

ALTER TABLE products
ALTER insert_date SET DEFAULT (NOW());      -- function defaults need extra brackets in some MySQL versions

-- ---------- PRIMARY KEY: unique + not null, identifies each row ----------
-- only ONE primary key per table

-- at table creation
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    amount         DECIMAL(5, 2)
);

-- on an existing table
ALTER TABLE transactions
ADD CONSTRAINT PRIMARY KEY (transaction_id);

-- ---------- AUTO_INCREMENT: DB generates the next number itself ----------
-- works on a key column; starts from 1 by default

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    amount         DECIMAL(5, 2)
);

-- start counting from a custom value
ALTER TABLE transactions
AUTO_INCREMENT = 1000;


/* ==========================================================
   10. FOREIGN KEY (links a column to the PRIMARY KEY of another table)
   Used to connect tables, e.g. transactions -> customers.
   The referenced table (customers) must exist first.
   ========================================================== */

-- at table creation (MySQL auto-names it: transactions_ibfk_1)
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    amount         DECIMAL(5, 2),
    customer_id    INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- drop a foreign key (use the auto-generated or custom name)
ALTER TABLE transactions
DROP FOREIGN KEY transactions_ibfk_1;

-- add a foreign key with your OWN name (better practice)
ALTER TABLE transactions
ADD CONSTRAINT fk_customer_id
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);


/* ==========================================================
   11. JOINS (combine rows from 2+ tables)
   ========================================================== */

-- INNER JOIN: only rows that have a match in BOTH tables
SELECT transaction_id, amount, first_name, last_name
FROM transactions
INNER JOIN customers
    ON transactions.customer_id = customers.customer_id;

-- LEFT JOIN: ALL rows from the left table (transactions),
--            matching rows from the right; no match => NULL
SELECT transaction_id, amount, first_name, last_name
FROM transactions
LEFT JOIN customers
    ON transactions.customer_id = customers.customer_id;

-- RIGHT JOIN: mirror of LEFT — ALL rows from the right table (customers)
SELECT transaction_id, amount, first_name, last_name
FROM transactions
RIGHT JOIN customers
    ON transactions.customer_id = customers.customer_id;


/* ==========================================================
   12. FUNCTIONS
   ========================================================== */

-- Aggregate functions: COUNT, MAX, MIN, AVG, SUM
-- AS gives the result column a readable name (alias)
SELECT COUNT(amount) AS count
FROM transactions;

SELECT MAX(amount) AS maximum
FROM transactions;

-- CONCAT: join strings together
SELECT CONCAT(first_name, " ", last_name) AS full_name   -- " " adds a space between names
FROM employees;

-- Logical operators: AND / OR / NOT / BETWEEN / IN
SELECT *
FROM employees
WHERE hire_date < "2023-01-05" AND job = "cook";         -- both conditions must be true

-- more examples of the same idea (use with SELECT * FROM employees):
-- WHERE NOT job = "manager" AND NOT job = "asst. manager";   -- exclude values
-- WHERE hire_date BETWEEN "2023-01-04" AND "2023-01-07";     -- range (both ends included)
-- WHERE job IN ("cook", "cashier", "janitor");               -- match any value in the list


/* ==========================================================
   13. WILDCARDS (with LIKE)
   %  = any number of characters (0 or more)
   _  = exactly ONE character
   ========================================================== */

SELECT *
FROM employees
WHERE first_name LIKE "s%";          -- names starting with "s"

-- more patterns:
-- WHERE hire_date LIKE "2023%";        -- any date in 2023
-- WHERE hire_date LIKE "____-01-__";   -- any date in January (4 + 2 underscores)
-- WHERE job LIKE "_a%";                -- second letter is "a"


/* ==========================================================
   14. ORDER BY (sorting results)
   ========================================================== */

SELECT *
FROM employees
ORDER BY last_name DESC;             -- ASC = A-Z (default), DESC = Z-A

-- sort by 2 columns: second one breaks ties of the first
SELECT *
FROM transactions
ORDER BY amount DESC, customer_id ASC;


/* ==========================================================
   15. LIMIT (restrict number of rows; used for pagination)
   ========================================================== */

SELECT *
FROM customers
ORDER BY last_name DESC
LIMIT 10;                            -- only the first 10 rows

-- LIMIT offset, count  -> skip `offset` rows, then show `count` rows
SELECT *
FROM customers
ORDER BY last_name DESC
LIMIT 5, 10;                         -- skip 5, show next 10


/* ==========================================================
   16. UNION (stack results of 2+ SELECTs vertically)
   Rules: same number of columns and compatible data types.
   ========================================================== */

-- UNION removes duplicate rows
SELECT * FROM income
UNION
SELECT * FROM expenses;

-- UNION ALL keeps duplicates (also faster, no duplicate check)
SELECT first_name, last_name FROM employees
UNION ALL
SELECT first_name, last_name FROM customers;


/* ==========================================================
   17. SELF JOIN (a table joined with itself)
   Use: compare rows of the same table, show hierarchy
   (e.g. which customer referred which customer).
   ========================================================== */

SELECT
    a.customer_id,
    CONCAT(a.first_name, " ", a.last_name) AS customer,
    CONCAT(b.first_name, " ", b.last_name) AS referred_by
FROM customers AS a
INNER JOIN customers AS b           -- b = second "copy" of the same table
    ON a.referral_id = b.customer_id;


/* ==========================================================
   18. VIEW (saved query that behaves like a virtual table)
   - Stores no data itself; reads from the real table(s)
   - Always shows up-to-date data
   - Good for hiding columns or simplifying complex queries
   ========================================================== */

CREATE VIEW employee_attendance AS
SELECT first_name, last_name
FROM employees;

SELECT * FROM employee_attendance;   -- use it like a normal table

DROP VIEW employee_attendance;       -- remove the view (real table is untouched)


/* ==========================================================
   19. INDEX (B-Tree structure for faster searching)
   - Without index: MySQL scans the column row by row (slow on big tables)
   - Trade-off: SELECT gets faster, INSERT/UPDATE/DELETE get slower
   - Create indexes on columns you search/filter/join on often
   ========================================================== */

-- single-column index
CREATE INDEX last_name_idx
ON customers(last_name);

SHOW INDEXES FROM customers;         -- list all indexes of a table

-- multi-column index (order matters: last_name first, then first_name)
CREATE INDEX last_name_first_name_idx
ON customers(last_name, first_name);

-- drop an index
ALTER TABLE customers
DROP INDEX last_name_first_name_idx;


/* ==========================================================
   20. SUBQUERY (a query inside another query)
   ========================================================== */

-- subquery in SELECT: show the overall average next to every row
SELECT
    first_name, last_name, hourly_pay,
    (SELECT AVG(hourly_pay) FROM employees) AS avg_pay
FROM employees;

-- subquery in WHERE: employees paid at or above average
SELECT first_name, last_name, hourly_pay
FROM employees
WHERE hourly_pay >= (SELECT AVG(hourly_pay) FROM employees);


/* ==========================================================
   21. GROUP BY (+ HAVING)
   Groups rows with the same value and runs aggregate functions
   (SUM, MAX, MIN, AVG, COUNT) on each group.
   ========================================================== */

-- total amount per order date
SELECT SUM(amount), order_date
FROM transactions
GROUP BY order_date
HAVING COUNT(amount) > 1;            -- only dates with more than 1 transaction

-- WHERE vs HAVING:
--   WHERE  -> filters rows BEFORE grouping (can't use aggregate functions)
--   HAVING -> filters groups AFTER grouping (use with aggregates)


/* ==========================================================
   22. WITH ROLLUP (extension of GROUP BY)
   Adds an extra last row with the GRAND TOTAL (super-aggregate).
   ========================================================== */

SELECT SUM(amount), order_date
FROM transactions
GROUP BY order_date WITH ROLLUP;     -- last row (order_date = NULL) = grand total


/* ==========================================================
   23. ON DELETE (what happens to child rows when the parent row is deleted)
   - ON DELETE SET NULL : child's foreign key becomes NULL
   - ON DELETE CASCADE  : child row is deleted too
   ========================================================== */

SET foreign_key_checks = 0;          -- temporarily disable FK checks (e.g. to drop tables in any order)
SET foreign_key_checks = 1;          -- turn them back ON when done!

-- at table creation
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    amount         DECIMAL(5, 2),
    customer_id    INT,
    order_date     DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL
);

-- on an existing table (drop the old FK first if it exists)
ALTER TABLE transactions
ADD CONSTRAINT fk_customer_id
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE SET NULL;              -- or: ON DELETE CASCADE


/* ==========================================================
   24. STORED PROCEDURE (saved SQL you can call by name, like a function)
   Useful for queries you write again and again.
   ========================================================== */

-- DELIMITER: temporarily change ";" so MySQL doesn't end the statement
-- inside the procedure body. $$ is the convention ( // is also common).
DELIMITER $$
CREATE PROCEDURE get_customers()
BEGIN
    SELECT * FROM customers;
END $$
DELIMITER ;                          -- restore normal delimiter

CALL get_customers();                -- run the procedure

DROP PROCEDURE get_customers;        -- delete the procedure

-- procedure with parameters (IN = input value passed by the caller)
DELIMITER $$
CREATE PROCEDURE find_customer(IN f_name VARCHAR(50), IN l_name VARCHAR(50))
BEGIN
    SELECT *
    FROM customers
    WHERE first_name = f_name AND last_name = l_name;
END $$
DELIMITER ;

CALL find_customer("Bob", "Sponge");


/* ==========================================================
   25. TRIGGER (runs automatically when an event happens on a table)
   Uses: data validation, auto-calculation, auditing, keeping tables in sync.
   Timing: BEFORE / AFTER   |   Event: INSERT / UPDATE / DELETE
   NEW.col = value after the change | OLD.col = value before the change
   ========================================================== */

-- prerequisite: the table needs a salary column
ALTER TABLE employees
ADD COLUMN salary DECIMAL(10, 2);

-- before every UPDATE, auto-calculate yearly salary from hourly pay
-- (2080 = working hours in a year: 40 hrs x 52 weeks)
CREATE TRIGGER before_hourly_pay_update
BEFORE UPDATE ON employees
FOR EACH ROW
SET NEW.salary = (NEW.hourly_pay * 2080);

SHOW TRIGGERS;                       -- list all triggers

-- after an employee row is deleted, reduce the total salary expense
CREATE TRIGGER after_salary_delete
AFTER DELETE ON employees
FOR EACH ROW
UPDATE expenses
SET expense_total = expense_total - OLD.salary
WHERE expense_name = "salaries";

DROP TRIGGER before_hourly_pay_update;   -- remove a trigger
