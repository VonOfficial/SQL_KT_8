-- Тестовый сценарий 1: ввод существующего стола
-- Результат: пройден

CREATE OR REPLACE PROCEDURE restaurant_table_insert(
    p_table_number VARCHAR(10),
    p_seats_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM restaurant_table
        WHERE table_number = p_table_number
    ) THEN
        RAISE NOTICE 'Указанный стол уже есть в таблице!';
    ELSE
        INSERT INTO restaurant_table (table_number, seats_count)
        VALUES (p_table_number, p_seats_count);

        RAISE NOTICE 'Стол успешно добавлен.';
    END IF;
END;
$$;

CALL restaurant_table_insert('Д2', 4);


-- Тестовый сценарий 2: автоматическое формирование номера бронирования
-- Результат: пройден

CREATE OR REPLACE PROCEDURE reservation_insert_auto(
    p_created_at TIMESTAMP,
    p_table_number VARCHAR(10),
    p_client_code VARCHAR(20),
    p_planned_visit_at TIMESTAMP,
    p_guests_count INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_client_id INT;
    v_table_id INT;
    v_table_capacity INT;
    v_year TEXT;
    v_next_number INT;
    v_reservation_number VARCHAR(20);
    v_reservation_id INT;
BEGIN
    SELECT id
    INTO v_client_id
    FROM client
    WHERE client_code = p_client_code;

    IF v_client_id IS NULL THEN
        RAISE NOTICE 'Указанный клиент не найден!';
        RETURN;
    END IF;

    SELECT id, seats_count
    INTO v_table_id, v_table_capacity
    FROM restaurant_table
    WHERE table_number = p_table_number;

    IF v_table_id IS NULL THEN
        RAISE NOTICE 'Указанный стол не найден!';
        RETURN;
    END IF;

    IF p_guests_count < 1 THEN
        RAISE NOTICE 'Количество гостей должно быть не меньше 1!';
        RETURN;
    END IF;

    IF p_guests_count > v_table_capacity THEN
        RAISE NOTICE 'Количество гостей превышает вместимость выбранного стола!';
        RETURN;
    END IF;

    IF p_planned_visit_at < p_created_at THEN
        RAISE NOTICE 'Дата посещения не может быть раньше даты создания брони!';
        RETURN;
    END IF;

    v_year := TO_CHAR(p_created_at, 'YY');

    SELECT COALESCE(MAX(SUBSTRING(reservation_number FROM 7 FOR 10)::INT), 0) + 1
    INTO v_next_number
    FROM reservation
    WHERE reservation_number LIKE 'БР/' || v_year || '/%';

    v_reservation_number := 'БР/' || v_year || '/' || LPAD(v_next_number::TEXT, 10, '0');

    INSERT INTO reservation (
        reservation_number,
        client_id,
        created_at,
        planned_visit_at,
        guests_count,
        status
    )
    VALUES (
        v_reservation_number,
        v_client_id,
        p_created_at,
        p_planned_visit_at,
        p_guests_count,
        'active'
    )
    RETURNING id INTO v_reservation_id;

    INSERT INTO reservation_tables (reservation_id, table_id)
    VALUES (v_reservation_id, v_table_id);

    RAISE NOTICE 'Сформирован номер бронирования: %', v_reservation_number;
END;
$$;

CALL reservation_insert_auto(
    '2024-03-01 10:10:10',
    'ОБ2',
    'IvanovII',
    '2024-03-02 11:11:00',
    1
);


-- Тестовый сценарий 3: удаление ингредиента, который используется в блюде
-- Результат: пройден

CREATE OR REPLACE PROCEDURE ingredient_delete(
    p_ingredient_name VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ingredient_id INT;
    v_count INT;
BEGIN
    SELECT id
    INTO v_ingredient_id
    FROM ingredient
    WHERE name = p_ingredient_name;

    IF v_ingredient_id IS NULL THEN
        RAISE NOTICE 'Указанный ингредиент не найден!';
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM menu_ingredient
    WHERE ingredient_id = v_ingredient_id;

    IF v_count > 0 THEN
        RAISE NOTICE 'Выбранный ингредиент невозможно удалить, так как к нему привязано блюдо.';
    ELSE
        DELETE FROM ingredient
        WHERE id = v_ingredient_id;

        RAISE NOTICE 'Ингредиент удалён.';
    END IF;
END;
$$;

CALL ingredient_delete('Перец');


-- Тестовый сценарий 4: повторное добавление ингредиента к блюду
-- Результат: пройден

CREATE OR REPLACE PROCEDURE menu_ingredient_insert(
    p_menu_name VARCHAR(100),
    p_ingredient_name VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_menu_id INT;
    v_ingredient_id INT;
BEGIN
    SELECT id
    INTO v_menu_id
    FROM menu
    WHERE name = p_menu_name;

    IF v_menu_id IS NULL THEN
        RAISE NOTICE 'Указанное блюдо не найдено!';
        RETURN;
    END IF;

    SELECT id
    INTO v_ingredient_id
    FROM ingredient
    WHERE name = p_ingredient_name;

    IF v_ingredient_id IS NULL THEN
        RAISE NOTICE 'Указанный ингредиент не найден!';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM menu_ingredient
        WHERE menu_id = v_menu_id
          AND ingredient_id = v_ingredient_id
    ) THEN
        RAISE NOTICE 'Указанный ингредиент уже есть у указанного блюда.';
    ELSE
        INSERT INTO menu_ingredient (menu_id, ingredient_id)
        VALUES (v_menu_id, v_ingredient_id);

        RAISE NOTICE 'Ингредиент добавлен к блюду.';
    END IF;
END;
$$;

CALL menu_ingredient_insert('Суп мечты', 'Огурцы');


-- Тестовый сценарий 5: перерасчёт стоимости заказа
-- Результат: пройден

CREATE OR REPLACE PROCEDURE order_add_item_recalc(
    p_order_number VARCHAR(20),
    p_menu_name VARCHAR(100),
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INT;
    v_menu_id INT;
    v_price NUMERIC(10,2);
    v_total NUMERIC(10,2);
BEGIN
    SELECT id
    INTO v_order_id
    FROM orders
    WHERE order_number = p_order_number;

    IF v_order_id IS NULL THEN
        RAISE NOTICE 'Указанный заказ не найден!';
        RETURN;
    END IF;

    SELECT id, price
    INTO v_menu_id, v_price
    FROM menu
    WHERE name = p_menu_name;

    IF v_menu_id IS NULL THEN
        RAISE NOTICE 'Указанное блюдо не найдено!';
        RETURN;
    END IF;

    IF p_quantity < 1 THEN
        RAISE NOTICE 'Количество позиции должно быть больше 0!';
        RETURN;
    END IF;

    INSERT INTO order_items (order_id, menu_id, quantity, item_price)
    VALUES (v_order_id, v_menu_id, p_quantity, v_price);

    SELECT COALESCE(SUM(quantity * item_price), 0)
    INTO v_total
    FROM order_items
    WHERE order_id = v_order_id;

    UPDATE orders
    SET total_price = v_total
    WHERE id = v_order_id;

    RAISE NOTICE 'Итоговая стоимость заказа: % р.', v_total;
END;
$$;

DELETE FROM order_items
WHERE order_id = (
    SELECT id
    FROM orders
    WHERE order_number = 'ЗКЗ-000000001-23'
);

UPDATE orders
SET total_price = 0
WHERE order_number = 'ЗКЗ-000000001-23';

CALL order_add_item_recalc(
    'ЗКЗ-000000001-23',
    'Как бы здоровое питание',
    1
);


-- Дополнительная процедура 1: отмена бронирования
-- Результат проверки: пройден

CREATE OR REPLACE PROCEDURE reservation_cancel(
    p_reservation_number VARCHAR(20),
    p_cancelled_at TIMESTAMP
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_planned_visit_at TIMESTAMP;
BEGIN
    SELECT planned_visit_at
    INTO v_planned_visit_at
    FROM reservation
    WHERE reservation_number = p_reservation_number;

    IF v_planned_visit_at IS NULL THEN
        RAISE NOTICE 'Указанное бронирование не найдено!';
        RETURN;
    END IF;

    IF p_cancelled_at > v_planned_visit_at - INTERVAL '1 day' THEN
        RAISE NOTICE 'Бронь можно отменить не менее чем за сутки до посещения!';
        RETURN;
    END IF;

    UPDATE reservation
    SET cancelled_at = p_cancelled_at,
        status = 'cancelled'
    WHERE reservation_number = p_reservation_number;

    RAISE NOTICE 'Бронирование отменено.';
END;
$$;


-- Дополнительная процедура 2: добавление блюда в предварительное меню
-- Результат проверки: пройден

CREATE OR REPLACE PROCEDURE reservation_item_insert(
    p_reservation_number VARCHAR(20),
    p_menu_name VARCHAR(100),
    p_quantity INT,
    p_serve_time TIME
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_reservation_id INT;
    v_visit_time TIME;
    v_menu_id INT;
BEGIN
    SELECT id, planned_visit_at::TIME
    INTO v_reservation_id, v_visit_time
    FROM reservation
    WHERE reservation_number = p_reservation_number;

    IF v_reservation_id IS NULL THEN
        RAISE NOTICE 'Указанное бронирование не найдено!';
        RETURN;
    END IF;

    SELECT id
    INTO v_menu_id
    FROM menu
    WHERE name = p_menu_name;

    IF v_menu_id IS NULL THEN
        RAISE NOTICE 'Указанное блюдо не найдено!';
        RETURN;
    END IF;

    IF p_quantity < 1 THEN
        RAISE NOTICE 'Количество блюда должно быть больше 0!';
        RETURN;
    END IF;

    IF p_serve_time < v_visit_time THEN
        RAISE NOTICE 'Время подачи блюда не может быть раньше времени посещения!';
        RETURN;
    END IF;

    INSERT INTO reservation_items (
        reservation_id,
        menu_id,
        quantity,
        serve_time
    )
    VALUES (
        v_reservation_id,
        v_menu_id,
        p_quantity,
        p_serve_time
    );

    RAISE NOTICE 'Блюдо добавлено в предварительное меню.';
END;
$$;