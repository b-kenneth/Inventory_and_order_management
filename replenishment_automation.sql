-- Stock below reorder level
SELECT 
    product_id, 
    product_name, 
    stock_quantity, 
    reorder_level
FROM products
WHERE stock_quantity < reorder_level;

-- Replenish and Log the change
-- 1. Update the stock quantity
UPDATE products
SET stock_quantity = stock_quantity + 100
WHERE product_id = 1;

-- 2. Log the replenishment in inventory_logs
INSERT INTO inventory_logs (product_id, change_amount, new_stock_quantity, change_type)
SELECT 
    1,
    100,
    stock_quantity,
    'replenish'
FROM products
WHERE product_id = 1;


-- Automate
CREATE OR REPLACE FUNCTION log_inventory_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if the stock level actually changes
    IF NEW.stock_quantity <> OLD.stock_quantity THEN
        INSERT INTO inventory_logs (product_id, change_amount, new_stock_quantity, change_type)
        VALUES (
            NEW.product_id,
            NEW.stock_quantity - OLD.stock_quantity,
            NEW.stock_quantity,
            'adjustment'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inventory_log
AFTER UPDATE OF stock_quantity ON products
FOR EACH ROW
EXECUTE FUNCTION log_inventory_change();


--Test
SELECT * FROM products WHERE product_id = 1;

-- Update stock quantity directly
-- UPDATE products
UPDATE products
SET stock_quantity = stock_quantity + 7
WHERE product_id = 1;


-- Examine the inventory log
-- SELECT *
FROM inventory_logs
WHERE product_id = 1
ORDER BY log_timestamp DESC
LIMIT 5;



-- Categorize customers based on their spending habits
-- Run this regularly or use in reporting
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
GROUP BY c.customer_id, c.customer_name;


-- ** did calculating the total amount for an order already in order procedure