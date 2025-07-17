'1.Historia: Como analista, quiero consultar todas las empresas junto con los productos que ofrecen, mostrando el nombre del producto y el precio.'

SELECT c.name AS NombreEmpresa, p.name AS NombreProducto, cp.price AS PrecioProducto 
FROM companies AS c  
INNER JOIN companyproducts AS cp ON c.id = cp.company_id 
INNER JOIN products AS p ON cp.product_id = p.id;


'2.Historia: Como cliente, deseo ver mis productos favoritos junto con la categoría y el nombre de la empresa que los ofrece.'

SELECT f.customer_id,p.name,c.name,cat.name
FROM favorites AS f
INNER JOIN companies AS c ON f.company_id = c.id
INNER JOIN companyproducts AS cp ON c.id = cp.company_id
INNER JOIN products AS p ON cp.product_id = p.id
INNER JOIN categories AS cat ON p.category_id = cat.id
WHERE f.customer_id = 5;

'3.Historia: Como supervisor, quiero ver todas las empresas aunque no tengan productos asociados.'

SELECT c.name AS NombreEmpresa,p.name AS NombreProducto
FROM companies AS c               
LEFT JOIN companyproducts AS cp ON c.id = cp.company_id
LEFT JOIN products AS p ON cp.product_id = p.id;

'4.Historia: Como técnico, deseo obtener todas las calificaciones de productos incluyendo aquellos productos que aún no han sido calificados.'

SELECT p.name AS NombreProducto, qp.rating AS Calificacion,qp.daterating AS FechaCalificacion
FROM products AS p
LEFT JOIN quality_products AS qp ON p.id = qp.product_id;

'5.Historia: Como gestor, quiero ver productos con su promedio de calificación y nombre de la empresa.'

SELECT p.name AS NombreProducto,c.name AS NombreEmpresa,AVG(qp.rating) AS PromedioCalificacion
FROM products AS p
INNER JOIN companyproducts AS cp ON p.id = cp.product_id
INNER JOIN companies AS c ON cp.company_id = c.id
LEFT JOIN quality_products AS qp ON p.id = qp.product_id AND c.id = qp.company_id
GROUP BY p.id, p.name, c.id, c.name;

'6.Historia: Como operador, deseo obtener todos los clientes y sus calificaciones si existen.'

SELECT cust.name AS NombreCliente, qp.rating AS Calificacion, qp.daterating AS FechaCalificacion, p.name AS NombreProducto,
comp.name AS NombreEmpresa
FROM customers AS cust
LEFT JOIN quality_products AS qp ON cust.id = qp.customer_id
LEFT JOIN products AS p ON qp.product_id = p.id
LEFT JOIN companies AS comp ON qp.company_id = comp.id;

'7.Historia: Como cliente, quiero consultar todos mis favoritos junto con la última calificación que he dado.'

SELECT f.customer_id, p.name AS NombreProducto, c.name AS NombreEmpresa,
latest_rating.rating AS UltimaCalificacion, latest_rating.daterating AS FechaUltimaCalificacion
FROM favorites AS f
INNER JOIN companyproducts AS cp ON f.company_id = cp.company_id
INNER JOIN products AS p ON cp.product_id = p.id
INNER JOIN companies AS c ON f.company_id = c.id
LEFT JOIN (
    SELECT qp_inner.customer_id, qp_inner.product_id, qp_inner.rating, qp_inner.daterating
    FROM quality_products AS qp_inner
    INNER JOIN (
        SELECT customer_id, product_id, MAX(daterating) AS max_daterating
        FROM quality_products
        GROUP BY customer_id, product_id
    ) AS latest_ratings ON qp_inner.customer_id = latest_ratings.customer_id
    AND qp_inner.product_id = latest_ratings.product_id
    AND qp_inner.daterating = latest_ratings.max_daterating
) AS latest_rating ON f.customer_id = latest_rating.customer_id AND p.id = latest_rating.product_id
WHERE f.customer_id = 7;

'8.Historia: Como administrador, quiero unir membershipbenefits, benefits y memberships.'

SELECT m.name AS NombreMembresia, b.name AS NombreBeneficio, b.description AS DescripcionBeneficio 
FROM memberships AS m 
INNER JOIN membershipbenefits AS mb ON m.id = mb.membership_id 
INNER JOIN benefits AS b ON mb.benefit_id = b.id; 

'9.Historia: Como gerente, deseo ver todos los clientes con membresía activa y sus beneficios actuales.'

SELECT c.name AS NombreCliente, m.name AS NombreMembresia, mp.start_date AS FechaInicioMembresia, mp.end_date AS FechaFinMembresia, b.name AS NombreBeneficio, b.description AS DescripcionBeneficio 
FROM customers AS c
INNER JOIN membershipperiods AS mp ON c.id = mp.customer_id 
INNER JOIN memberships AS m ON mp.membership_id = m.id 
INNER JOIN membershipbenefits AS mb ON m.id = mb.membership_id 
INNER JOIN benefits AS b ON mb.benefit_id = b.id 
WHERE mp.status = 'ACTIVA' AND mp.end_date >= CURDATE();

