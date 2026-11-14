-- Active: 1754303878390@@127.0.0.1@5433@postgres@public
-- =====================================================
-- ORDERS: one table containing order + product details
-- =====================================================
DROP TABLE IF EXISTS orders;
 
CREATE TABLE orders (
    order_id      INT PRIMARY KEY,
    order_date    DATE         NOT NULL,
    customer_name TEXT         NOT NULL,
    region        TEXT         NOT NULL,   -- East / West / North
    product_id    INT          NOT NULL,
    product_name  TEXT         NOT NULL,
    category      TEXT         NOT NULL,   -- Electronics / Furniture / Stationery
    unit_price    NUMERIC(10,2) NOT NULL,
    quantity      INT          NOT NULL,
    amount        NUMERIC(12,2) GENERATED ALWAYS AS (unit_price * quantity) STORED
);
 
INSERT INTO orders
    (order_id, order_date, customer_name, region, product_id, product_name, category, unit_price, quantity)
VALUES
-- Jan 1 (2 orders)
(1,  '2026-01-01', 'Ada',    'East',  101, 'Laptop',     'Electronics', 800, 1),
(2,  '2026-01-01', 'Bola',   'West',  103, 'Headphones', 'Electronics', 100, 2),
-- Jan 2 (3 orders)
(3,  '2026-01-02', 'Chidi',  'East',  202, 'Chair',      'Furniture',   150, 2),
(4,  '2026-01-02', 'Dayo',   'North', 301, 'Notebook',   'Stationery',    5, 20),
(5,  '2026-01-02', 'Emeka',  'West',  102, 'Phone',      'Electronics', 500, 1),
-- Jan 3 (2 orders)
(6,  '2026-01-03', 'Ngozi',  'East',  201, 'Desk',       'Furniture',   250, 1),
(7,  '2026-01-03', 'Tunde',  'North', 302, 'Pen Pack',   'Stationery',   10, 10),
-- Jan 4 (3 orders)
(8,  '2026-01-04', 'Ada',    'East',  103, 'Headphones', 'Electronics', 100, 1),
(9,  '2026-01-04', 'Fatima', 'West',  101, 'Laptop',     'Electronics', 800, 1),
(10, '2026-01-04', 'Kemi',   'North', 202, 'Chair',      'Furniture',   150, 1),
-- Jan 5 (2 orders)
(11, '2026-01-05', 'Bola',   'West',  301, 'Notebook',   'Stationery',    5, 50),
(12, '2026-01-05', 'Chidi',  'East',  102, 'Phone',      'Electronics', 500, 2),
-- Jan 6: NO ORDERS (gap on purpose, useful for RANGE demos)
-- Jan 7 (3 orders)
(13, '2026-01-07', 'Dayo',   'North', 201, 'Desk',       'Furniture',   250, 2),
(14, '2026-01-07', 'Emeka',  'West',  103, 'Headphones', 'Electronics', 100, 3),
(15, '2026-01-07', 'Ngozi',  'East',  302, 'Pen Pack',   'Stationery',   10, 25),
-- Jan 8 (2 orders)
(16, '2026-01-08', 'Tunde',  'North', 101, 'Laptop',     'Electronics', 800, 1),
(17, '2026-01-08', 'Fatima', 'West',  202, 'Chair',      'Furniture',   150, 3),
-- Jan 9 (3 orders)
(18, '2026-01-09', 'Kemi',   'North', 102, 'Phone',      'Electronics', 500, 1),
(19, '2026-01-09', 'Ada',    'East',  301, 'Notebook',   'Stationery',    5, 30),
(20, '2026-01-09', 'Bola',   'West',  201, 'Desk',       'Furniture',   250, 1),
-- Jan 10 (2 orders)
(21, '2026-01-10', 'Chidi',  'East',  101, 'Laptop',     'Electronics', 800, 2),
(22, '2026-01-10', 'Dayo',   'North', 103, 'Headphones', 'Electronics', 100, 2),
-- Jan 11: NO ORDERS (another gap)
-- Jan 12 (3 orders)
(23, '2026-01-12', 'Emeka',  'West',  302, 'Pen Pack',   'Stationery',   10, 40),
(24, '2026-01-12', 'Ngozi',  'East',  202, 'Chair',      'Furniture',   150, 1),
(25, '2026-01-12', 'Tunde',  'North', 102, 'Phone',      'Electronics', 500, 2),
-- Jan 13 (2 orders)
(26, '2026-01-13', 'Fatima', 'West',  201, 'Desk',       'Furniture',   250, 3),
(27, '2026-01-13', 'Kemi',   'North', 301, 'Notebook',   'Stationery',    5, 100),
-- Jan 14 (3 orders)
(28, '2026-01-14', 'Ada',    'East',  101, 'Laptop',     'Electronics', 800, 1),
(29, '2026-01-14', 'Bola',   'West',  103, 'Headphones', 'Electronics', 100, 4),
(30, '2026-01-14', 'Chidi',  'East',  202, 'Chair',      'Furniture',   150, 2);


-- =====================================================
-- ALTER orders: add customer details
-- Run this AFTER orders.sql has created and filled the table
-- =====================================================
 
-- 1. Add the new columns (nullable first so existing rows are allowed)
ALTER TABLE orders
    ADD COLUMN customer_id        INT,
    ADD COLUMN customer_full_name TEXT,
    ADD COLUMN customer_email     TEXT,
    ADD COLUMN customer_city      TEXT,
    ADD COLUMN customer_segment   TEXT;      -- Retail / Business
 
-- 2. Backfill existing rows, matching on the existing customer_name (first name)
UPDATE orders o
SET customer_id        = c.customer_id,
    customer_full_name = c.full_name,
    customer_email     = c.email,
    customer_city      = c.city,
    customer_segment   = c.segment
FROM (VALUES
    (1001, 'Ada',    'Ada Okafor',     'ada.okafor@example.com',     'Lagos',         'Retail'),
    (1002, 'Bola',   'Bola Adeyemi',   'bola.adeyemi@example.com',   'Ibadan',        'Business'),
    (1003, 'Chidi',  'Chidi Eze',      'chidi.eze@example.com',      'Enugu',         'Retail'),
    (1004, 'Dayo',   'Dayo Bello',     'dayo.bello@example.com',     'Kano',          'Business'),
    (1005, 'Emeka',  'Emeka Nwosu',    'emeka.nwosu@example.com',    'Port Harcourt', 'Retail'),
    (1006, 'Fatima', 'Fatima Abubakar','fatima.abubakar@example.com','Abuja',         'Business'),
    (1007, 'Kemi',   'Kemi Balogun',   'kemi.balogun@example.com',   'Kaduna',        'Retail'),
    (1008, 'Ngozi',  'Ngozi Obi',      'ngozi.obi@example.com',      'Onitsha',       'Retail'),
    (1009, 'Tunde',  'Tunde Alabi',    'tunde.alabi@example.com',    'Jos',           'Business')
) AS c(customer_id, first_name, full_name, email, city, segment)
WHERE o.customer_name = c.first_name;
 
-- 3. Lock it down now that every row is filled
ALTER TABLE orders
    ALTER COLUMN customer_id        SET NOT NULL,
    ALTER COLUMN customer_full_name SET NOT NULL;
 
-- 4. Optional but recommended: index for joins, filters and PARTITION BY customer_id
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
 