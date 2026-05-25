DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'restaurant_admin') THEN
        CREATE ROLE restaurant_admin;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'restaurant_manager') THEN
        CREATE ROLE restaurant_manager;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'restaurant_waiter') THEN
        CREATE ROLE restaurant_waiter;
    END IF;
END;
$$;

GRANT USAGE ON SCHEMA public TO restaurant_admin;
GRANT USAGE ON SCHEMA public TO restaurant_manager;
GRANT USAGE ON SCHEMA public TO restaurant_waiter;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public
TO restaurant_admin;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public
TO restaurant_admin;

GRANT SELECT, INSERT, UPDATE ON restaurant_table TO restaurant_manager;
GRANT SELECT, INSERT, UPDATE ON reservation TO restaurant_manager;
GRANT SELECT, INSERT, UPDATE ON reservation_tables TO restaurant_manager;
GRANT SELECT, INSERT, UPDATE ON reservation_items TO restaurant_manager;

GRANT SELECT ON client TO restaurant_manager;
GRANT SELECT ON menu TO restaurant_manager;

GRANT SELECT, INSERT, UPDATE ON orders TO restaurant_manager;
GRANT SELECT, INSERT, UPDATE ON order_items TO restaurant_manager;

GRANT SELECT ON ingredient TO restaurant_manager;
GRANT SELECT ON menu_ingredient TO restaurant_manager;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public
TO restaurant_manager;

GRANT SELECT ON client TO restaurant_waiter;
GRANT SELECT ON menu TO restaurant_waiter;
GRANT SELECT ON orders TO restaurant_waiter;
GRANT SELECT ON order_items TO restaurant_waiter;

GRANT SELECT ON restaurant_table TO restaurant_waiter;
GRANT SELECT ON reservation TO restaurant_waiter;
GRANT SELECT ON reservation_tables TO restaurant_waiter;
GRANT SELECT ON reservation_items TO restaurant_waiter;

GRANT EXECUTE ON PROCEDURE restaurant_table_insert(VARCHAR, INT)
TO restaurant_admin, restaurant_manager;

GRANT EXECUTE ON PROCEDURE reservation_insert_auto(TIMESTAMP, VARCHAR, VARCHAR, TIMESTAMP, INT)
TO restaurant_admin, restaurant_manager;

GRANT EXECUTE ON PROCEDURE ingredient_delete(VARCHAR)
TO restaurant_admin;

GRANT EXECUTE ON PROCEDURE menu_ingredient_insert(VARCHAR, VARCHAR)
TO restaurant_admin, restaurant_manager;

GRANT EXECUTE ON PROCEDURE order_add_item_recalc(VARCHAR, VARCHAR, INT)
TO restaurant_admin, restaurant_manager;

GRANT EXECUTE ON PROCEDURE reservation_cancel(VARCHAR, TIMESTAMP)
TO restaurant_admin, restaurant_manager;

GRANT EXECUTE ON PROCEDURE reservation_item_insert(VARCHAR, VARCHAR, INT, TIME)
TO restaurant_admin, restaurant_manager;