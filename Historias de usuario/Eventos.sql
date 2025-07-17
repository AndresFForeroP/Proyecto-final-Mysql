'1.Historia: Como administrador, quiero un evento que borre productos sin actividad cada 6 meses.'

DELIMITER //

CREATE EVENT event_delete_inactive_products
ON SCHEDULE EVERY 6 MONTH
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM products
    WHERE id NOT IN (SELECT DISTINCT product_id FROM quality_products)
    AND id NOT IN (SELECT DISTINCT product_id FROM favorites)
    AND id NOT IN (SELECT DISTINCT product_id FROM companyproducts);

END //

DELIMITER ;

'2.Historia: Como supervisor, deseo un evento semanal que recalcula el promedio de calificaciones.'

DELIMITER //

CREATE EVENT event_recalculate_weekly_average_ratings
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE products AS p
    SET average_rating = (
        SELECT AVG(qp.rating)
        FROM quality_products AS qp
        WHERE qp.product_id = p.id
    )
    WHERE EXISTS (
        SELECT 1
        FROM quality_products AS qp
        WHERE qp.product_id = p.id
    );
END //

DELIMITER ;

'3.Historia: Como operador, quiero un evento mensual que actualice los precios de productos por inflación.'

DELIMITER //
CREATE EVENT event_update_prices_monthly_inflation
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE companyproducts
    SET price = price * 1.03;
END //

DELIMITER ;

'4.Historia: Como auditor, deseo un evento que genere un backup lógico cada medianoche.'

DELIMITER //

CREATE EVENT event_daily_logical_backup
ON SCHEDULE EVERY 1 DAY
STARTS '2025-07-17 00:00:00'
DO
BEGIN
    TRUNCATE TABLE products_backup;
    TRUNCATE TABLE quality_products_backup;
    TRUNCATE TABLE favorites_backup;
    TRUNCATE TABLE companies_backup;
    TRUNCATE TABLE customers_backup;
    TRUNCATE TABLE polls_backup;
    TRUNCATE TABLE companyproducts_backup;
    TRUNCATE TABLE membershipbenefits_backup;
    TRUNCATE TABLE membershipperiods_backup;
    TRUNCATE TABLE audiencebenefits_backup;
    TRUNCATE TABLE price_history_backup;
    TRUNCATE TABLE log_acciones_backup;
    TRUNCATE TABLE log_encuestas_estado_backup;
    TRUNCATE TABLE summary_company_ratings_monthly_backup;
    INSERT INTO products_backup SELECT * FROM products;
    INSERT INTO quality_products_backup SELECT * FROM quality_products;
    INSERT INTO favorites_backup SELECT * FROM favorites;
    INSERT INTO companies_backup SELECT * FROM companies;
    INSERT INTO customers_backup SELECT * FROM customers;
    INSERT INTO polls_backup SELECT * FROM polls;
    INSERT INTO companyproducts_backup SELECT * FROM companyproducts;
    INSERT INTO membershipbenefits_backup SELECT * FROM membershipbenefits;
    INSERT INTO membershipperiods_backup SELECT * FROM membershipperiods;
    INSERT INTO audiencebenefits_backup SELECT * FROM audiencebenefits;
    INSERT INTO price_history_backup SELECT * FROM price_history;
    INSERT INTO log_acciones_backup SELECT * FROM log_acciones;
    INSERT INTO log_encuestas_estado_backup SELECT * FROM log_encuestas_estado;
    INSERT INTO summary_company_ratings_monthly_backup SELECT * FROM summary_company_ratings_monthly;

END //

DELIMITER ;

'5.Historia: Como cliente, quiero un evento que me recuerde los productos que tengo en favoritos y no he calificado.'

DELIMITER //

