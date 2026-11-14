-- Active: 1754303878390@@127.0.0.1@5433@postgres@public
SELECT * FROM orders
lIMIT 5;

-- Why do we need window functions? Let's say we want to find the total sale for each product. We can do this using a simple GROUP BY query:

-- Find Total Sale for each product
    -- Result Granularity: Product Level, the number of rows in the result set will be equal to the number of unique products in the orders table.
SELECT 
    product_name, 
    SUM(amount) AS total_sale
FROM orders
GROUP BY product_name;

-- Find Total Sales across all Orders
    -- Result Granularity: Single Row, the number of rows in the result set will be equal to 1.
    -- So you can use a window function to find the total sale for each product, while still keeping the granularity of the result set at the order level.
    -- So no PARTITION BY Clause, so all rows in the result set will be considered as a single partition.

SELECT 
    order_id, 
    order_date,
    product_name,
    amount,
    SUM(amount) OVER () AS total_sale
FROM orders;

-- Find Total Sale for each product, but add additional columns to the result set, such as the order_id and order_date. We can do this using a window function:
    -- Result Granularity: Order Level, the number of rows in the result set will be equal to the number of rows in the orders table.
SELECT 
    order_id, 
    order_date,
    product_name,
    amount,
    SUM(amount) OVER (PARTITION BY product_name) AS total_sale
FROM orders;

-- Find Total Sales for each combination of product and order date, but add additional columns to the result set, such as the order_id. We can do this using a window function:
    -- Result Granularity: Order Level, the number of rows in the result set will be equal to the number of rows in the orders table.
SELECT 
    order_id,
    order_date,
    product_name,
    amount,
    SUM(amount) OVER (PARTITION BY product_name, order_date) AS total_sale
FROM orders;

-- Rank Window Function: The RANK() function is a window function that assigns a rank to each row within a partition of a result set. The rank of a row is one plus the number of ranks that come before it. If two rows have the same rank, they will receive the same rank value, and the next rank value will be skipped.
-- Find the rank of each order based on the amount, partitioned by product_name and ordered by amount in descending order. This will give us the rank of each order within each product category based on the amount.
    -- Result Granularity: Order Level, the number of rows in the result set will be equal to the number of rows in the orders table.
SELECT 
    order_id,
    order_date,
    product_name,
    amount,
    RANK() OVER (ORDER BY amount DESC) AS rank
FROM orders;

SELECT 
    order_id,
    order_date,
    product_name,
    amount,
    RANK() OVER (PARTITION BY product_name ORDER BY amount DESC) AS rank
FROM orders;

