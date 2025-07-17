"1.Como analista, quiero obtener el promedio de calificación por producto."

SELECT p.name AS Producto, AVG(qp.rating) AS Promedio_Calificacion 
FROM products AS p
JOIN quality_products AS qp ON p.id = qp.product_id
GROUP BY p.id,p.name
ORDER BY Promedio_Calificacion DESC, 
p.name;

'2.Como gerente, desea contar cuántos productos ha calificado cada cliente.'

SELECT c.name AS Nombre_Cliente, COUNT(qp.product_id) AS Productos_Calificados
FROM customers AS c
JOIN quality_products AS qp ON c.id = qp.customer_id
GROUP BY c.id, c.name
ORDER BY Productos_Calificados DESC, c.name;

"3.Como auditor, quiere sumar el total de beneficios asignados por audiencia."

SELECT a.description AS Nombre_Audiencia, COUNT(ab.benefit_id) AS Total_Beneficios_Asignados
FROM audiences AS a
JOIN audiencebenefits AS ab ON a.id = ab.audience_id
GROUP BY a.id, a.description
ORDER BY Total_Beneficios_Asignados DESC, a.description;

"4.Como administrador, desea conocer la media de productos por empresa."

SELECT AVG(ProductosPorEmpresa.Cantidad_Productos) AS Media_Productos_Por_Empresa
FROM (
    SELECT company_id, COUNT(product_id) AS Cantidad_Productos
    FROM companyproducts
    GROUP BY company_id
) AS ProductosPorEmpresa;

"5.Como supervisor, quiere ver el total de empresas por ciudad."

SELECT ci.name AS Ciudad, COUNT(comp.id) AS Empresas
FROM citiesormunicipalities AS ci
JOIN companies AS comp ON ci.id = comp.city_id
GROUP BY ci.id, ci.name
ORDER BY Empresas DESC, ci.name;

"6.Como técnico, desea obtener el promedio de precios de productos por unidad de medida."

SELECT um.description AS Unidad_Medida, AVG(cp.price) AS Promedio_Precio
FROM unitofmeasure AS um
JOIN companyproducts AS cp ON um.id = cp.unitmeasure_id
GROUP BY um.id, um.description
ORDER BY Promedio_Precio DESC, um.description;

"7.Como gerente, quiere ver el número de clientes registrados por cada ciudad."

SELECT ci.name AS Ciudad, COUNT(c.id) AS Clientes
FROM citiesormunicipalities AS ci
JOIN customers AS c ON ci.id = c.city_id
GROUP BY ci.id, ci.name
ORDER BY Clientes DESC, ci.name;

"8.Como operador, desea contar cuántos planes de membresía existen por periodo."

NO ME SALIO :c

"9.Como cliente, quiere ver el promedio de calificaciones que ha otorgado a sus productos favoritos."

SELECT c.name AS Cliente, AVG(qp.rating) AS Promedio_Calificacion
FROM customers AS c
JOIN favorites AS f ON c.id = f.customer_id
JOIN companyproducts AS cp ON f.company_id = cp.company_id
JOIN quality_products AS qp ON cp.product_id = qp.product_id AND f.company_id = qp.company_id AND c.id = qp.customer_id
WHERE c.id = 10
GROUP BY c.id, c.name;

"10.Como auditor, desea obtener la fecha más reciente en la que se calificó un producto."

SELECT  p.name AS Producto, MAX(qp.daterating) AS Ultima_Calificacion
FROM products AS p
JOIN quality_products AS qp ON p.id = qp.product_id
GROUP BY p.id, p.name
ORDER BY Ultima_Calificacion DESC, p.name;

"11.Como desarrollador, quiere conocer la variación de precios por categoría de producto."

