USE pizzeria_don_piccolo;

CREATE OR REPLACE VIEW vista_resumen_clientes AS
SELECT 
    c.nombre AS cliente,
    COUNT(p.id_pedido) AS cantidad_pedidos,
    SUM(p.total_pedido) AS total_gastado
FROM clientes c
LEFT JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre;

CREATE OR REPLACE VIEW vista_desempeno_repartidores AS
SELECT 
    r.nombre AS repartidor,
    r.zona_asignada AS zona,
    COUNT(d.id_domicilio) AS numero_entregas,
    AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)) AS tiempo_promedio_minutos
FROM repartidores r
JOIN domicilios d ON r.id_repartidor = d.id_repartidor
WHERE d.hora_entrega IS NOT NULL
GROUP BY r.id_repartidor, r.nombre, r.zona_asignada;

CREATE OR REPLACE VIEW vista_stock_critico AS
SELECT 
    nombre AS ingrediente,
    stock,
    stock_minimo
FROM ingredientes
WHERE stock < stock_minimo;

CREATE OR REPLACE VIEW vista_pedidos_pendientes_despacho AS
SELECT 
    p.id_pedido,
    c.nombre AS cliente,
    c.telefono,
    c.direccion,
    p.fecha_hora AS fecha_pedido,
    TIMESTAMPDIFF(MINUTE, p.fecha_hora, NOW()) AS minutos_transcurridos,
    p.estado,
    p.total_pedido
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE p.estado IN ('pendiente', 'en preparación') AND c.activo = 1;

CREATE OR REPLACE VIEW vista_rendimiento_mensual_pizzas AS
SELECT 
    YEAR(p.fecha_hora) AS anio,
    MONTHNAME(p.fecha_hora) AS mes,
    pz.nombre AS pizza,
    SUM(pp.cantidad) AS unidades_vendidas,
    SUM(pp.cantidad * pp.precio_unitario) AS ingresos_totales
FROM pizzas pz
JOIN pedido_pizzas pp ON pz.id_pizza = pp.id_pizza
JOIN pedidos p ON pp.id_pedido = p.id_pedido
WHERE p.estado = 'entregado'
GROUP BY YEAR(p.fecha_hora), MONTH(p.fecha_hora), MONTHNAME(p.fecha_hora), pz.id_pizza, pz.nombre
ORDER BY anio DESC, MONTH(p.fecha_hora) DESC, unidades_vendidas DESC;

-- [MÓDULO 1] Vista: vista_desempeno_repartidor
-- Muestra el nombre del repartidor, el total de entregas y el promedio en minutos de entrega.
CREATE OR REPLACE VIEW vista_desempeno_repartidor AS
SELECT 
    r.nombre AS nombre_repartidor,
    COUNT(d.id_domicilio) AS entregas_totales,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)), 1) AS promedio_minutos_entrega
FROM repartidores r
JOIN domicilios d ON r.id_repartidor = d.id_repartidor
WHERE d.estado = 'entregado' AND d.hora_entrega IS NOT NULL
GROUP BY r.id_repartidor, r.nombre;

-- [MÓDULO 2] Vista: vista_inventario_critico
-- Muestra ingredientes bajo stock mínimo, su estado de alerta y cantidad sugerida de compra.
CREATE OR REPLACE VIEW vista_inventario_critico AS
SELECT 
    nombre AS ingrediente,
    stock AS stock_actual,
    stock_minimo,
    CASE 
        WHEN stock = 0 THEN 'Agotado'
        ELSE 'Stock Crítico'
    END AS estado_alerta,
    ((stock_minimo * 2) - stock) AS sugerencia_compra
FROM ingredientes
WHERE stock < stock_minimo;

-- [MÓDULO 3] Vista: vista_resumen_precios
-- Muestra el precio actual de la pizza, la cantidad de cambios históricos y el promedio del incremento.
CREATE OR REPLACE VIEW vista_resumen_precios AS
SELECT 
    p.id_pizza,
    p.nombre AS pizza,
    p.precio_base AS precio_actual,
    COUNT(hp.id_historial) AS modificaciones_realizadas,
    ROUND(AVG(hp.precio_nuevo - hp.precio_anterior), 2) AS promedio_monto_incremento
FROM pizzas p
LEFT JOIN historial_precios hp ON p.id_pizza = hp.id_pizza
GROUP BY p.id_pizza, p.nombre, p.precio_base;

-- Nota: La [vista_resumen_clientes] requerida para el [MÓDULO 4] ya está implementada al inicio de este archivo.


