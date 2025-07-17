"1.Como desarrollador, quiero un procedimiento que registre una calificación y actualice el promedio del producto."

DELIMITER //

CREATE PROCEDURE RegistrarCalificacionYActualizarPromedio(
    IN p_product_id INT,
    IN p_customer_id INT,
    IN p_rating DECIMAL(3, 1)
)
BEGIN
    DECLARE v_company_id VARCHAR(10);
    DECLARE v_poll_id INT;
    DECLARE v_new_average_rating DECIMAL(3, 1);

    SELECT company_id INTO v_company_id
    FROM companyproducts
    WHERE product_id = p_product_id
    LIMIT 1;

    IF v_company_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El producto no está asociado a ninguna empresa';
    END IF;

    SET v_poll_id = 2;

    INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
    VALUES (p_product_id, p_customer_id, v_poll_id, v_company_id, NOW(), p_rating);

    SELECT AVG(rating) INTO v_new_average_rating
    FROM quality_products
    WHERE product_id = p_product_id;

    UPDATE products
    SET average_rating = v_new_average_rating
    WHERE id = p_product_id;

END //

DELIMITER ;

"2.Como administrador, deseo un procedimiento para insertar una empresa y asociar productos por defecto."

CREATE PROCEDURE InsertarEmpresaYAsociarProductosPorDefecto(
    IN p_name VARCHAR(255),
    IN p_nit VARCHAR(50),
    IN p_cellphone VARCHAR(20),
    IN p_email VARCHAR(255),
    IN p_address VARCHAR(255),
    IN p_city_id INT,
    IN p_company_type_id INT,
    IN p_isactivate TINYINT
)
BEGIN
    DECLARE v_new_company_id VARCHAR(10);
    DECLARE v_next_company_num INT;

    START TRANSACTION;

    SELECT
        CAST(SUBSTRING(MAX(id), 5) AS UNSIGNED) + 1
    INTO v_next_company_num
    FROM companies
    WHERE
        id LIKE 'COMP%';

    IF v_next_company_num IS NULL THEN
        SET v_next_company_num = 1;
    END IF;

    SET v_new_company_id = CONCAT('COMP', LPAD(v_next_company_num, 3, '0'));

    INSERT INTO companies (id, name, nit, cellphone, email, address, city_id, company_type_id, isactivate)
    VALUES (v_new_company_id, p_name, p_nit, p_cellphone, p_email, p_address, p_city_id, p_company_type_id, p_isactivate);

    INSERT INTO companyproducts (company_id, product_id, unitmeasure_id, price) VALUES
    (v_new_company_id, 1, 1, 25.99),
    (v_new_company_id, 2, 2, 3.50),
    (v_new_company_id, 3, 1, 5.99),
    (v_new_company_id, 6, 1, 599.99),
    (v_new_company_id, 7, 3, 15.50);

    COMMIT;

END //

"3.Como cliente, quiero un procedimiento que añada un producto favorito y verifique duplicados."

DELIMITER //

CREATE PROCEDURE AnadirFavoritoValidandoDuplicados(
    IN p_customer_id INT,
    IN p_company_id VARCHAR(10)
)
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*)
    INTO v_count
    FROM favorites
    WHERE customer_id = p_customer_id AND company_id = p_company_id;

    IF v_count = 0 THEN
        INSERT INTO favorites (customer_id, company_id)
        VALUES (p_customer_id, p_company_id);
    END IF;

END //

DELIMITER ;


"4.Como gestor, deseo un procedimiento que genere un resumen mensual de calificaciones por empresa."

DELIMITER //