'10.Historia: Como operador, quiero obtener todas las ciudades junto con la cantidad de empresas registradas.'

SELECT city.name AS NombreCiudad, COUNT(c.id) AS CantidadEmpresas
FROM citiesormunicipalities AS city
LEFT JOIN companies AS c ON city.id = c.city_id
GROUP BY city.id, city.name
ORDER BY CantidadEmpresas DESC, NombreCiudad;

'11.Historia: Como analista, deseo unir polls y rates.'

SELECT p.name, qp.rating, qp.daterating, cust.name, prod.name
FROM polls AS p
INNER JOIN quality_products AS qp ON p.id = qp.poll_id
LEFT JOIN customers AS cust ON qp.customer_id = cust.id
LEFT JOIN products AS prod ON qp.product_id = prod.id;

'12.Historia: Como técnico, quiero consultar todos los productos evaluados con su fecha y cliente.'

SELECT p.name AS NombreProducto, qp.daterating AS FechaEvaluacion, qp.rating AS Calificacion, c.name AS NombreCliente, c.email AS EmailCliente
FROM quality_products AS qp
INNER JOIN products AS p ON qp.product_id = p.id
INNER JOIN customers AS c ON qp.customer_id = c.id;

'13.Historia: Como supervisor, deseo obtener todos los productos con la audiencia objetivo de la empresa.'

SELECT p.name, c.name, a.name
FROM products AS p
INNER JOIN companyproducts AS cp ON p.id = cp.product_id
INNER JOIN companies AS c ON cp.company_id = c.id
INNER JOIN audiences AS a ON c.audience_id = a.id;

'14.Historia: Como auditor, quiero unir customers y favorites.'

SELECT cust.name, p.name, comp.name
FROM customers AS cust
INNER JOIN favorites AS f ON cust.id = f.customer_id
INNER JOIN companyproducts AS cp ON f.company_id = cp.company_id
INNER JOIN products AS p ON cp.product_id = p.id
INNER JOIN companies AS comp ON f.company_id = comp.id;

'15.Historia: Como gestor, deseo obtener la relación de planes de membresía, periodos, precios y beneficios.'

SELECT m.name, mp.start_date, mp.end_date, mp.price, b.name, b.description
FROM memberships AS m
INNER JOIN membershipperiods AS mp ON m.id = mp.membership_id
INNER JOIN membershipbenefits AS mb ON m.id = mb.membership_id
INNER JOIN benefits AS b ON mb.benefit_id = b.id;

'16.Historia: Como desarrollador, quiero consultar todas las combinaciones empresa-producto-cliente que hayan sido calificadas.'

SELECT comp.name, p.name, cust.name, qp.rating, qp.daterating
FROM quality_products AS qp
INNER JOIN companies AS comp ON qp.company_id = comp.id
INNER JOIN products AS p ON qp.product_id = p.id
INNER JOIN customers AS cust ON qp.customer_id = cust.id;

'17.Historia: Como cliente, quiero ver productos que he calificado y también tengo en favoritos.'

SELECT f.customer_id, p.name AS NombreProducto, c.name AS NombreEmpresa, qp.rating AS Calificacion, qp.daterating AS FechaCalificacion
FROM favorites AS f
INNER JOIN quality_products AS qp ON f.customer_id = qp.customer_id AND f.company_id = qp.company_id
INNER JOIN products AS p ON qp.product_id = p.id
INNER JOIN companies AS c ON f.company_id = c.id
WHERE f.customer_id = 6 AND p.id = qp.product_id;

'18.Historia: Como operador, quiero unir categories y products.'

SELECT cat.name, p.name, p.description
FROM categories AS cat
INNER JOIN products AS p ON cat.id = p.category_id
ORDER BY cat.name, p.name;

'19.Historia: Como especialista, quiero listar beneficios por audiencia, incluso si no tienen asignados.'

SELECT a.name, b.name, b.description
FROM audiences AS a
LEFT JOIN audiencebenefits AS ab ON a.id = ab.audience_id
LEFT JOIN benefits AS b ON ab.benefit_id = b.id
ORDER BY a.name, b.name;

'20.Historia: Como auditor, deseo una consulta que relacione rates, polls, products y customers.'

SELECT qp.rating, qp.daterating, cust.name, p.name, pol.name
FROM quality_products AS qp
INNER JOIN customers AS cust ON qp.customer_id = cust.id
INNER JOIN products AS p ON qp.product_id = p.id
INNER JOIN polls AS pol ON qp.poll_id = pol.id;