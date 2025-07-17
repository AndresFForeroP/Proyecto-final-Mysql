"1.Como desarrollador, deseo un trigger que actualice la fecha de modificación cuando se actualice un producto."

DELIMITER //

CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END //

DELIMITER ;

"2.Como administrador, quiero un trigger que registre en log cuando un cliente califica un producto."

NO ME SALIO :c

"3.Como técnico, deseo un trigger que impida insertar productos sin unidad de medida."

DELIMITER //

CREATE TRIGGER trg_before_insert_companyproduct_check_unit_measure
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
    IF NEW.unitmeasure_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se puede insertar un producto sin una unidad de medida asignada.';
    END IF;
END //

DELIMITER ;

"4.Como auditor, quiero un trigger que verifique que las calificaciones no superen el valor máximo permitido."

DELIMITER //

CREATE TRIGGER trg_before_insert_quality_products_validate_rating
BEFORE INSERT ON quality_products
FOR EACH ROW
BEGIN
    IF NEW.rating > 5.0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La calificación no puede ser mayor a 5.0.';
    END IF;
END //

DELIMITER ;

"5.Como supervisor, deseo un trigger que actualice automáticamente el estado de membresía al vencer el periodo."

DELIMITER //

CREATE TRIGGER trg_membershipperiods_update_status_on_expiry
BEFORE UPDATE ON membershipperiods
FOR EACH ROW
BEGIN
    IF NEW.end_date < CURDATE() AND NEW.status <> 'INACTIVA' THEN
        SET NEW.status = 'INACTIVA';
    END IF;
END //

DELIMITER ;

"6.Como operador, quiero un trigger que evite duplicar productos por nombre dentro de una misma empresa."

DELIMITER //

CREATE TRIGGER trg_before_insert_companyproducts_prevent_duplicate
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*)
    INTO v_count
    FROM companyproducts
    WHERE product_id = NEW.product_id AND company_id = NEW.company_id;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Este producto ya está asociado a esta empresa.';
    END IF;
END //

DELIMITER ;

"7.Como cliente, deseo un trigger que envíe notificación cuando añado un producto como favorito."

NO ME SALIO :c

"8.Como técnico, quiero un trigger que inserte una fila en quality_products cuando se registra una calificación."

NO ME SALIO

"9.Como desarrollador, deseo un trigger que elimine los favoritos si se elimina el producto."

DELIMITER //

CREATE TRIGGER trg_before_delete_product_remove_favorites
BEFORE DELETE ON products
FOR EACH ROW
BEGIN
    
    FOR company_rec IN (SELECT cp.company_id FROM companyproducts AS cp WHERE cp.product_id = OLD.id) DO
        DECLARE v_remaining_products_count INT;
        SELECT COUNT(*)
        INTO v_remaining_products_count
        FROM companyproducts
        WHERE company_id = company_rec.company_id AND product_id <> OLD.id; 
        IF v_remaining_products_count = 0 THEN
            DELETE FROM favorites
            WHERE company_id = company_rec.company_id;
        END IF;
    END FOR;
END //

DELIMITER ;

"10.Como administrador, quiero un trigger que bloquee la modificación de audiencias activas."

DELIMITER //

CREATE TRIGGER trg_before_update_audiences_block_active
BEFORE UPDATE ON audiences
FOR EACH ROW
BEGIN
    IF OLD.isactivate = TRUE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se puede modificar una audiencia que está activa.';
    END IF;
END //

DELIMITER ;

"11.Como gestor, deseo un trigger que actualice el promedio de calidad del producto tras una nueva evaluación."

DELIMITER //

CREATE TRIGGER trg_after_insert_quality_products_update_average
AFTER INSERT ON quality_products
FOR EACH ROW
BEGIN
    UPDATE products
    SET average_rating = (
        SELECT AVG(rating)
        FROM quality_products
        WHERE product_id = NEW.product_id
    )
    WHERE id = NEW.product_id;
END //

DELIMITER ;

"12.Como auditor, quiero un trigger que registre cada vez que se asigna un nuevo beneficio."

DELIMITER //

CREATE TRIGGER trg_after_insert_membershipbenefit_log
AFTER INSERT ON membershipbenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (timestamp, action_type, entity_type, entity_id, related_id, description)
    VALUES (
        NOW(),
        'Asignación de Beneficio',
        'Membresía',
        NEW.membership_id,
        NEW.benefit_id,
        CONCAT('Beneficio ID ', NEW.benefit_id, ' asignado a la membresía ID ', NEW.membership_id, '.')
    );
