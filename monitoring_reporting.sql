--  Customer Order Summaries
CREATE OR REPLACE FUNCTION fn_customer_order_summary(p_customer_id INT)
RETURNS TABLE (
    order_id INT, 
    order_date TIMESTAMPTZ, 
    total_amount DECIMAL(10,2), 
    total_items BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.order_id,
        o.order_date,
        o.total_amount,
        COALESCE(SUM(od.quantity), 0) AS total_items
    FROM orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    WHERE o.customer_id = p_customer_id
    GROUP BY o.order_id, o.order_date, o.total_amount
    ORDER BY o.order_date DESC;
END;
$$ LANGUAGE plpgsql;

-- USAGE
SELECT * FROM fn_customer_order_summary(1);

-- SELECT 
--     o.order_id,
--     o.order_date,
--     o.total_amount,
--     COALESCE(SUM(od.quantity), 0) AS total_items
-- FROM orders o
-- LEFT JOIN order_details od ON o.order_id = od.order_id
-- WHERE o.customer_id = 1   -- Replace with customer_id as needed
-- GROUP BY o.order_id, o.order_date, o.total_amount
-- ORDER BY o.order_date DESC;


-- Low Stock Product Report
CREATE OR REPLACE FUNCTION fn_low_stock_report()
RETURNS TABLE (
    product_id INT,
    product_name VARCHAR(255),
    stock_quantity INT,
    reorder_level INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.product_id,
        p.product_name,
        p.stock_quantity,
        p.reorder_level
    FROM products p
    WHERE p.stock_quantity < p.reorder_level
    ORDER BY p.stock_quantity ASC;
END;
$$ LANGUAGE plpgsql;

-- USAGE
SELECT * FROM fn_low_stock_report();

-- SELECT 
--     product_id,
--     product_name,
--     stock_quantity,
--     reorder_level
-- FROM products
-- WHERE stock_quantity < reorder_level
-- ORDER BY stock_quantity ASC;


-- Customer Spending Summary
CREATE OR REPLACE FUNCTION fn_customer_spending_summary()
RETURNS TABLE (
    customer_id INT,
    customer_name VARCHAR(255),
    total_spent DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.customer_id,
        c.customer_name,
        COALESCE(SUM(o.total_amount), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
    ORDER BY total_spent DESC;
END;
$$ LANGUAGE plpgsql;

-- USAGE
SELECT * FROM fn_customer_spending_summary();

-- SELECT 
--     c.customer_id,
--     c.customer_name,
--     COALESCE(SUM(o.total_amount), 0) AS total_spent
-- FROM customers c
-- LEFT JOIN orders o ON c.customer_id = o.customer_id
-- GROUP BY c.customer_id, c.customer_name
-- ORDER BY total_spent DESC;


-- Customer Spending Tier
CREATE OR REPLACE FUNCTION fn_customer_spending_tiers(
    p_gold_threshold DECIMAL = 1000,
    p_silver_threshold DECIMAL = 500
)
RETURNS TABLE (
    customer_id INT,
    customer_name VARCHAR(255),
    total_spent DECIMAL(10,2),
    spending_tier VARCHAR(10)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.customer_id,
        c.customer_name,
        COALESCE(SUM(o.total_amount), 0) AS total_spent,
        CASE
            WHEN COALESCE(SUM(o.total_amount), 0) >= p_gold_threshold THEN 'Gold'
            WHEN COALESCE(SUM(o.total_amount), 0) >= p_silver_threshold THEN 'Silver'
            ELSE 'Bronze'
        END AS spending_tier
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
    ORDER BY total_spent DESC;
END;
$$ LANGUAGE plpgsql;

-- USAGE
-- With default thresholds
SELECT * FROM fn_customer_spending_tiers();

-- Or with custom thresholds
SELECT * FROM fn_customer_spending_tiers(1500, 750);


-- SELECT 
--     c.customer_id,
--     c.customer_name,
--     COALESCE(SUM(o.total_amount), 0) AS total_spent,
--     CASE
--         WHEN COALESCE(SUM(o.total_amount), 0) >= 1000 THEN 'Gold'
--         WHEN COALESCE(SUM(o.total_amount), 0) >= 500 THEN 'Silver'
--         ELSE 'Bronze'
--     END AS spending_tier
-- FROM customers c
-- LEFT JOIN orders o ON c.customer_id = o.customer_id
-- GROUP BY c.customer_id, c.customer_name
-- ORDER BY total_spent DESC;


-- -- Bulk Discount Logic
-- SELECT
--     o.order_id,
--     o.customer_id,
--     c.customer_name,
--     o.order_date,
--     SUM(od.quantity) AS total_items,
--     o.total_amount,
--     -- Bulk discount logic:
--     CASE
--         WHEN SUM(od.quantity) >= 10 THEN 'Bulk Discount'
--         ELSE 'No Discount'
--     END AS discount_status,
--     CASE
--         WHEN SUM(od.quantity) >= 10 THEN 0.10   -- 10% discount
--         ELSE 0.00
--     END AS discount_rate,
--     o.total_amount * 
--         CASE
--             WHEN SUM(od.quantity) >= 10 THEN 0.10
--             ELSE 0.00
--         END AS discount_value,
--     o.total_amount - 
--         (o.total_amount * 
--             CASE
--                 WHEN SUM(od.quantity) >= 10 THEN 0.10
--                 ELSE 0.00
--             END
--         ) AS discounted_total
-- FROM orders o
-- JOIN order_details od ON o.order_id = od.order_id
-- JOIN customers c ON o.customer_id = c.customer_id
-- GROUP BY o.order_id, o.customer_id, c.customer_name, o.order_date, o.total_amount
-- ORDER BY o.order_date DESC;


