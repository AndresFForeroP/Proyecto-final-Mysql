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

'RESULTADO
+---------------------------+------------------------+---------+----------------------+
| producto                  | empresa                | precio  | ciudad               |
+---------------------------+------------------------+---------+----------------------+
| Aceite de oliva           | ElectroHogar           |   79.99 | NORCASIA             |
| Aire acondicionado        | Óptica Visión          |   49.99 | CALAMAR              |
| Analgésico                | Farmacia Salud         |    5.99 | SAN LUIS             |
| Analgésico                | Café Aroma             |   12.99 | BUENAVISTA           |
| Analgésico                | Restaurante Sabor      |   12.99 | SAN JACINTO          |
| Anillo de plata           | Farmacia Vida          |   59.99 | ABEJORRAL            |
| Anillo de plata           | Joyas Brillantes       |   89.99 | SAN JERONIMO         |
| Arroz premium             | SuperAhorro            |     3.5 | SORA                 |
| Arroz premium             | Ropa Moda              |   49.99 | SALGAR               |
| Bicicleta montañera       | Gimnasio Power         |   39.99 | VILLANUEVA           |
| Café premium              | Belleza Total          |   39.99 | PUEBLORRICO          |
| Camiseta básica           | Ropa Moda              |   25.99 | SALGAR               |
| Camiseta básica           | Moda Elegante          |   25.99 | EL CARMEN DE VIBORAL |
| Cepillo dental eléctrico  | ElectroHogar           |  599.99 | NORCASIA             |
| Cerveza artesanal         | Gimnasio Power         |  499.99 | VILLANUEVA           |
| Cerveza artesanal         | Deportes Extremos      |  499.99 | SUAN                 |
| Collar de oro             | Joyeria Lux            |   89.99 | CAUCASIA             |
| Crema hidratante          | Clínica Moderna        |    15.5 | ENVIGADO             |
| Crema hidratante          | SuperDescuentos        |   14.99 | TURMEQUE             |
| Habitación estándar       | Hotel Plaza            |      75 | BURITICA             |
| Habitación estándar       | Hotel Paraíso          |      75 | ABEJORRAL            |
| Habitación estándar       | Café Aroma             |   15.99 | BUENAVISTA           |
| Juego de ollas            | Gasolinera Express     |   29.99 | ENTRERRIOS           |
| Juego de sábanas          | ElectroHogar           |  349.99 | NORCASIA             |
| Laptop ultradelgada       | SuperDescuentos        |  129.99 | TURMEQUE             |
| Libro bestseller          | Hotel Plaza            |   89.99 | BURITICA             |
| Libro bestseller          | Librería Conocimiento  |   22.99 | CANDELARIA           |
| Menú del día              | Restaurante La Casona  |   12.99 | CUBARA               |
| Menú del día              | Restaurante Sabor      |   12.99 | SAN JACINTO          |
| Mochila resistente        | Muebles Elegantes      |  149.99 | PUERTO BOYACA        |
| Pantalón vaquero          | TechWorld              |  799.99 | MACEO                |
| Parrilla eléctrica        | Belleza Total          |   49.99 | PUEBLORRICO          |
| Parrilla eléctrica        | Farmacia Vida          |   49.99 | ABEJORRAL            |
| Reloj inteligente         | Deportes Extremos      |  199.99 | SUAN                 |
| Robot aspirador           | Óptica Visión          |   59.99 | CALAMAR              |
| Set de maquillaje         | Muebles Elegantes      |  199.99 | PUERTO BOYACA        |
| Smartphone                | Gasolinera Express     |  599.99 | ENTRERRIOS           |
| Suscripción gimnasio      | Gimnasio Activo        |      45 | SALGAR               |
| Suscripción gimnasio      | Gasolinera Rápida      |      45 | ARMENIA              |
| Televisor 55"             | TechWorld              |  899.99 | MACEO                |
| Zapatos formales          | TechWorld              | 1299.99 | MACEO                |
| Zapatos formales          | Joyeria Lux            |  299.99 | CAUCASIA             |
+---------------------------+------------------------+---------+----------------------+
42 rows in set (0,00 sec)'


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

