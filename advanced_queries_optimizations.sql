-- Order Summary
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.total_amount,
    COALESCE(SUM(od.quantity), 0) AS total_items
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_id, c.customer_name, o.order_date, o.total_amount;

SELECT * FROM vw_order_summary ORDER BY order_date DESC;




-- Low Stock Report

CREATE OR REPLACE VIEW vw_low_stock_products AS
SELECT
    product_id,
    product_name,
    category,
    stock_quantity,
    reorder_level
FROM products
WHERE stock_quantity < reorder_level;

SELECT * FROM vw_low_stock_products;




Retrieve Latest Orders (via View):
SELECT * FROM vw_order_summary ORDER BY order_date DESC LIMIT 10;

Retrieve All Products Needing Replenishment (via View):
SELECT * FROM vw_low_stock_products;

