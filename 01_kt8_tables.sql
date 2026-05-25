ALTER TABLE client
ADD COLUMN IF NOT EXISTS client_code VARCHAR(20);

UPDATE client
SET client_code = CASE
    WHEN id = 1 THEN 'IvanovII'
    WHEN id = 2 THEN 'PetrovAA'
    ELSE 'Client_' || id
END
WHERE client_code IS NULL;

ALTER TABLE client
ALTER COLUMN client_code SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'uq_client_client_code'
    ) THEN
        ALTER TABLE client
        ADD CONSTRAINT uq_client_client_code UNIQUE (client_code);
    END IF;
END;
$$;

ALTER TABLE orders
ADD COLUMN IF NOT EXISTS order_number VARCHAR(20);

UPDATE orders
SET order_number = 'ЗКЗ-' || LPAD(id::text, 9, '0') || '-23'
WHERE order_number IS NULL;

ALTER TABLE orders
ALTER COLUMN order_number SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'uq_orders_order_number'
    ) THEN
        ALTER TABLE orders
        ADD CONSTRAINT uq_orders_order_number UNIQUE (order_number);
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS ingredient (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS menu_ingredient (
    menu_id INT NOT NULL REFERENCES menu(id) ON DELETE CASCADE,
    ingredient_id INT NOT NULL REFERENCES ingredient(id),
    PRIMARY KEY (menu_id, ingredient_id)
);

CREATE INDEX IF NOT EXISTS index_ingredient_name
ON ingredient(name);

CREATE INDEX IF NOT EXISTS index_menu_ingredient_menu_id
ON menu_ingredient(menu_id);

CREATE INDEX IF NOT EXISTS index_menu_ingredient_ingredient_id
ON menu_ingredient(ingredient_id);