CREATE PROCEDURE GenerarResumenMensualCalificacionesEmpresa(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    DECLARE v_summary_date DATE;

    SET v_summary_date = STR_TO_DATE(CONCAT(p_year, '-', p_month, '-01'), '%Y-%m-%d');

    INSERT INTO summary_company_ratings_monthly (company_id, summary_date, average_rating, total_ratings_count)
    SELECT
        qp.company_id,
        v_summary_date,
        AVG(qp.rating),
        COUNT(qp.rating)
    FROM
        quality_products AS qp
    WHERE
        YEAR(qp.daterating) = p_year AND MONTH(qp.daterating) = p_month
    GROUP BY
        qp.company_id
    ON DUPLICATE KEY UPDATE
        average_rating = VALUES(average_rating),
        total_ratings_count = VALUES(total_ratings_count);

END //

DELIMITER ;

"5.Como supervisor, quiero un procedimiento que calcule beneficios activos por membresía."

DELIMITER //

CREATE PROCEDURE CalcularBeneficiosActivosPorMembresia(
    IN p_fecha_actual DATE
)
BEGIN
    SELECT
        m.id AS ID_Membresia,
        m.name AS Nombre_Membresia,
        COUNT(DISTINCT mb.benefit_id) AS Total_Beneficios_Activos
    FROM
        memberships AS m
    JOIN
        membershipbenefits AS mb ON m.id = mb.membership_id
    JOIN
        membershipperiods AS mp ON m.id = mp.membership_id
    JOIN
        periods AS p ON mp.period_id = p.id
    WHERE
        p_fecha_actual BETWEEN p.start_date AND p.end_date
    GROUP BY
        m.id,
        m.name
    ORDER BY
        Total_Beneficios_Activos DESC,
        m.name;
END //

DELIMITER ;

"6.Como técnico, deseo un procedimiento que elimine productos sin calificación ni empresa asociada."

DELIMITER //

CREATE PROCEDURE EliminarProductosHuerfanos()
BEGIN
    DELETE FROM products
    WHERE id NOT IN (
        SELECT DISTINCT product_id
        FROM quality_products
    )
    AND id NOT IN (
        SELECT DISTINCT product_id
        FROM companyproducts
    );
END //

DELIMITER ;

"7.Como operador, quiero un procedimiento que actualice precios de productos por categoría."

DELIMITER //

CREATE PROCEDURE ActualizarPreciosProductosPorCategoria(
    IN p_category_id INT,
    IN p_factor DECIMAL(5, 2)
)
BEGIN
    UPDATE companyproducts AS cp
    JOIN products AS p
        ON cp.product_id = p.id
    SET
        cp.price = cp.price * p_factor
    WHERE
        p.category_id = p_category_id;
END //

"8.Como auditor, deseo un procedimiento que liste inconsistencias entre rates y quality_products."
DELIMITER //

CREATE PROCEDURE ValidarInconsistenciasCalificaciones()
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
        'Producto inexistente',
        'quality_products',
        qp.product_id,
        CONCAT('La calificación con ID de producto ', qp.product_id, ' no tiene un producto correspondiente en la tabla products.')
    FROM quality_products AS qp
    LEFT JOIN products AS p ON qp.product_id = p.id
    WHERE p.id IS NULL;

    INSERT INTO errores_log (error_type, table_name, record_id, description)
    SELECT
        'Cliente inexistente',
        'quality_products',
        qp.customer_id,
        CONCAT('La calificación con ID de cliente ', qp.customer_id, ' no tiene un cliente correspondiente en la tabla customers.')
    FROM quality_products AS qp
    LEFT JOIN customers AS c ON qp.customer_id = c.id
    WHERE c.id IS NULL;

    INSERT INTO errores_log (error_type, table_name, record_id, description)
    SELECT
        'Empresa inexistente',
        'quality_products',
        qp.company_id,
        CONCAT('La calificación con ID de empresa ', qp.company_id, ' no tiene una empresa correspondiente en la tabla companies.')
    FROM quality_products AS qp
    LEFT JOIN companies AS comp ON qp.company_id = comp.id
    WHERE comp.id IS NULL;

    INSERT INTO errores_log (error_type, table_name, record_id, description)
    SELECT
        'Encuesta inexistente',
        'quality_products',
        qp.poll_id,
        CONCAT('La calificación con ID de encuesta ', qp.poll_id, ' no tiene una encuesta correspondiente en la tabla polls.')
    FROM quality_products AS qp
    LEFT JOIN polls AS po ON qp.poll_id = po.id
    WHERE po.id IS NULL;

END //

DELIMITER ;


"9.Como desarrollador, quiero un procedimiento que asigne beneficios a nuevas audiencias."

DELIMITER //

CREATE PROCEDURE AsignarBeneficiosANuevasAudiencias(
    IN p_benefit_id INT,
    IN p_audience_id INT
)
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*)
    INTO v_count
    FROM audiencebenefits
    WHERE benefit_id = p_benefit_id AND audience_id = p_audience_id;

    IF v_count = 0 THEN
        INSERT INTO audiencebenefits (benefit_id, audience_id)
        VALUES (p_benefit_id, p_audience_id);
    END IF;

END //

DELIMITER ;

"10.Como administrador, deseo un procedimiento que active planes de membresía vencidos si el pago fue confirmado."

DELIMITER //

CREATE PROCEDURE ActivarPlanesMembresiaVencidosConPagoConfirmado()
BEGIN
    UPDATE membershipperiods
    SET
        status = 'ACTIVA'
    WHERE
        end_date < CURDATE() -- El plan ha vencido (fecha de fin es anterior a hoy)
        AND pago_confirmado = TRUE; -- El pago ha sido confirmado
END //

DELIMITER ;

"11.Como cliente, deseo un procedimiento que me devuelva todos mis productos favoritos con su promedio de rating."

