-- Start a transaction
BEGIN;

-- 1. Create the order (customer_id = 1)
INSERT INTO orders (customer_id, total_amount)
VALUES (1, 0)
RETURNING order_id;

-- Example output: order_id = 1

-- 2. Insert order details and update stock for each product

-- Product 1: Wireless Keyboard (product_id = 1, quantity = 2)
INSERT INTO order_details (order_id, product_id, quantity, price)
SELECT 1, 1, 2,  49.99 FROM products WHERE product_id = 1;

UPDATE products
SET stock_quantity = stock_quantity - 2
WHERE product_id = 1;

-- Log inventory change for product 1
INSERT INTO inventory_logs (product_id, change_amount, new_stock_quantity, change_type)
SELECT 1, -2, stock_quantity, 'order' FROM products WHERE product_id = 1;

-- Product 2: Noise-Cancelling Headphones (product_id = 2, quantity = 1)
INSERT INTO order_details (order_id, product_id, quantity, price)
SELECT 1, 2, 1, 199.99 FROM products WHERE product_id = 2;

UPDATE products
SET stock_quantity = stock_quantity - 1
WHERE product_id = 2;

-- Log inventory change for product 2
INSERT INTO inventory_logs (product_id, change_amount, new_stock_quantity, change_type)
SELECT 2, -1, stock_quantity, 'order' FROM products WHERE product_id = 2;

-- 3. Calculate and update the order total
UPDATE orders
SET total_amount = (
    SELECT SUM(quantity * price) 
    FROM order_details 
    WHERE order_id = 1
)
WHERE order_id = 1;

-- Commit the transaction
COMMIT;



-- AUTOMATION WITH STORED PROCEDURES
CREATE OR REPLACE PROCEDURE place_order(
    p_customer_id INT,  -- Renamed parameter to avoid ambiguity
    product_quantities JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;     -- Changed variable name to v_order_id
    item JSONB;
BEGIN
    -- Start transaction
    BEGIN
        -- Create the order (use parameter p_customer_id)
        INSERT INTO orders (customer_id, total_amount)
        VALUES (p_customer_id, 0)
        RETURNING order_id INTO v_order_id;  -- Use renamed variable

        -- Process each product in the order
        FOR item IN SELECT * FROM jsonb_array_elements(product_quantities)
        LOOP
            -- Insert order details using v_order_id
            INSERT INTO order_details (order_id, product_id, quantity, price)
            SELECT 
                v_order_id, 
                (item->>'product_id')::INT, 
                (item->>'quantity')::INT, 
                price 
            FROM products 
            WHERE product_id = (item->>'product_id')::INT;

            -- Update product stock
            UPDATE products
            SET stock_quantity = stock_quantity - (item->>'quantity')::INT
            WHERE product_id = (item->>'product_id')::INT;

            -- Log inventory change
            INSERT INTO inventory_logs (product_id, change_amount, new_stock_quantity, change_type)
            SELECT 
                (item->>'product_id')::INT,
                -(item->>'quantity')::INT,
                stock_quantity,
                'order'
            FROM products 
            WHERE product_id = (item->>'product_id')::INT;
        END LOOP;

        -- Update order total using v_order_id
        UPDATE orders
        SET total_amount = (
            SELECT SUM(quantity * price)
            FROM order_details
            WHERE order_id = v_order_id
        )
        WHERE order_id = v_order_id;

        -- Commit transaction
        COMMIT;
    EXCEPTION
        WHEN others THEN
            ROLLBACK;
            RAISE;
    END;
END;
$$;


CALL place_order(
    2,  -- Customer ID (Bob Smith)
    '[{"product_id": 1, "quantity": 3}, {"product_id": 3, "quantity": 5}]'::JSONB
);




-- without explicit begin , commit and rollback

CREATE OR REPLACE PROCEDURE place_order(
    p_customer_id INT,
    product_quantities JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
    item JSONB;
BEGIN
    -- Create the order
    INSERT INTO orders (customer_id, total_amount)
    VALUES (p_customer_id, 0)
    RETURNING order_id INTO v_order_id;

    -- Process each product in the order
    FOR item IN SELECT * FROM jsonb_array_elements(product_quantities)
    LOOP
        INSERT INTO order_details (order_id, product_id, quantity, price)
        SELECT 
            v_order_id, 
            (item->>'product_id')::INT, 
            (item->>'quantity')::INT, 
            price 
        FROM products 
        WHERE product_id = (item->>'product_id')::INT;

        UPDATE products
        SET stock_quantity = stock_quantity - (item->>'quantity')::INT
        WHERE product_id = (item->>'product_id')::INT;

        INSERT INTO inventory_logs (product_id, change_amount, new_stock_quantity, change_type)
        SELECT 
            (item->>'product_id')::INT,
            -(item->>'quantity')::INT,
            stock_quantity,
            'order'
        FROM products 
        WHERE product_id = (item->>'product_id')::INT;
    END LOOP;

    -- Update order total
    UPDATE orders
    SET total_amount = (
        SELECT SUM(quantity * price)
        FROM order_details
        WHERE order_id = v_order_id
    )
    WHERE order_id = v_order_id;
END;
$$;