CREATE EVENT event_notify_unrated_favorite_products
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO user_reminders (customer_id, company_id, product_id, message)
    SELECT
        f.customer_id,
        cp.company_id,
        cp.product_id,
        CONCAT(
            '¡Recordatorio! El producto "', p.name,
            '" de tu empresa favorita "', c.name, '" aún no ha sido calificado por ti. ¡Tu opinión es importante!'
        )
    FROM
        favorites AS f
    JOIN
        companyproducts AS cp ON f.company_id = cp.company_id
    JOIN
        products AS p ON cp.product_id = p.id
    JOIN
        companies AS c ON cp.company_id = c.id
    LEFT JOIN
        quality_products AS qp ON f.customer_id = qp.customer_id
                                AND cp.product_id = qp.product_id
                                AND cp.company_id = qp.company_id
    WHERE
        qp.product_id IS NULL
        AND NOT EXISTS (
            SELECT 1
            FROM user_reminders AS ur
            WHERE ur.customer_id = f.customer_id
            AND ur.company_id = cp.company_id
            AND ur.product_id = cp.product_id
        );
END //

DELIMITER ;

'6.Historia: Como técnico, deseo un evento que revise inconsistencias entre empresas y productos cada domingo.'

DELIMITER //

CREATE EVENT event_check_company_product_inconsistencies
ON SCHEDULE EVERY 1 WEEK
ON SUNDAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS errores_log (
        id INT AUTO_INCREMENT PRIMARY KEY,
        error_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        error_type VARCHAR(100),
        table_name VARCHAR(100),
        record_id VARCHAR(255),
        description TEXT
    );

    INSERT INTO errores_log (error_type, table_name, record_id, description)
    SELECT
        'Producto sin empresa',
        'products',
        p.id,
        CONCAT('El producto ID ', p.id, ' (', p.name, ') no está asociado a ninguna empresa en companyproducts.')
    FROM products AS p
    LEFT JOIN companyproducts AS cp ON p.id = cp.product_id
    WHERE cp.product_id IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM errores_log
        WHERE error_type = 'Producto sin empresa'
        AND table_name = 'products'
        AND record_id = p.id
        AND DATE(error_timestamp) = CURDATE()
    );

    INSERT INTO errores_log (error_type, table_name, record_id, description)
    SELECT
        'Empresa sin productos',
        'companies',
        c.id,
        CONCAT('La empresa ID ', c.id, ' (', c.name, ') no tiene ningún producto asociado en companyproducts.')
    FROM companies AS c
    LEFT JOIN companyproducts AS cp ON c.id = cp.company_id
    WHERE cp.company_id IS NULL
    AND NOT EXISTS (
        SELECT 1 FROM errores_log
        WHERE error_type = 'Empresa sin productos'
        AND table_name = 'companies'
        AND record_id = c.id
        AND DATE(error_timestamp) = CURDATE()
    );

END //

DELIMITER ;

'7.Historia: Como administrador, quiero un evento que archive membresías vencidas.'

DELIMITER //

CREATE EVENT event_archive_expired_memberships
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE membershipperiods
    SET status = 'INACTIVA'
    WHERE end_date < CURDATE();
END //

DELIMITER ;

'8.Historia: Como supervisor, deseo un evento que notifique por correo sobre beneficios nuevos.'

DELIMITER //

CREATE EVENT event_notify_new_benefits_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO notifications (customer_id, benefit_id, message)
    SELECT
        c.id AS customer_id,
        b.id AS benefit_id,
        CONCAT('¡Nuevo beneficio disponible! Descubre "', b.name, '".') AS message
    FROM
        benefits AS b
    JOIN
        customers AS c ON c.isactivate = TRUE
    WHERE
        b.created_at >= NOW() - INTERVAL 7 DAY
        AND NOT EXISTS (
            SELECT 1
            FROM notifications AS n
            WHERE n.customer_id = c.id
            AND n.benefit_id = b.id
            AND n.created_at >= NOW() - INTERVAL 7 DAY
        );
END //

DELIMITER ;

'9.Historia: Como operador, quiero un evento que calcule el total de favoritos por cliente y lo guarde.'

DELIMITER //