DELIMITER //

CREATE PROCEDURE ListarFavoritosConCalificacion(
    IN p_customer_id INT
)
BEGIN
    SELECT
        p.id AS ID_Producto,
        p.name AS Nombre_Producto,
        comp.name AS Empresa_Favorita,
        AVG(qp.rating) AS Promedio_Calificacion_Producto
    FROM
        customers AS c
    JOIN
        favorites AS f ON c.id = f.customer_id
    JOIN
        companies AS comp ON f.company_id = comp.id
    JOIN
        companyproducts AS cp ON comp.id = cp.company_id
    JOIN
        products AS p ON cp.product_id = p.id
    LEFT JOIN
        quality_products AS qp ON p.id = qp.product_id AND comp.id = qp.company_id
    WHERE
        c.id = p_customer_id
    GROUP BY
        p.id,
        p.name,
        comp.name
    ORDER BY
        Promedio_Calificacion_Producto DESC,
        p.name;
END //

"12.Como gestor, quiero un procedimiento que registre una encuesta y sus preguntas asociadas."

DELIMITER //

CREATE PROCEDURE RegistrarEncuestaYPreguntasAsociadas(
    IN p_poll_description VARCHAR(255),
    IN p_question1_text TEXT,
    IN p_question2_text TEXT,
    IN p_question3_text TEXT
)
BEGIN
    DECLARE v_new_poll_id INT;

    INSERT INTO polls (description)
    VALUES (p_poll_description);

    SET v_new_poll_id = LAST_INSERT_ID();

    IF p_question1_text IS NOT NULL THEN
        INSERT INTO poll_questions (poll_id, question_text)
        VALUES (v_new_poll_id, p_question1_text);
    END IF;

    IF p_question2_text IS NOT NULL THEN
        INSERT INTO poll_questions (poll_id, question_text)
        VALUES (v_new_poll_id, p_question2_text);
    END IF;

    IF p_question3_text IS NOT NULL THEN
        INSERT INTO poll_questions (poll_id, question_text)
        VALUES (v_new_poll_id, p_question3_text);
    END IF;

END //

"13.Como técnico, deseo un procedimiento que borre favoritos antiguos no calificados en más de un año."

DELIMITER //

CREATE PROCEDURE EliminarFavoritosAntiguosSinCalificaciones()
BEGIN
    DELETE FROM favorites
    WHERE company_id IN (
        SELECT
            c.id 
        FROM
            companies AS c
        LEFT JOIN 
            quality_products AS qp ON c.id = qp.company_id
            AND qp.daterating >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR) 
        GROUP BY
            c.id
        HAVING
            COUNT(qp.product_id) = 0 
    );
END //

DELIMITER ;

"14.Como operador, quiero un procedimiento que asocie automáticamente beneficios por audiencia."

DELIMITER //

CREATE PROCEDURE AsociarBeneficiosAutomaticamentePorAudiencia(
    IN p_audience_id INT
)
BEGIN
    IF p_audience_id = 1 THEN
        IF NOT EXISTS (SELECT 1 FROM audiencebenefits WHERE audience_id = p_audience_id AND benefit_id = 1) THEN
            INSERT INTO audiencebenefits (audience_id, benefit_id) VALUES (p_audience_id, 1);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM audiencebenefits WHERE audience_id = p_audience_id AND benefit_id = 2) THEN
            INSERT INTO audiencebenefits (audience_id, benefit_id) VALUES (p_audience_id, 2);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM audiencebenefits WHERE audience_id = p_audience_id AND benefit_id = 3) THEN
            INSERT INTO audiencebenefits (audience_id, benefit_id) VALUES (p_audience_id, 3);
        END IF;
    ELSEIF p_audience_id = 2 THEN
        IF NOT EXISTS (SELECT 1 FROM audiencebenefits WHERE audience_id = p_audience_id AND benefit_id = 2) THEN
            INSERT INTO audiencebenefits (audience_id, benefit_id) VALUES (p_audience_id, 2);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM audiencebenefits WHERE audience_id = p_audience_id AND benefit_id = 4) THEN
            INSERT INTO audiencebenefits (audience_id, benefit_id) VALUES (p_audience_id, 4);
        END IF;
    ELSEIF p_audience_id = 3 THEN
        IF NOT EXISTS (SELECT 1 FROM audiencebenefits WHERE audience_id = p_audience_id AND benefit_id = 1) THEN
            INSERT INTO audiencebenefits (audience_id, benefit_id) VALUES (p_audience_id, 1);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM audiencebenefits WHERE audience_id = p_audience_id AND benefit_id = 5) THEN
            INSERT INTO audiencebenefits (audience_id, benefit_id) VALUES (p_audience_id, 5);
        END IF;
    END IF;

