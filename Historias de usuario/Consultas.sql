1.Como analista, quiero listar todos los productos con su empresa asociada y el precio más bajo por ciudad.

SELECT p.name AS nombre, cps.precio AS precio, c.name AS nombre_compañia
FROM companies as c
JOIN companyproducts AS cps ON cps.company_id = c.id
JOIN product as p ON p.id = cps.product_id;