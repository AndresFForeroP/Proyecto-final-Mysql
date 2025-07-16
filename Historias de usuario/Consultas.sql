'1.Como analista, quiero listar todos los productos con su empresa asociada y el precio
más bajo por ciudad.'

SELECT p.name AS producto,c.name AS empresa, cps.price AS precio, ct.name AS ciudad
FROM products p
JOIN companyproducts cps ON p.id = cps.product_id
JOIN companies c ON cps.company_id = c.id
JOIN citiesormunicipalities ct ON c.city_id = ct.id
WHERE cps.price = (
        SELECT MIN(cps2.price)
        FROM companyproducts cps2
        JOIN companies c2 ON cps2.company_id = c2.id
        WHERE cps2.product_id = p.id 
        AND c2.city_id = c.city_id
)
ORDER BY producto;

'2.Como administrador, deseo obtener el top 5 de clientes que más productos han calificado 
en los últimos 6 meses.'

SELECT c.name AS cliente, COUNT(qp.customer_id) AS total_calificaciones
FROM customers AS c
JOIN quality_products AS qp ON qp.customer_id = c.id
WHERE qp.daterating >= DATE_SUB(CURDATE(),INTERVAL 6 MONTH)
GROUP BY c.id, c.name
ORDER BY total_calificaciones DESC
LIMIT 5;

'3.Como gerente de ventas, quiero ver la distribución de productos por categoría y unidad 
de medida.'

SELECT p.name AS producto, c.description AS categoria, um.description AS unidad_medida
FROM products AS p
JOIN categories AS c ON c.id = p.category_id
JOIN companyproducts AS cps ON cps.product_id = p.id
JOIN unitofmeasure AS um ON um.id = cps.unitmeasure_id; 

'4.Como cliente, quiero saber qué productos tienen calificaciones superiores al promedio 
general.'

SELECT p.name AS producto, qp.rating AS calificacion
FROM products AS p
JOIN quality_products AS qp ON qp.product_id = p.id
WHERE qp.rating > (SELECT AVG(rating) FROM quality_products)
ORDER BY calificacion DESC;

'5.Como auditor, quiero conocer todas las empresas que no han recibido ninguna calificación.'

SELECT c.name AS empresa
FROM companies AS c
WHERE NOT EXISTS (
    SELECT *
    FROM rates AS r
    WHERE r.company_id = c.id
);

'6.Como operador, deseo obtener los productos que han sido añadidos como favoritos por más 
de 10 clientes distintos.'

SELECT p.name AS producto,COUNT(f.customer_id) AS cantidad_favoritos
FROM favorites f
JOIN companyproducts AS cp ON f.company_id = cp.company_id
JOIN products AS p ON cp.product_id = p.id
GROUP BY p.id, p.name
HAVING COUNT(f.customer_id) > 10
ORDER BY cantidad_favoritos DESC;

'7.Como gerente regional, quiero obtener todas las empresas activas por ciudad y categoría.'

SELECT c.name AS empresa, cm.name AS ciudad, ct.description AS categoria
FROM companies as c
JOIN citiesormunicipalities AS cm ON cm.id = c.city_id
JOIN categories AS ct ON ct.id = c.category_id
WHERE c.isactivate = TRUE;

'8.Como especialista en marketing, deseo obtener los 10 productos más calificados en 
cada ciudad.'

NO ME SE SALIO :c

'9.Como técnico, quiero identificar productos sin unidad de medida asignada.'

SELECT p.name AS producto
FROM products AS p
LEFT JOIN companyproducts AS cps ON p.id = cps.product_id
WHERE cps.unitmeasure_id IS NULL;

'10.Como gestor de beneficios, deseo ver los planes de membresía sin beneficios registrados.'

SELECT m.name AS Membresia, m.description AS Descripcion
FROM memberships AS m
LEFT JOIN membershipbenefits mb ON m.id = mb.membership_id
WHERE mb.membership_id IS NULL
ORDER BY m.name;

'11.Como supervisor, quiero obtener los productos de una categoría específica con su 
promedio de calificación.'

SELECT p.name AS Productos, c.description AS categories, AVG(qp.rating) AS Promedio_rating
FROM products AS p
JOIN quality_products AS qp ON qp.product_id = p.id
JOIN categories AS c ON c.id = p.category_id
WHERE c.description = 'Farmacias'
GROUP BY p.id, p.name, c.description
ORDER BY Promedio_rating DESC;

'12.Como asesor, deseo obtener los clientes que han comprado productos de más de una empresa.'

SELECT c.name AS Cliente, COUNT(cps.company_id) AS total_empresas
FROM customers AS c
JOIN companyproducts AS cps ON cps.product_id IN (
    SELECT qp.product_id
    FROM quality_products AS qp
    WHERE qp.customer_id = c.id
)
GROUP BY c.id,c.name
HAVING COUNT(cps.company_id) > 1
ORDER BY total_empresas DESC;

'13.Como director, quiero identificar las ciudades con más clientes activos.'

SELECT cm.name AS Ciudad, COUNT(c.id) AS Total_Cliente
FROM customers AS c
JOIN citiesormunicipalities AS cm ON c.city_id = cm.id
GROUP BY cm.id, cm.name
ORDER BY Total_Cliente DESC
LIMIT 10;

'14.Como analista de calidad, deseo obtener el ranking de productos por 
empresa basado en la media de quality_products.'

SELECT qp.company_id,qp.product_id,AVG(qp.rating) AS avg_rating
FROM quality_products qp
GROUP BY qp.company_id, qp.product_id
ORDER BY qp.company_id, avg_rating DESC;

'15.Como administrador, quiero listar empresas que ofrecen más de cinco productos distintos.'

SELECT c.name AS empresa, COUNT(cp.product_id) AS cantidad_productos
FROM companies c
JOIN companyproducts cp ON c.id = cp.company_id
GROUP BY c.id, c.name
HAVING COUNT(DISTINCT cp.product_id) > 2
ORDER BY cantidad_productos DESC;

'16.Como cliente, deseo visualizar los productos favoritos que aún no han sido calificados.'

NO ME SE SALIO :c

'17.Como desarrollador, deseo consultar los beneficios asignados a cada audiencia junto 
con su descripción.'

SELECT a.description AS Audiencia, b.description AS Beneficio, b.detail AS Detalles
FROM audiences AS a 
JOIN audiencebenefits AS ab ON a.id = ab.audience_id
JOIN benefits AS b ON ab.benefit_id = b.id;

'18.Como operador logístico, quiero saber en qué ciudades hay empresas sin productos asociados.'

SELECT cm.name AS Ciudad
FROM citiesormunicipalities AS cm
JOIN companies AS c ON cm.id = c.city_id
LEFT JOIN companyproducts AS cps ON c.id = cps.company_id
WHERE cps.company_id IS NULL;

'19.Como técnico, deseo obtener todas las empresas con productos duplicados por nombre.'

NO ME SALIO :c

'20.Como analista, quiero una vista resumen de clientes, productos favoritos y promedio 
de calificación recibido.'

NO ME SALIO 