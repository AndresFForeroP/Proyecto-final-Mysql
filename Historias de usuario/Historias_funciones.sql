'1.Explicación: Se desea una función calcular_promedio_ponderado(product_id) que combine el valor de rate y la antigüedad de cada calificación para dar más peso a calificaciones recientes.'

DELIMITER //

CREATE FUNCTION calcular_promedio_ponderado(p_product_id INT)
RETURNS DECIMAL(3,2)
READS SQL DATA
BEGIN
    DECLARE v_weighted_avg DECIMAL(3,2);

    SELECT
        SUM(qp.rating * (1 - (DATEDIFF(CURDATE(), qp.daterating) / 365.0))) / SUM(1 - (DATEDIFF(CURDATE(), qp.daterating) / 365.0))
    INTO
        v_weighted_avg
    FROM
        quality_products AS qp
    WHERE
        qp.product_id = p_product_id
        AND qp.daterating IS NOT NULL;

    RETURN v_weighted_avg;
END //

DELIMITER ;

'2.Explicación: Se busca una función booleana es_calificacion_reciente(fecha) que devuelva TRUE si la calificación se hizo en los últimos 30 días.'

DELIMITER //

CREATE FUNCTION es_calificacion_reciente(p_fecha DATE)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    RETURN (p_fecha >= CURDATE() - INTERVAL 30 DAY);
END //

DELIMITER ;

'3.Explicación: La función obtener_empresa_producto(product_id) haría un JOIN entre companyproducts y companies y devolvería el nombre de la empresa.'

DELIMITER //

CREATE FUNCTION obtener_empresa_producto(p_product_id INT)
RETURNS VARCHAR(255)
READS SQL DATA
BEGIN
    DECLARE v_company_name VARCHAR(255);

    SELECT
        c.name
    INTO
        v_company_name
    FROM
        companies AS c
    INNER JOIN
        companyproducts AS cp ON c.id = cp.company_id
    WHERE
        cp.product_id = p_product_id
    LIMIT 1;

    RETURN v_company_name;
END //

DELIMITER ;

'4.Explicación: tiene_membresia_activa(customer_id) consultaría la tabla membershipperiods para ese cliente y verificaría si la fecha actual está dentro del rango.'

DELIMITER //

