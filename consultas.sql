USE pizzeria_don_piccolo;

SELECT DISTINCT c.nombre, c.telefono, p.fecha_hora
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.fecha_hora BETWEEN '2023-01-01 00:00:00' AND '2023-12-31 23:59:59';

-- Pizzas más vendidas (GROUP BY y COUNT/SUM)
SELECT pz.nombre, SUM(pp.cantidad) AS cantidad_vendida
FROM pizzas pz
JOIN pedido_pizzas pp ON pz.id_pizza = pp.id_pizza
GROUP BY pz.id_pizza, pz.nombre
ORDER BY cantidad_vendida DESC;

SELECT r.nombre AS repartidor, p.id_pedido, p.estado, d.hora_entrega
FROM repartidores r
JOIN domicilios d ON r.id_repartidor = d.id_repartidor
JOIN pedidos p ON d.id_pedido = p.id_pedido;

-- Promedio de entrega por zona (AVG y JOIN)
SELECT r.zona_asignada, 
       AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)) AS tiempo_promedio_entrega_minutos
FROM repartidores r
JOIN domicilios d ON r.id_repartidor = d.id_repartidor
WHERE d.hora_entrega IS NOT NULL
GROUP BY r.zona_asignada;

SELECT c.nombre, SUM(p.total_pedido) AS gasto_total
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre
HAVING gasto_total > 50000;

SELECT id_pizza, nombre, tipo, precio_base
FROM pizzas
WHERE nombre LIKE '%Queso%';

-- Subconsulta para obtener los clientes frecuentes (más de 5 pedidos mensuales)
SELECT nombre, telefono, correo_electronico
FROM clientes
WHERE id_cliente IN (
    SELECT id_cliente
    FROM pedidos
    GROUP BY id_cliente
    HAVING COUNT(id_pedido) > 5
);

-- 8. Cantidad de entregas a domicilio realizadas por cada repartidor
SELECT r.id_repartidor, r.nombre, COUNT(d.id_domicilio) AS total_entregas
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor
GROUP BY r.id_repartidor, r.nombre
ORDER BY total_entregas DESC;

-- 9. Cuántas entregas a domicilio se han realizado por cada tipo/nombre de pizza del menú
SELECT pz.nombre AS pizza, COUNT(DISTINCT d.id_domicilio) AS total_domicilios_entregados
FROM pizzas pz
JOIN pedido_pizzas pp ON pz.id_pizza = pp.id_pizza
JOIN pedidos p ON pp.id_pedido = p.id_pedido
JOIN domicilios d ON p.id_pedido = d.id_pedido
WHERE p.estado = 'entregado'
GROUP BY pz.id_pizza, pz.nombre
ORDER BY total_domicilios_entregados DESC;

-- 10. Ingresos totales generados y cantidad de pedidos agrupados por método de pago
SELECT metodo_pago, COUNT(id_pedido) AS total_pedidos, SUM(total_pedido) AS ingresos_totales
FROM pedidos
WHERE estado = 'entregado'
GROUP BY metodo_pago
ORDER BY ingresos_totales DESC;

-- 11. Clientes frecuentes que han solicitado entrega a domicilio en más de una ocasión
SELECT c.nombre AS cliente, COUNT(d.id_domicilio) AS total_domicilios
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
JOIN domicilios d ON p.id_pedido = d.id_pedido
GROUP BY c.id_cliente, c.nombre
HAVING total_domicilios > 1
ORDER BY total_domicilios DESC;

-- 12. Consumo acumulado de ingredientes basados en las pizzas que han sido entregadas con éxito
SELECT i.nombre AS ingrediente, SUM(pi.cantidad * pp.cantidad) AS cantidad_usada
FROM ingredientes i
JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
JOIN pedido_pizzas pp ON pi.id_pizza = pp.id_pizza
JOIN pedidos p ON pp.id_pedido = p.id_pedido
WHERE p.estado = 'entregado'
GROUP BY i.id_ingrediente, i.nombre
ORDER BY cantidad_usada DESC;


-- 13. Ranking de clientes VIP (los 3 clientes que más dinero han gastado en la pizzería)
SELECT c.id_cliente, c.nombre, SUM(p.total_pedido) AS total_gastado, COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.estado = 'entregado' AND c.activo = 1
GROUP BY c.id_cliente, c.nombre
ORDER BY total_gastado DESC
LIMIT 3;

-- 14. Reporte de compra sugerida de insumos (ingredientes con stock menor al mínimo)
SELECT 
    nombre AS ingrediente,
    stock AS stock_actual,
    stock_minimo,
    (stock_minimo * 2) AS stock_sugerido_optimo,
    ((stock_minimo * 2) - stock) AS cantidad_a_comprar
FROM ingredientes
WHERE stock < stock_minimo;

-- 15. Promedio de pizzas solicitadas por pedido
SELECT AVG(cantidad_de_pizzas) AS promedio_pizzas_por_pedido
FROM (
    SELECT id_pedido, SUM(cantidad) AS cantidad_de_pizzas
    FROM pedido_pizzas
    GROUP BY id_pedido
) AS subconsulta;