SELECT cat.description AS Categoria, STDDEV(cp.price) AS Desviacion_Estandar_Precios
FROM categories AS cat
JOIN products AS p ON cat.id = p.category_id
JOIN companyproducts AS cp ON p.id = cp.product_id
GROUP BY cat.id, cat.description
ORDER BY Desviacion_Estandar_Precios DESC, cat.description;

"12.Como técnico, desea contar cuántas veces un producto fue marcado como favorito."

SELECT p.name AS Producto, COUNT(f.company_id) AS Veces_Marcado_Favorito
FROM products AS p
JOIN companyproducts AS cp ON p.id = cp.product_id
JOIN companies AS comp ON cp.company_id = comp.id
JOIN favorites AS f ON comp.id = f.company_id
GROUP BY p.id, p.name
ORDER BY Veces_Marcado_Favorito DESC, p.name;

"13.Como director, quiere saber qué porcentaje de productos han sido calificados al menos una vez."

SELECT ROUND(
    (
      COUNT(DISTINCT qp.product_id) * 100.0 / COUNT(DISTINCT p.id)
    ),
    2 ) AS Porcentaje_Productos_Evaluados
FROM products AS p
LEFT JOIN quality_products AS qp ON p.id = qp.product_id;

"14.Como analista, desea conocer el promedio de rating por encuesta."

SELECT p.description AS Encuesta, AVG(qp.rating) AS Promedio_Rating_Encuesta
FROM polls AS p
JOIN quality_products AS qp ON p.id = qp.poll_id
GROUP BY p.id, p.description
ORDER BY Promedio_Rating_Encuesta DESC, p.description;

"15.Como gestor, quiere obtener el promedio y el total de beneficios asignados a cada plan de membresía."

SELECT m.name AS Nombre_Membresia, COUNT(mb.benefit_id) AS Total_Beneficios_Asignados
FROM memberships AS m
JOIN membershipbenefits AS mb ON m.id = mb.membership_id
GROUP BY m.id, m.name
ORDER BY Total_Beneficios_Asignados DESC, m.name;

"16.Como gerente, desea obtener la media y la varianza del precio de productos por empresa."

SELECT c.name AS Nombre_Empresa, AVG(cp.price) AS Media_Precios, VAR_SAMP(cp.price) AS Varianza_Precios -- O VARIANCE(cp.price) dependiendo del SGBD
FROM companies AS c
JOIN companyproducts AS cp ON c.id = cp.company_id
GROUP BY c.id, c.name
ORDER BY Media_Precios DESC, Varianza_Precios DESC, c.name;

"17.Como cliente, quiere ver cuántos productos están disponibles en su ciudad."

SELECT c.name AS Tu_Nombre_Cliente, ci.name AS Tu_Ciudad, COUNT(DISTINCT cp.product_id) AS Total_Productos_Disponibles_En_Tu_Ciudad
FROM customers AS c
JOIN citiesormunicipalities AS ci ON c.city_id = ci.id
JOIN companies AS comp ON ci.id = comp.city_id
JOIN companyproducts AS cp ON comp.id = cp.company_id
WHERE c.id = 3 -- ¡IMPORTANTE! Reemplaza con el ID del cliente
GROUP BY c.id,c.name, ci.name;

"18.Como administrador, desea contar los productos únicos por tipo de empresa."

NO ME SALIO :c

"19.Como operador, quiere saber cuántos clientes no han registrado su correo."

SELECT COUNT(id) AS Total_Clientes_Sin_Correo
FROM customers
WHERE email IS NULL OR email = '';

"20.Como especialista, desea obtener la empresa con el mayor número de productos calificados."

SELECT c.name AS Empresa, COUNT(DISTINCT qp.product_id) AS Total_Productos_Calificados
FROM companies AS c
JOIN companyproducts AS cp ON c.id = cp.company_id
JOIN quality_products AS qp ON cp.product_id = qp.product_id AND cp.company_id = qp.company_id
GROUP BY c.id, c.name
ORDER BY Total_Productos_Calificados DESC
LIMIT 1;