CREATE EVENT event_calculate_monthly_favorites_per_customer
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS favoritos_resumen (
        customer_id INT NOT NULL,
        total_favorites INT NOT NULL,
        summary_month DATE NOT NULL,
        PRIMARY KEY (customer_id, summary_month)
    );

    INSERT INTO favoritos_resumen (customer_id, total_favorites, summary_month)
    SELECT
        f.customer_id,
        COUNT(f.company_id) AS total_favorites,
        DATE_FORMAT(CURDATE(), '%Y-%m-01') AS summary_month
    FROM
        favorites AS f
    GROUP BY
        f.customer_id
    ON DUPLICATE KEY UPDATE
        total_favorites = VALUES(total_favorites);
END //

DELIMITER ;


'10.Historia: Como auditor, deseo un evento que valide claves foráneas semanalmente y reporte errores.'

NO ME SALIO :c

'11.Historia: Como técnico, quiero un evento que elimine calificaciones con errores antiguos.'

DELIMITER //

CREATE EVENT event_delete_invalid_old_ratings
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM quality_products
    WHERE (rating IS NULL OR rating < 0)
    AND daterating < NOW() - INTERVAL 3 MONTH;
END //

DELIMITER ;

'12.Historia: Como desarrollador, deseo un evento que actualice encuestas que no se han usado en mucho tiempo.'

DELIMITER //

CREATE EVENT event_update_inactive_polls
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE polls AS p
    SET status = 'inactiva'
    WHERE p.status = 'activa'
    AND (
        p.id NOT IN (SELECT DISTINCT poll_id FROM quality_products)
        AND p.start_date < NOW() - INTERVAL 6 MONTH
    )
    OR (
        p.id IN (
            SELECT poll_id
            FROM quality_products
            GROUP BY poll_id
            HAVING MAX(daterating) < NOW() - INTERVAL 6 MONTH
        )
    );
END //

DELIMITER ;

'13.Historia: Como administrador, quiero un evento que inserte datos de auditoría periódicamente.'

NO ME SALIO 

'14.Historia: Como gestor, deseo un evento que notifique a las empresas sus métricas de calidad cada lunes.'

DELIMITER //

CREATE EVENT event_notify_company_quality_metrics
ON SCHEDULE EVERY 1 WEEK
ON MONDAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS notifications_empresa (
        id INT AUTO_INCREMENT PRIMARY KEY,
        company_id VARCHAR(10) NOT NULL,
        product_id INT,
        average_rating DECIMAL(3,1),
        message TEXT NOT NULL,
        notification_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY (company_id, product_id, DATE(notification_date))
    );

    INSERT INTO notifications_empresa (company_id, product_id, average_rating, message)
    SELECT
        c.id AS company_id,
        p.id AS product_id,
        AVG(qp.rating) AS average_rating,
        CONCAT(
            'Estimada empresa ', c.name, ',\n',
            'Su producto "', p.name, '" ha recibido un promedio de calificación de ',
            FORMAT(AVG(qp.rating), 1), ' esta semana. ¡Siga mejorando!'
        ) AS message
    FROM
        quality_products AS qp
    JOIN
        companies AS c ON qp.company_id = c.id
    JOIN
        products AS p ON qp.product_id = p.id
    WHERE
        qp.daterating >= CURDATE() - INTERVAL 7 DAY
    GROUP BY
        c.id, c.name, p.id, p.name
    ON DUPLICATE KEY UPDATE
        average_rating = VALUES(average_rating),
        message = VALUES(message),
        notification_date = VALUES(notification_date);

END //

DELIMITER ;

'15.Historia: Como cliente, quiero un evento que me recuerde renovar la membresía próxima a vencer.'

DELIMITER //