CREATE FUNCTION tiene_membresia_activa(p_customer_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_has_active_membership BOOLEAN;

    SELECT
        COUNT(*) > 0
    INTO
        v_has_active_membership
    FROM
        membershipperiods
    WHERE
        customer_id = p_customer_id
        AND status = 'ACTIVA'
        AND CURDATE() BETWEEN start_date AND end_date;

    RETURN v_has_active_membership;
END //

DELIMITER ;

'5.Explicación: ciudad_supera_empresas(city_id, limite) devolvería TRUE si el conteo de empresas en esa ciudad excede limite.'

DELIMITER //

CREATE FUNCTION ciudad_supera_empresas(p_city_id INT, p_limite INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_company_count INT;

    SELECT
        COUNT(id)
    INTO
        v_company_count
    FROM
        companies
    WHERE
        city_id = p_city_id;

    RETURN (v_company_count > p_limite);
END //

DELIMITER ;

'6.Explicación: descripcion_calificacion(valor) devolvería “Excelente” si valor = 5, “Bueno” si valor = 4, etc.'

DELIMITER //

CREATE FUNCTION descripcion_calificacion(p_valor INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE v_description VARCHAR(50);

    CASE p_valor
        WHEN 5 THEN SET v_description = 'Excelente';
        WHEN 4 THEN SET v_description = 'Muy Bueno';
        WHEN 3 THEN SET v_description = 'Regular';
        WHEN 2 THEN SET v_description = 'Malo';
        WHEN 1 THEN SET v_description = 'Muy Malo';
        ELSE SET v_description = 'No Definido';
    END CASE;

    RETURN v_description;
END //

DELIMITER ;

'7.Explicación: estado_producto(product_id) clasificaría un producto como “Crítico”, “Aceptable” o “Óptimo” según su promedio de calificaciones.'

DELIMITER //

CREATE FUNCTION estado_producto(p_product_id INT)
RETURNS VARCHAR(50)
READS SQL DATA
BEGIN
    DECLARE v_avg_rating DECIMAL(3,2);
    DECLARE v_status VARCHAR(50);

    SELECT
        AVG(rating)
    INTO
        v_avg_rating
    FROM
        quality_products
    WHERE
        product_id = p_product_id;

    IF v_avg_rating IS NULL THEN
        SET v_status = 'Sin Calificaciones';
    ELSEIF v_avg_rating >= 4.0 THEN
        SET v_status = 'Óptimo';
    ELSEIF v_avg_rating >= 2.5 THEN
        SET v_status = 'Aceptable';
    ELSE
        SET v_status = 'Crítico';
    END IF;

    RETURN v_status;
END //

DELIMITER ;

'8.Explicación: es_favorito(customer_id, product_id) devolvería TRUE si hay un registro en details_favorites.'

DELIMITER //

CREATE FUNCTION es_favorito(p_customer_id INT, p_product_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_is_favorite BOOLEAN;

    SELECT
        COUNT(*) > 0
    INTO
        v_is_favorite
    FROM
        favorites AS f
    INNER JOIN
        companyproducts AS cp ON f.company_id = cp.company_id
    WHERE
        f.customer_id = p_customer_id
        AND cp.product_id = p_product_id;

    RETURN v_is_favorite;
END //

DELIMITER ;

'9.Explicación: beneficio_asignado_audiencia(benefit_id, audience_id) buscaría en audiencebenefits y retornaría TRUE si hay coincidencia.'

DELIMITER //

CREATE FUNCTION beneficio_asignado_audiencia(p_benefit_id INT, p_audience_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_is_assigned BOOLEAN;

    SELECT
        COUNT(*) > 0
    INTO
        v_is_assigned
    FROM
        audiencebenefits
    WHERE
        benefit_id = p_benefit_id
        AND audience_id = p_audience_id;

    RETURN v_is_assigned;
END //

DELIMITER ;

'10.Explicación: fecha_en_membresia(fecha, customer_id) compararía fecha con los rangos de membershipperiods activos del cliente.'

DELIMITER //

CREATE FUNCTION fecha_en_membresia(p_fecha DATE, p_customer_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_in_membership BOOLEAN;

    SELECT
        COUNT(*) > 0
    INTO
        v_in_membership
    FROM
        membershipperiods
    WHERE
        customer_id = p_customer_id
        AND status = 'ACTIVA'
        AND p_fecha BETWEEN start_date AND end_date;

    RETURN v_in_membership;
END //

DELIMITER ;

'11.Explicación: porcentaje_positivas(product_id) devolvería la relación entre calificaciones mayores o iguales a 4 y el total de calificaciones.'

DELIMITER //

CREATE FUNCTION porcentaje_positivas(p_product_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total_ratings INT;
    DECLARE v_positive_ratings INT;
    DECLARE v_percentage DECIMAL(5,2);

    SELECT
        COUNT(*)
    INTO
        v_total_ratings
    FROM
        quality_products
    WHERE
        product_id = p_product_id;

    SELECT
        COUNT(*)
    INTO
        v_positive_ratings
    FROM
        quality_products
    WHERE
        product_id = p_product_id
        AND rating >= 4;

    IF v_total_ratings > 0 THEN
        SET v_percentage = (v_positive_ratings / v_total_ratings) * 100;
    ELSE
        SET v_percentage = 0.00;
    END IF;

    RETURN v_percentage;
END //

DELIMITER ;

'12.Un supervisor quiere saber cuántos días han pasado desde que se registró una calificación de un producto. Este cálculo debe hacerse dinámicamente comparando la fecha actual del sistema (CURRENT_DATE) con la fecha en que se hizo la calificación (que suponemos está almacenada en un campo como created_at o rate_date en la tabla rates).'

DELIMITER //

CREATE FUNCTION edad_calificacion_dias(p_rate_date DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN DATEDIFF(CURDATE(), p_rate_date);
END //

DELIMITER ;

'13.Explicación: productos_por_empresa(company_id) haría un COUNT(DISTINCT product_id) en companyproducts.'

DELIMITER //

CREATE FUNCTION productos_por_empresa(p_company_id VARCHAR(10))
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_product_count INT;

    SELECT
        COUNT(DISTINCT product_id)
    INTO
        v_product_count
    FROM
        companyproducts
    WHERE
        company_id = p_company_id;

    RETURN v_product_count;
END //

DELIMITER ;

'14.Como gerente, deseo una función que retorne el nivel de actividad de un cliente (frecuente, esporádico, inactivo), según su número de calificaciones.'

DELIMITER //

CREATE FUNCTION nivel_actividad_cliente(p_customer_id INT)
RETURNS VARCHAR(50)
READS SQL DATA
BEGIN
    DECLARE v_rating_count INT;
    DECLARE v_activity_level VARCHAR(50);

    SELECT
        COUNT(*)
    INTO
        v_rating_count
    FROM
        quality_products
    WHERE
        customer_id = p_customer_id;

    IF v_rating_count >= 10 THEN
        SET v_activity_level = 'Frecuente';
    ELSEIF v_rating_count >= 1 THEN
        SET v_activity_level = 'Esporádico';
    ELSE
        SET v_activity_level = 'Inactivo';
    END IF;

    RETURN v_activity_level;
END //

DELIMITER ;

'15.Como administrador, quiero una función que calcule el precio promedio ponderado de un producto, tomando en cuenta su uso en favoritos.'

DELIMITER //

CREATE FUNCTION precio_promedio_ponderado_favoritos(p_product_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_weighted_avg_price DECIMAL(10,2);
    DECLARE v_total_favorites_for_product INT;

    SELECT
        COUNT(f.customer_id)
    INTO
        v_total_favorites_for_product
    FROM
        favorites AS f
    INNER JOIN
        companyproducts AS cp ON f.company_id = cp.company_id
    WHERE
        cp.product_id = p_product_id;

    IF v_total_favorites_for_product = 0 THEN
        SELECT AVG(price) INTO v_weighted_avg_price FROM companyproducts WHERE product_id = p_product_id;
    ELSE
        SELECT
            SUM(cp.price * (SELECT COUNT(*) FROM favorites WHERE company_id = cp.company_id)) / SUM( (SELECT COUNT(*) FROM favorites WHERE company_id = cp.company_id) )
        INTO
            v_weighted_avg_price
        FROM
            companyproducts AS cp
        WHERE
            cp.product_id = p_product_id;
    END IF;

    RETURN v_weighted_avg_price;
END //

DELIMITER ;

'16.Como técnico, deseo una función que me indique si un benefit_id está asignado a más de una audiencia o membresía (valor booleano).'

DELIMITER //

CREATE FUNCTION beneficio_multi_asignado(p_benefit_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_audience_count INT;
    DECLARE v_membership_count INT;

    SELECT COUNT(*) INTO v_audience_count FROM audiencebenefits WHERE benefit_id = p_benefit_id;
    SELECT COUNT(*) INTO v_membership_count FROM membershipbenefits WHERE benefit_id = p_benefit_id;

    RETURN (v_audience_count > 1 OR v_membership_count > 1);
END //

DELIMITER ;

'17.Como cliente, quiero una función que, dada mi ciudad, retorne un índice de variedad basado en número de empresas y productos.'

DELIMITER //

CREATE FUNCTION indice_variedad_ciudad(p_city_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_company_count INT;
    DECLARE v_product_count INT;
    DECLARE v_variety_index DECIMAL(10,2);

    SELECT COUNT(id) INTO v_company_count FROM companies WHERE city_id = p_city_id;

    SELECT COUNT(DISTINCT cp.product_id)
    INTO v_product_count
    FROM companyproducts AS cp
    INNER JOIN companies AS c ON cp.company_id = c.id
    WHERE c.city_id = p_city_id;

    IF v_company_count > 0 AND v_product_count > 0 THEN
        SET v_variety_index = (v_company_count * v_product_count) / 100.0;
    ELSE
        SET v_variety_index = 0.00;
    END IF;

    RETURN v_variety_index;
END //

DELIMITER ;

'18.Como gestor de calidad, deseo una función que evalúe si un producto debe ser desactivado por tener baja calificación histórica.'

DELIMITER //

CREATE FUNCTION desactivar_por_baja_calificacion(p_product_id INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_avg_rating DECIMAL(3,2);
    DECLARE v_should_deactivate BOOLEAN;

    SELECT AVG(rating)
    INTO v_avg_rating
    FROM quality_products
    WHERE product_id = p_product_id;

    IF v_avg_rating IS NOT NULL AND v_avg_rating < 2.0 THEN
        SET v_should_deactivate = TRUE;
    ELSE
        SET v_should_deactivate = FALSE;
    END IF;

    RETURN v_should_deactivate;
END //

DELIMITER ;

'19.Como desarrollador, quiero una función que calcule el índice de popularidad de un producto (combinando favoritos y ratings).'

DELIMITER //

CREATE FUNCTION indice_popularidad_producto(p_product_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_favorite_count INT;
    DECLARE v_avg_rating DECIMAL(3,2);
    DECLARE v_popularity_index DECIMAL(10,2);

    SELECT
        COUNT(f.customer_id)
    INTO
        v_favorite_count
    FROM
        favorites AS f
    INNER JOIN
        companyproducts AS cp ON f.company_id = cp.company_id
    WHERE
        cp.product_id = p_product_id;

    SELECT
        AVG(rating)
    INTO
        v_avg_rating
    FROM
        quality_products
    WHERE
        product_id = p_product_id;

    IF v_avg_rating IS NULL THEN
        SET v_avg_rating = 0;
    END IF;

    SET v_popularity_index = (v_favorite_count * 0.5) + (v_avg_rating * 0.5);

    RETURN v_popularity_index;
END //

DELIMITER ;

'20.Como auditor, deseo una función que genere un código único basado en el nombre del producto y su fecha de creación.'

DELIMITER //

CREATE FUNCTION generar_codigo_unico_producto(p_product_name VARCHAR(255), p_creation_date DATE)
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE v_unique_code VARCHAR(255);
    SET v_unique_code = CONCAT(
        UPPER(SUBSTRING(p_product_name, 1, 3)),
        DATE_FORMAT(p_creation_date, '%Y%m%d'),
        LPAD(FLOOR(RAND() * 1000), 3, '0')
    );
    RETURN v_unique_code;
END //

DELIMITER ;
