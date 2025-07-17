'1.Como gerente, quiero ver los productos cuyo precio esté por encima del promedio 
de su categoría.'

SELECT p.name AS Producto, p.price AS Precio, c.description AS Categoria
FROM products AS p
JOIN categories AS c ON p.category_id = c.id
WHERE p.price > (
    SELECT AVG(price)
    FROM products AS p2 
    WHERE p2.category_id = p.category_id
)
ORDER BY c.description,p.name;

'2.Como administrador, deseo listar las empresas que tienen más productos 
que la media de empresas.'

SELECT c.name AS Empresa,COUNT(cps.product_id) AS Total_productos
FROM companies AS c
JOIN companyproducts AS cps ON c.id = cps.company_id
GROUP BY c.id,c.name
HAVING COUNT(cps.product_id) > (
    SELECT AVG(productoscompañia.numproductos)
    FROM (
        SELECT COUNT(product_id) AS numproductos
        FROM companyproducts
        GROUP BY company_id
    ) AS productoscompañia
)
ORDER BY Total_productos DESC;

'3.Como cliente, quiero ver mis productos favoritos que han sido 
calificados por otros clientes.'

SELECT c.name AS Cliente, p.name AS Producto,comp.name AS Empresa,qp.rating AS Calificacion, (
    SELECT cr.name FROM customers AS cr WHERE cr.id = qp.customer_id) AS Calificado_Por
FROM customers AS c
JOIN favorites AS f ON c.id = f.customer_id
JOIN companies AS comp ON f.company_id = comp.id
JOIN companyproducts AS cps ON comp.id = cps.company_id
JOIN products AS p ON cps.product_id = p.id
JOIN quality_products AS qp ON p.id = qp.product_id AND comp.id = qp.company_id
WHERE c.id = 2 AND qp.customer_id <> c.id
ORDER BY p.name, qp.daterating DESC;

'4.Como supervisor, deseo obtener los productos con el mayor número 
de veces añadidos como favoritos.'

SELECT p.name AS Producto,(
    SELECT COUNT(f.company_id)
    FROM companyproducts AS cp
    JOIN favorites AS f ON cp.company_id = f.company_id
    WHERE cp.product_id = p.id
) AS VecesAñadido
FROM products AS p
ORDER BY VecesAñadido DESC
LIMIT 10;

'5.Como técnico, quiero listar los clientes cuyo correo no aparece 
en la tabla rates ni en quality_products.'

SELECT c.name AS Cliente, c.email AS Correo
FROM customers AS c
WHERE c.email NOT IN (
    SELECT cu.email
    FROM rates AS r
    JOIN customers AS cu ON r.customer_id = cu.id
) AND c.email NOT IN (
    SELECT cu.email
    FROM quality_products AS qp
    JOIN customers AS cu ON qp.customer_id = cu.id
);

'6.Como gestor de calidad, quiero obtener los productos con una 
calificación inferior al mínimo de su categoría.'

NO ME SE SALIO :c

'7.Como desarrollador, deseo listar las ciudades que no 
tienen clientes registrados.'

SELECT cm.name AS Ciudad
FROM citiesormunicipalities AS cm
WHERE cm.id NOT IN (
    SELECT c.city_id
    FROM customers AS c
    WHERE c.city_id IS NOT NULL
);

'8.Como administrador, quiero ver los productos que no 
han sido evaluados en ninguna encuesta.'

SELECT p.name AS Producto,p.detail AS Detalles
FROM products AS p
WHERE p.id NOT IN (
    SELECT qp.product_id
    FROM quality_products AS qp
    WHERE qp.product_id IS NOT NULL
)

'9.Como auditor, quiero listar los beneficios que no 
están asignados a ninguna audiencia.'

SELECT b.description AS Beneficio, b.detail AS Detalles
FROM benefits AS b
WHERE b.id NOT IN(
    SELECT ab.audience_id 
    FROM audiencebenefits AS ab
    WHERE benefit_id IS NOT NULL
);

'10.Como cliente, deseo obtener mis productos favoritos 
que no están disponibles actualmente en ninguna empresa.'

NO ME SALIO :c

'11.Como director, deseo consultar los productos vendidos 
en empresas cuya ciudad tenga menos de tres empresas registradas.'