-- Pruebas de funcionamiento - Registrar pedido completo
-- Insertamos un pedido para el cliente 1 (Juan Perez) comprando 1 Pizza Pepperoni Clásica (id: 3)
SELECT '--- PRUEBA 1: COMPRA EXITOSA ---' AS log;
SELECT stock INTO @stock_previo_queso FROM ingredientes WHERE id_ingrediente = 1;
SELECT stock INTO @stock_previo_pepp FROM ingredientes WHERE id_ingrediente = 2;

-- Ejecutamos la transacción
CALL registrar_pedido_completo(1, 'efectivo', '[{"id_pizza": 3, "cantidad": 1}]', @nuevo_pedido_id);

-- Consultamos el pedido creado y sus detalles
SELECT * FROM pedidos WHERE id_pedido = @nuevo_pedido_id;
SELECT * FROM pedido_pizzas WHERE id_pedido = @nuevo_pedido_id;

-- Validamos que el stock disminuyó correctamente
SELECT nombre, stock AS stock_actual, 
       IF(nombre='Queso Mozzarella', @stock_previo_queso - 2, @stock_previo_pepp - 3) AS stock_esperado
FROM ingredientes WHERE id_ingrediente IN (1, 2);


-- Caso 2: Compra Fallida por Stock Insuficiente (Gatilla ROLLBACK y SIGNAL)
-- Intentamos comprar 50 Pizzas Pepperoni Clásicas (id: 3), lo cual requiere 150 unidades de Pepperoni (solo quedan menos de 50)
SELECT '--- PRUEBA 2: COMPRA CON FALLA DE STOCK (DEBE HACER ROLLBACK) ---' AS log;
SELECT COUNT(*) INTO @pedidos_antes FROM pedidos;
SELECT COUNT(*) INTO @detalles_antes FROM pedido_pizzas;

-- Esto levantará un error SQLSTATE '45000' indicando que no hay suficiente stock
-- y anulará todo el pedido (no se crea el pedido ni se descuenta stock)
-- Ejecutar en una consola para ver el mensaje de error:
-- CALL registrar_pedido_completo(1, 'tarjeta', '[{"id_pizza": 3, "cantidad": 50}]', @nuevo_pedido_id_fallido);

-- Verificar que no se insertó nada
-- SELECT COUNT(*) AS pedidos_actuales, @pedidos_antes AS pedidos_anteriores FROM pedidos;
-- SELECT COUNT(*) AS detalles_actuales, @detalles_antes AS detalles_anteriores FROM pedido_pizzas;


-- Pruebas de funcionamiento - Borrado lógico y auditoría
SELECT '--- PRUEBA 3: MODIFICACIÓN DE CLIENTE (AUDITORÍA) ---' AS log;
UPDATE clientes 
SET telefono = '555-9999', direccion = 'Nueva Avenida Principal # 123'
WHERE id_cliente = 2;

-- Ver los registros de la tabla de auditoría para el cliente 2
SELECT * FROM auditoria_clientes WHERE id_cliente = 2;


-- Caso 2: Borrado Lógico de un cliente (Desactivación)
SELECT '--- PRUEBA 4: BORRADO LÓGICO (DESACTIVACIÓN) ---' AS log;
UPDATE clientes 
SET activo = 0 
WHERE id_cliente = 4; -- Desactivar a Ana Silva

-- Verificar que el cliente cambió su estado pero sigue existiendo físicamente
SELECT id_cliente, nombre, activo FROM clientes WHERE id_cliente = 4;

-- Consultar la vista de pedidos pendientes de despacho
-- (Debería excluir los pedidos asociados al cliente desactivado 4 si los tuviera)
SELECT * FROM vista_pedidos_pendientes_despacho;


-- Pruebas de funcionamiento - Despacho automatizado
SELECT '--- PRUEBA 5: DESPACHO EXITOSO DE PEDIDO ---' AS log;
-- Consultamos el estado inicial del primer repartidor disponible y del pedido
SELECT id_repartidor, nombre, estado FROM repartidores WHERE estado = 'disponible' LIMIT 1;

-- Despachamos el pedido id 6 (está en estado 'pendiente') a una distancia de 4.2 km y un costo de envío de 5000.00
CALL despachar_pedido(6, 4.20, 5000.00);

-- Verificamos el resultado: repartidor ocupado, pedido 'en camino' y total recalculado con envío + IVA
SELECT * FROM pedidos WHERE id_pedido = 6;
SELECT * FROM domicilios WHERE id_pedido = 6;
SELECT id_repartidor, nombre, estado FROM repartidores;


-- Caso 2: Cancelación de Pedidos (Dispara tr_pedido_cancelado)
SELECT '--- PRUEBA 6: CANCELACIÓN DE PEDIDO ---' AS log;
-- Consultamos el stock inicial de ingredientes para la pizza Hawaiana (ingredientes: piña, queso, jamón, etc)
SELECT nombre, stock FROM ingredientes;

-- Consultamos el repartidor del pedido 6 (que despachamos antes)
SELECT id_repartidor, estado FROM repartidores WHERE id_repartidor = 1;

-- Cancelamos el pedido 6
CALL cancelar_pedido(6);

-- Verificamos que el stock fue devuelto y el repartidor 1 fue liberado automáticamente
SELECT nombre, stock FROM ingredientes;
SELECT id_repartidor, estado FROM repartidores WHERE id_repartidor = 1;
SELECT * FROM pedidos WHERE id_pedido = 6;