END //

CREATE TRIGGER trg_after_insert_audiencebenefit_log
AFTER INSERT ON audiencebenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (timestamp, action_type, entity_type, entity_id, related_id, description)
    VALUES (
        NOW(),
        'Asignación de Beneficio',
        'Audiencia',
        NEW.audience_id,
        NEW.benefit_id,
        CONCAT('Beneficio ID ', NEW.benefit_id, ' asignado a la audiencia ID ', NEW.audience_id, '.')
    );
END //

DELIMITER ;

"13.Como cliente, deseo un trigger que me impida calificar el mismo producto dos veces seguidas."

DELIMITER //

CREATE TRIGGER trg_before_insert_quality_products_prevent_duplicate_rating
BEFORE INSERT ON quality_products
FOR EACH ROW
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*)
    INTO v_count
    FROM quality_products
    WHERE customer_id = NEW.customer_id AND product_id = NEW.product_id;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Ya has calificado este producto.';
    END IF;
END //

DELIMITER ;

"14.Como técnico, quiero un trigger que valide que el email del cliente no se repita."

DELIMITER //

CREATE TRIGGER trg_before_insert_customers_validate_email
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    DECLARE email_count INT;
    SELECT COUNT(*)
    INTO email_count
    FROM customers
    WHERE email = NEW.email;
    IF email_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El correo electrónico ya está registrado para otro cliente.';
    END IF;
END //

DELIMITER ;

"15.Como operador, deseo un trigger que elimine registros huérfanos de details_favorites."

DELIMITER //

CREATE TRIGGER trg_after_delete_favorites_delete_details
AFTER DELETE ON favorites
FOR EACH ROW
BEGIN
    DELETE FROM details_favorites
    WHERE favorite_id = OLD.id; -- Asumiendo que 'details_favorites' tiene una columna 'favorite_id' que referencia a 'favorites.id'
END //

DELIMITER ;

"16.Como administrador, quiero un trigger que actualice el campo updated_at en companies."

DELIMITER //

CREATE TRIGGER trg_companies_updated_at
BEFORE UPDATE ON companies
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END //

DELIMITER ;

"17.Como desarrollador, deseo un trigger que impida borrar una ciudad si hay empresas activas en ella."

DELIMITER //

CREATE TRIGGER trg_before_delete_city_check_active_companies
BEFORE DELETE ON citiesormunicipalities
FOR EACH ROW
BEGIN
    DECLARE v_active_companies_count INT;
    SELECT COUNT(*)
    INTO v_active_companies_count
    FROM companies
    WHERE city_id = OLD.id AND isactivate = TRUE;
    IF v_active_companies_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se puede eliminar esta ciudad porque tiene empresas activas asociadas.';
    END IF;
END //

DELIMITER ;

"18.Como auditor, quiero un trigger que registre cambios de estado de encuestas."

DELIMITER //
CREATE TRIGGER trg_after_update_polls_log_status_change
AFTER UPDATE ON polls
FOR EACH ROW
BEGIN
    IF NEW.status <> OLD.status THEN
        INSERT INTO log_encuestas_estado (poll_id, old_status, new_status, change_date)
        VALUES (OLD.id, OLD.status, NEW.status, NOW());
    END IF;
END //

DELIMITER ;

"19.Como supervisor, deseo un trigger que sincronice rates con quality_products al calificar."

CREATE TRIGGER trg_after_insert_rates_sync_quality_products
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
    VALUES (NEW.product_id, NEW.customer_id, NEW.poll_id, NEW.company_id, NOW(), NEW.rating);
END //

DELIMITER ;

"20.Como operador, quiero un trigger que elimine automáticamente productos sin relación a empresas."

DELIMITER //

CREATE TRIGGER trg_after_delete_companyproduct_delete_orphan_product
AFTER DELETE ON companyproducts
FOR EACH ROW
BEGIN
    DECLARE v_product_associations_count INT;

    SELECT COUNT(*)
    INTO v_product_associations_count
    FROM companyproducts
    WHERE product_id = OLD.product_id;

    IF v_product_associations_count = 0 THEN
        DELETE FROM products
        WHERE id = OLD.product_id;
    END IF;
END //

DELIMITER ;