END //

DELIMITER ;

"15.Como administrador, deseo un procedimiento para generar un historial de cambios de precio."

DELIMITER //

CREATE PROCEDURE GenerarHistorialCambiosPrecio(
    IN p_product_id INT,
    IN p_company_id VARCHAR(10),
    IN p_new_price DECIMAL(10, 2)
)
BEGIN
    DECLARE v_current_price DECIMAL(10, 2);

    SELECT price INTO v_current_price
    FROM companyproducts
    WHERE product_id = p_product_id AND company_id = p_company_id;

    IF v_current_price IS NOT NULL AND v_current_price <> p_new_price THEN
        INSERT INTO price_history (product_id, company_id, old_price, new_price, change_date)
        VALUES (p_product_id, p_company_id, v_current_price, p_new_price, NOW());

        UPDATE companyproducts
        SET price = p_new_price
        WHERE product_id = p_product_id AND company_id = p_company_id;
    ELSEIF v_current_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El producto no está asociado a la empresa especificada.';
    END IF;

END //

DELIMITER ;

"16.Como desarrollador, quiero un procedimiento que registre automáticamente una nueva encuesta activa."

DELIMITER //

CREATE PROCEDURE RegistrarEncuestaActivaAutomaticamente(
    IN p_description VARCHAR(255)
)
BEGIN
    INSERT INTO polls (description, status, start_date)
    VALUES (p_description, 'activa', NOW());
END //

DELIMITER ;

"17.Como técnico, deseo un procedimiento que actualice la unidad de medida de productos sin afectar si hay ventas."

DELIMITER //

CREATE PROCEDURE ActualizarUnidadMedidaSinAfectarVentas(
    IN p_product_id INT,
    IN p_company_id VARCHAR(10),
    IN p_new_unitmeasure_id INT
)
BEGIN
    DECLARE v_has_been_rated INT;

    SELECT COUNT(*)
    INTO v_has_been_rated
    FROM quality_products
    WHERE product_id = p_product_id AND company_id = p_company_id;

    IF v_has_been_rated = 0 THEN
        UPDATE companyproducts
        SET unitmeasure_id = p_new_unitmeasure_id
        WHERE product_id = p_product_id AND company_id = p_company_id;
    END IF;

END //

DELIMITER ;

"18.Como supervisor, quiero un procedimiento que recalcule todos los promedios de calidad cada semana."

DELIMITER //

CREATE PROCEDURE RecalcularPromediosCalidadSemanalmente()
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

"19.Como auditor, deseo un procedimiento que valide claves foráneas cruzadas entre calificaciones y encuestas."

DELIMITER //

CREATE PROCEDURE ValidarClavesForaneasCalificacionesEncuestas()
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
        'Inconsistencia FK',
        'quality_products',
        qp.poll_id,
        CONCAT('El poll_id ', qp.poll_id, ' en quality_products no tiene una entrada correspondiente en la tabla polls.')
    FROM quality_products AS qp
    LEFT JOIN polls AS p ON qp.poll_id = p.id
    WHERE p.id IS NULL;

END //

DELIMITER ;

"20.Como gerente, quiero un procedimiento que genere el top 10 de productos más calificados por ciudad."

DELIMITER //

CREATE PROCEDURE GenerarTop10ProductosMasCalificadosPorCiudad()
BEGIN
    SET @rn = 0;
    SET @prev_city = NULL;

    SELECT
        RankedProducts.ID_Ciudad,
        RankedProducts.Nombre_Ciudad,
        RankedProducts.ID_Producto,
        RankedProducts.Nombre_Producto,
        RankedProducts.Total_Calificaciones
    FROM (
        SELECT
            ci.id AS ID_Ciudad,
            ci.name AS Nombre_Ciudad,
            p.id AS ID_Producto,
            p.name AS Nombre_Producto,
            COUNT(qp.product_id) AS Total_Calificaciones,
            @rn := IF(@prev_city = ci.id, @rn + 1, 1) AS row_num,
            @prev_city := ci.id
        FROM
            citiesormunicipalities AS ci
        JOIN
            companies AS comp ON ci.id = comp.city_id
        JOIN
            companyproducts AS cp ON comp.id = cp.company_id
        JOIN
            products AS p ON cp.product_id = p.id
        JOIN
            quality_products AS qp ON p.id = qp.product_id AND comp.id = qp.company_id
        GROUP BY
            ci.id, ci.name, p.id, p.name
        ORDER BY
            ci.id, Total_Calificaciones DESC
    ) AS RankedProducts
    WHERE RankedProducts.row_num <= 10;
END //

DELIMITER ;