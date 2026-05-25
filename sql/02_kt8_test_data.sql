INSERT INTO client (client_code, full_name, passport, card_number)
VALUES
('IvanovII', 'Иванов Иван Иванович', 'AB1234567', '1111222233334444'),
('PetrovAA', 'Петров Петр Петрович', 'CD7654321', '5555666677778888')
ON CONFLICT (client_code) DO NOTHING;

INSERT INTO waiter (full_name)
SELECT 'Сидоров Алексей'
WHERE NOT EXISTS (
    SELECT 1
    FROM waiter
    WHERE full_name = 'Сидоров Алексей'
);

INSERT INTO restaurant_table (table_number, seats_count)
VALUES
('Д2', 4),
('ОБ2', 4)
ON CONFLICT (table_number) DO NOTHING;

INSERT INTO menu (name, price)
VALUES
('Суп мечты', 8.50),
('Как бы здоровое питание', 3990.00)
ON CONFLICT (name) DO NOTHING;

INSERT INTO ingredient (name)
VALUES
('Перец'),
('Огурцы')
ON CONFLICT (name) DO NOTHING;

INSERT INTO menu_ingredient (menu_id, ingredient_id)
SELECT m.id, i.id
FROM menu m
JOIN ingredient i ON i.name = 'Перец'
WHERE m.name = 'Суп мечты'
ON CONFLICT DO NOTHING;

INSERT INTO menu_ingredient (menu_id, ingredient_id)
SELECT m.id, i.id
FROM menu m
JOIN ingredient i ON i.name = 'Огурцы'
WHERE m.name = 'Суп мечты'
ON CONFLICT DO NOTHING;

INSERT INTO orders (client_id, waiter_id, order_time, total_price, order_number)
SELECT c.id, w.id, CURRENT_TIMESTAMP, 0, 'ЗКЗ-000000001-23'
FROM client c
CROSS JOIN waiter w
WHERE c.client_code = 'IvanovII'
  AND w.full_name = 'Сидоров Алексей'
  AND NOT EXISTS (
      SELECT 1
      FROM orders
      WHERE order_number = 'ЗКЗ-000000001-23'
  );

DELETE FROM order_items
WHERE order_id = (
    SELECT id
    FROM orders
    WHERE order_number = 'ЗКЗ-000000001-23'
);

UPDATE orders
SET total_price = 0
WHERE order_number = 'ЗКЗ-000000001-23';