--  List All Orders for a Given Customer
SELECT 
    o.order_id,
    o.order_date,
    o.total_amount,
    COALESCE(SUM(od.quantity), 0) AS total_items
FROM orders o
LEFT JOIN order_details od ON o.order_id = od.order_id
WHERE o.customer_id = 1   -- Replace with customer_id as needed
GROUP BY o.order_id, o.order_date, o.total_amount
ORDER BY o.order_date DESC;


-- Products Below Reorder Level
SELECT 
    product_id,
    product_name,
    stock_quantity,
    reorder_level
FROM products
WHERE stock_quantity < reorder_level
ORDER BY stock_quantity ASC;


-- Show Total Spend Per Customer
SELECT 
    c.customer_id,
    c.customer_name,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;


-- Categorize Customers by Spending
-- Gold: total_spent ≥ 1000
-- Silver: total_spent ≥ 500 and < 1000
-- Bronze: total_spent < 500
SELECT 
    c.customer_id,
    c.customer_name,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    CASE
        WHEN COALESCE(SUM(o.total_amount), 0) >= 1000 THEN 'Gold'
        WHEN COALESCE(SUM(o.total_amount), 0) >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS spending_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC;


-- Bulk Discount Logic
SELECT
    o.order_id,
    o.customer_id,
    c.customer_name,
    o.order_date,
    SUM(od.quantity) AS total_items,
    o.total_amount,
    -- Bulk discount logic:
    CASE
        WHEN SUM(od.quantity) >= 10 THEN 'Bulk Discount'
        ELSE 'No Discount'
    END AS discount_status,
    CASE
        WHEN SUM(od.quantity) >= 10 THEN 0.10   -- 10% discount
        ELSE 0.00
    END AS discount_rate,
    o.total_amount * 
        CASE
            WHEN SUM(od.quantity) >= 10 THEN 0.10
            ELSE 0.00
        END AS discount_value,
    o.total_amount - 
        (o.total_amount * 
            CASE
                WHEN SUM(od.quantity) >= 10 THEN 0.10
                ELSE 0.00
            END
        ) AS discounted_total
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY o.order_id, o.customer_id, c.customer_name, o.order_date, o.total_amount
ORDER BY o.order_date DESC;