CREATE EVENT event_remind_membership_renewal
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    INSERT INTO user_reminders (customer_id, message, reminder_date)
    SELECT
        mp.customer_id,
        CONCAT(
            '¡Recordatorio! Tu membresía vence el ', DATE_FORMAT(mp.end_date, '%d/%m/%Y'),
            '. ¡Renueva ahora para no perder tus beneficios!'
        ) AS message,
        NOW() AS reminder_date
    FROM
        membershipperiods AS mp
    WHERE
        mp.status = 'ACTIVA'
        AND mp.end_date >= CURDATE()
        AND mp.end_date <= CURDATE() + INTERVAL 7 DAY
        AND NOT EXISTS (
            SELECT 1
            FROM user_reminders AS ur
            WHERE ur.customer_id = mp.customer_id
            AND ur.message LIKE CONCAT('%vence el ', DATE_FORMAT(mp.end_date, '%d/%m/%Y'), '%')
            AND ur.reminder_date >= CURDATE() - INTERVAL 7 DAY
        );
END //

DELIMITER ;

'16.Historia: Como operador, deseo un evento que reordene estadísticas generales.'

NO ME SALIO 

'17.Historia: Como técnico, quiero un evento que cree resúmenes temporales por categoría.'

DELIMITER //

CREATE EVENT event_create_temporary_category_summaries
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS category_usage_summary (
        category_id INT NOT NULL,
        category_name VARCHAR(255) NOT NULL,
        total_rated_products INT NOT NULL,
        summary_date DATE NOT NULL,
        PRIMARY KEY (category_id, summary_date)
    );

    INSERT INTO category_usage_summary (category_id, category_name, total_rated_products, summary_date)
    SELECT
        cat.id AS category_id,
        cat.name AS category_name,
        COUNT(DISTINCT qp.product_id) AS total_rated_products,
        CURDATE() AS summary_date
    FROM
        categories AS cat
    JOIN
        products AS p ON cat.id = p.category_id
    JOIN
        quality_products AS qp ON p.id = qp.product_id
    WHERE
        qp.daterating >= CURDATE() - INTERVAL 1 WEEK
    GROUP BY
        cat.id, cat.name
    ON DUPLICATE KEY UPDATE
        total_rated_products = VALUES(total_rated_products),
        summary_date = VALUES(summary_date);
END //

DELIMITER ;

'18.Historia: Como gerente, deseo un evento que desactive beneficios que ya expiraron.'

DELIMITER //

CREATE EVENT event_deactivate_expired_benefits
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE benefits
    SET isactivate = FALSE
    WHERE expires_at IS NOT NULL
    AND expires_at < CURDATE()
    AND isactivate = TRUE;
END //

DELIMITER ;

'19.Historia: Como auditor, quiero un evento que genere alertas sobre productos sin evaluación anual.'

DELIMITER //

CREATE EVENT event_alert_unrated_products_annually
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CREATE TABLE IF NOT EXISTS alertas_productos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        product_id INT NOT NULL,
        alert_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        message TEXT NOT NULL,
        UNIQUE KEY (product_id, DATE(alert_date)) -- Evita alertas duplicadas para el mismo producto en el mismo día
    );

    INSERT INTO alertas_productos (product_id, message)
    SELECT
        p.id AS product_id,
        CONCAT('Alerta: El producto "', p.name, '" no ha recibido ninguna evaluación en los últimos 365 días.') AS message
    FROM
        products AS p
    LEFT JOIN
        quality_products AS qp ON p.id = qp.product_id
    GROUP BY
        p.id, p.name
    HAVING
        MAX(qp.daterating) IS NULL OR MAX(qp.daterating) < NOW() - INTERVAL 365 DAY
    ON DUPLICATE KEY UPDATE
        alert_date = VALUES(alert_date),
        message = VALUES(message);
END //

DELIMITER ;

'20.Historia: Como administrador, deseo un evento que actualice precios según un índice referenciado.'

DELIMITER //

CREATE EVENT event_update_prices_with_external_index
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP 
DO
BEGIN
    DECLARE v_inflation_index DECIMAL(5,4);
    SELECT index_value
    INTO v_inflation_index
    FROM inflacion_indice
    ORDER BY index_date DESC
    LIMIT 1;
    IF v_inflation_index IS NOT NULL THEN
        UPDATE companyproducts
        SET price = price * v_inflation_index;
    END IF;
END //

DELIMITER ;
