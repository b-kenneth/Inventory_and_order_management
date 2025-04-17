-- Automated Stock replenishment
CREATE OR REPLACE FUNCTION auto_replenish_stock()
RETURNS TRIGGER AS $$
DECLARE
    v_replenish_amount INT := 100; -- Default amount to replenish, could be made dynamic
BEGIN
    -- Check if stock has fallen below reorder level
    IF NEW.stock_quantity < NEW.reorder_level THEN
        -- Update the stock (without triggering the other logging trigger again)
        NEW.stock_quantity := NEW.stock_quantity + v_replenish_amount;
        
        -- Log the replenishment directly
        INSERT INTO inventory_logs (
            product_id, 
            change_amount, 
            new_stock_quantity, 
            change_type
        ) VALUES (
            NEW.product_id,
            v_replenish_amount,
            NEW.stock_quantity,
            'replenish'
        );
        
        -- Optional: Log activity for monitoring
        RAISE NOTICE 'Auto-replenished product ID % with % units', NEW.product_id, v_replenish_amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_replenish
BEFORE UPDATE OF stock_quantity ON products
FOR EACH ROW
WHEN (NEW.stock_quantity < NEW.reorder_level)
EXECUTE FUNCTION auto_replenish_stock();


-- Update Inventory logs
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


-- ** did calculating the total amount for an order already in order procedure

-- Function (Your Current Approach)
-- Advantage: Calculates tiers dynamically when needed

-- Advantage: Always reflects the latest order data

-- Disadvantage: Recalculates every time, which could affect performance with large datasets

-- Procedure (Storing Tiers)
-- Advantage: Calculates once and stores the result (better performance for lookups)

-- Advantage: Makes tier information immediately available to other parts of the system

-- Disadvantage: Requires periodic updates to stay current

-- Decision Criteria
-- You should stick with just your function (and not add the procedure) if:

-- You only need tier information for reports and analytics

-- Real-time accuracy is critical for your business rules

-- Your customer/order volume is relatively small