SELECT p.name AS Producto,cs.name AS Empresa
FROM products AS p
JOIN companyproducts AS cps ON p.id = cps.product_id
JOIN companies AS cs ON cps.company_id = cs.id
JOIN citiesormunicipalities AS cm ON cs.city_id = cm.id
WHERE cm.id IN (
    SElECT city_id
    FROM companies
    GROUP BY city_id
    HAVING COUNT(id) <= 2
)
ORDER BY cs.name, cm.name, p.name;

'12.Como analista, quiero ver los productos con calidad superior 
al promedio de todos los productos.'

SELECT p.name AS producto, AVG(qp.rating) AS Calificacion
FROM products AS p
JOIN quality_products AS qp ON qp.product_id = p.id
GROUP BY p.id,p.name
HAVING AVG(qp.rating) > (
    SELECT AVG(qp2.rating)
    FROM quality_products AS qp2
);

'13.Como gestor, quiero ver empresas que sólo venden 
productos de una única categoría.'

SELECT c.name AS Empresa,(
    SELECT cate.description
    FROM companyproducts AS cps2
    JOIN products AS p2 ON cps2.product_id = p2.id
    JOIN categories AS cate ON cate.id = p2.category_id
    WHERE cps2.company_id = c.id
    GROUP BY cate.description
    LIMIT 1
) 
FROM companies AS c
WHERE (
    SELECT COUNT(p2.category_id)
    FROM companyproducts AS cps2 
    JOIN products AS p2 ON cps2.product_id = p2.id
    WHERE cps2.company_id = c.id
) = 1;

'14.Como gerente comercial, quiero consultar los productos
con el mayor precio entre todas las empresas.'

SELECT p.name AS Producto, cps.price AS precio, c.name AS empresa
FROM products AS p
JOIN companyproducts AS cps ON cps.product_id = p.id
JOIN companies AS c ON c.id = cps.company_id
WHERE cps.price = (
    SELECT MAX(cps2.price)
    FROM companyproducts AS cps2
    WHERE cps2.product_id = p.id
)
ORDER BY precio;

'15.Como cliente, quiero saber si algún producto de mis favoritos 
ha sido calificado por otro cliente con más de 4 estrellas.'

SELECT p.name AS Producto, qp.rating AS Calificacion, c.name AS Cliente
FROM products p
JOIN quality_products qp ON qp.product_id = p.id
JOIN customers c ON c.id = qp.customer_id
WHERE p.id IN (
    SELECT id 
    FROM products 
    WHERE name = 'Pantalón vaquero'
) AND qp.rating > 4
ORDER BY qp.rating DESC;

'16.Como operador, quiero saber qué productos no tienen imagen 
asignada pero sí han sido calificados.'

SELECT p.name AS Nombre_Producto, p.detail AS Detalle
FROM products AS p
WHERE (p.image IS NULL OR p.image = 'None') AND p.id IN (
    SELECT qp.product_id
    FROM quality_products AS qp
    WHERE qp.product_id IS NOT NULL
)
ORDER BY p.name;

'17.como auditor, quiero ver los planes de membresía sin periodo vigente.'


NO ME SALIO :c


'18.Como especialista, quiero identificar los beneficios compartidos por más de una audiencia.'

SELECT b.description AS Beneficio, b.detail AS Detalle
FROM benefits AS b
WHERE(
    SELECT COUNT(ab.audience_id)
    FROM audiencebenefits AS ab
    WHERE ab.benefit_id = b.id
) > 1
ORDER BY b.description;


'19.Como técnico, quiero encontrar empresas cuyos productos no tengan unidad de medida definida.'

SELECT c.name AS Nombre_Empresa
FROM companies AS c
WHERE c.id IN (
    SELECT cps.company_id
    FROM companyproducts AS cps
    WHERE cps.unitmeasure_id IS NULL
)
ORDER BY c.name;


'20.Como gestor de campañas, deseo obtener los clientes con membresía activa y sin productos favoritos.'

SELECT c.name AS Cliente, c.email AS Correo
FROM customers AS c
WHERE c.id NOT IN (
    SELECT f.customer_id
    FROM favorites AS f
    WHERE f.customer_id IS NOT NULL
)
ORDER BY c.name;