-- WINDOW FUNCTION FULL SYNTAX
/*
FUNCTION_NAME ( [ ALL | DISTINCT ] expression ) 
    OVER ( [ PARTITION BY partition_expression ] [ ORDER BY order_expression [ ASC | DESC ] ] [ ROWS frame_specification ] )

Window Functions are divided into 3:
1. Aggregate Window Functions: These functions perform a calculation on a set of values and return a single value. Examples include SUM(), AVG(), COUNT(), MIN(), MAX().
  - COUNT() is a special case of aggregate window function that can be used to count the number of rows in a partition, regardless of whether the rows contain NULL values or not.
  - And it can take all Data Types as input, unlike the other aggregate functions which have more restrictive input requirements only as numeric.
2. Ranking Window Functions: These functions assign a rank to each row within a partition of a
    result set. Examples include RANK(), DENSE_RANK(), ROW_NUMBER(), PERCENT_RANK(), CUME_DIST(), NTILE().
3. Value Window Functions(Anlaytical Window Functions): These functions return a value for each row in the result set based on the values of other rows in the same partition. Examples include LEAD(), LAG(), FIRST_VALUE(), LAST_VALUE(), NTH_VALUE().

Note:
1. - Aggregate Window Functions can be used with or without a PARTITION BY clause. 
If the PARTITION BY clause is omitted, the function will be applied to the entire result set. If the PARTITION BY clause is included, 
the function will be applied to each partition of the result set.
2. - Ranking Window Functions assign a rank to each row within a partition of the result set.
And it always requires an ORDER BY clause  and takes no extra parameters to determine the order of the rows within each partition.
Only NTILE() Takes a numeric parameter to determine the number of buckets to divide the partition into.

Whats a Frame:
- A frame is a subset of rows within a partition that is used to calculate the value of a window function for a specific row.
Its the set of rows allowed to be seen or considered when computing the value of a window function for a specific row. 
The frame is defined by the frame specification, which can be specified using the ROWS or RANGE clause in the OVER() clause of the window function.
Frame Types: 
    1. ROWS: The ROWS clause defines the frame in terms of physical offsets from the current row. 
        It allows you to specify a range of rows based on their position relative to the current row.
    2. RANGE: The RANGE clause defines the frame in terms of logical offsets from the current row. 
        It allows you to specify a range of rows based on their values relative to the current row.
Frame Boundarys:
    1. UNBOUNDED PRECEDING: This boundary indicates that the frame starts from the first row of the partition.
    2. UNBOUNDED FOLLOWING: This boundary indicates that the frame ends at the last row of the partition.
    3. CURRENT ROW: This boundary indicates that the frame starts or ends at the current row.
    4. n PRECEDING: This boundary indicates that the frame starts or ends n rows before the current row.
    5. n FOLLOWING: This boundary indicates that the frame starts or ends n rows after the current row.

Rules of Window Functions:
1. Window functions are applied after the WHERE clause and before the ORDER BY clause in a SQL query.
2. Window functions do not reduce the number of rows returned by a query. Instead, they add additional columns to the result set based on the calculations performed by the window function.
3. Frame clause can only be used together with Order By clause.
4. The start cant be after the end, and the end cant be before the start. The frame must be a valid range of rows within the partition.
    e.g BETWEEN CURRENT ROW AND 1 PRECEDING is invalid, because the start is after the end.
5. Window Functions can't be used in a WHERE clause, because the WHERE clause is applied before the window functions are calculated. 
Instead, you can use a subquery or a Common Table Expression (CTE) to filter the results based on the values calculated by the window function.
Or in DataWAREHOUSE, you can use a QUALIFY clause to filter the results based on the values calculated by the window function.
6. Window Function can be used with Group By clause, but the window function will be applied after the grouping is done, and it will operate on the grouped result set.
*/

-- Rank Customers based on their total sales, partitioned by product_name and ordered by total sales in descending order. This will give us the rank of each customer within each product category based on their total sales.
    -- Result Granularity: Customer Level, the number of rows in the result set will be equal to the number of unique customers in the orders table.
SELECT
    customer_id,
    product_name,
    SUM(amount) AS total_sales,
    RANK() OVER (PARTITION BY product_name ORDER BY SUM(amount) DESC) AS rank
FROM orders
GROUP BY customer_id, product_name;

-- Rank Customers based on their total sales 
SELECT
    customer_id,
    SUM(amount) AS total_sales,
    RANK() OVER (ORDER BY SUM(amount) DESC) AS rank 
FROM orders
GROUP BY customer_id;

-- Find the percentage contribution of each product's sales to the total sales across all products, partitioned by product_name and ordered by total sales in descending order. This will give us the percentage contribution of each product's sales to the total sales across all products.
    -- Result Granularity: Product Level, the number of rows in the result set will be equal to the number of unique products in the orders table.
SELECT product_name,
       SUM(amount) AS product_sales,
       ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 2) AS pct_of_total
FROM orders
GROUP BY product_name
ORDER BY pct_of_total DESC;

WITH prod AS (
    SELECT product_name, SUM(amount) AS product_sales
    FROM orders 
    GROUP BY product_name
)
SELECT product_name,
       product_sales,
       ROUND(100.0 * product_sales / SUM(product_sales) OVER (), 2) AS pct_of_total
FROM prod
ORDER BY pct_of_total DESC;

WITH daily AS (
    SELECT order_date, SUM(amount) AS daily_sales
    FROM orders
    GROUP BY order_date
)
SELECT order_date, daily_sales,
       ROUND(AVG(daily_sales) OVER (
           ORDER BY order_date
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS ma_3_rows,
       ROUND(AVG(daily_sales) OVER (
           ORDER BY order_date
           RANGE BETWEEN INTERVAL '2 days' PRECEDING AND CURRENT ROW
       ), 2) AS ma_3_days
FROM daily;