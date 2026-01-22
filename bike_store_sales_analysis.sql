
--  1. SALES VIEW (CORE CALCULATION LAYER) --

CREATE OR REPLACE VIEW vw_sales AS
SELECT
    o.order_id,
    o.order_date,
    oi.product_id,
    o.store_id,
    oi.quantity,
    oi.list_price,
    oi.discount,
    (oi.quantity * oi.list_price * (1 - oi.discount)) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id;


 -- 2. Overall KPIs
 -- Total Revenue across all orders

SELECT
    ROUND(SUM(revenue), 2) AS total_revenue
FROM vw_sales;


-- Total number of distinct orders
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM vw_sales;


-- Average Order Value (AOV)
-- Indicates average customer spend per transaction

SELECT
    ROUND(
        SUM(revenue) / COUNT(DISTINCT order_id),
        2
    ) AS average_order_value
FROM vw_sales;


-- 3. REVENUE BY STORE

SELECT
    s.store_name,
    ROUND(SUM(v.revenue), 2) AS total_revenue
FROM vw_sales v
JOIN stores s
    ON v.store_id = s.store_id
GROUP BY s.store_name
ORDER BY total_revenue DESC;

-- 4. REVENUE BY CATEGORY
SELECT
    c.category_name,
    ROUND(SUM(v.revenue), 2) AS total_revenue
FROM vw_sales v
JOIN products p
    ON v.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_revenue DESC;


--  5. TOP 10 PRODUCTS BY REVENUE
SELECT
    p.product_name,
    ROUND(SUM(v.revenue), 2) AS total_revenue
FROM vw_sales v
JOIN products p
    ON v.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;


-- 6. REVENUE PER UNIT SOLD (ADVANCED PRICING METRIC)

SELECT
    c.category_name,
    ROUND(
        SUM(v.revenue) / NULLIF(SUM(v.quantity), 0),
        2
    ) AS revenue_per_unit
FROM vw_sales v
JOIN products p
    ON v.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY revenue_per_unit DESC;



-- 7. LOW-STOCK, HIGH-PERFORMING PRODUCTS (INVENTORY RISK)
SELECT
    s.store_name,
    p.product_name,
    ROUND(SUM(v.revenue), 2) AS total_revenue,
    st.quantity AS stock_quantity,
    CASE
        WHEN st.quantity <= 20 THEN 'Low Stock'
        ELSE 'OK'
    END AS inventory_flag
FROM vw_sales v
JOIN products p
    ON v.product_id = p.product_id
JOIN stores s
    ON v.store_id = s.store_id
JOIN stocks st
    ON p.product_id = st.product_id
   AND s.store_id = st.store_id
GROUP BY
    s.store_name,
    p.product_name,
    st.quantity
ORDER BY total_revenue DESC;

-- 8. PIVOT SOURCE DATA (EXCEL INTEGRATION)

SELECT
    o.order_id,
    o.order_date,
    s.store_name,
    c.category_name,
    p.product_name,
    oi.quantity,
    ROUND(
        oi.quantity * oi.list_price * (1 - oi.discount),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
JOIN stores s
    ON o.store_id = s.store_id;
