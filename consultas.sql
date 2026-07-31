USE pizzeria_don_piccolo;

SELECT DISTINCT c.nombre, c.telefono, p.fecha_hora
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.fecha_hora BETWEEN '2023-01-01 00:00:00' AND '2023-12-31 23:59:59';

SELECT pz.nombre, SUM(pp.cantidad) AS cantidad_vendida
FROM pizzas pz
JOIN pedido_pizzas pp ON pz.id_pizza = pp.id_pizza
GROUP BY pz.id_pizza, pz.nombre
ORDER BY cantidad_vendida DESC;

SELECT r.nombre AS repartidor, p.id_pedido, p.estado, d.hora_entrega
FROM repartidores r
JOIN domicilios d ON r.id_repartidor = d.id_repartidor
JOIN pedidos p ON d.id_pedido = p.id_pedido;

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

SELECT nombre, telefono, correo_electronico
FROM clientes
WHERE id_cliente IN (
    SELECT id_cliente
    FROM pedidos
    GROUP BY id_cliente
    HAVING COUNT(id_pedido) > 5
);

SELECT r.id_repartidor, r.nombre, COUNT(d.id_domicilio) AS total_entregas
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor
GROUP BY r.id_repartidor, r.nombre
ORDER BY total_entregas DESC;

SELECT pz.nombre AS pizza, COUNT(DISTINCT d.id_domicilio) AS total_domicilios_entregados
FROM pizzas pz
JOIN pedido_pizzas pp ON pz.id_pizza = pp.id_pizza
JOIN pedidos p ON pp.id_pedido = p.id_pedido
JOIN domicilios d ON p.id_pedido = d.id_pedido
WHERE p.estado = 'entregado'
GROUP BY pz.id_pizza, pz.nombre
ORDER BY total_domicilios_entregados DESC;

SELECT metodo_pago, COUNT(id_pedido) AS total_pedidos, SUM(total_pedido) AS ingresos_totales
FROM pedidos
WHERE estado = 'entregado'
GROUP BY metodo_pago
ORDER BY ingresos_totales DESC;

SELECT c.nombre AS cliente, COUNT(d.id_domicilio) AS total_domicilios
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
JOIN domicilios d ON p.id_pedido = d.id_pedido
GROUP BY c.id_cliente, c.nombre
HAVING total_domicilios > 1
ORDER BY total_domicilios DESC;

SELECT i.nombre AS ingrediente, SUM(pi.cantidad * pp.cantidad) AS cantidad_usada
FROM ingredientes i
JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
JOIN pedido_pizzas pp ON pi.id_pizza = pp.id_pizza
JOIN pedidos p ON pp.id_pedido = p.id_pedido
WHERE p.estado = 'entregado'
GROUP BY i.id_ingrediente, i.nombre
ORDER BY cantidad_usada DESC;

SELECT c.id_cliente, c.nombre, SUM(p.total_pedido) AS total_gastado, COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.estado = 'entregado' AND c.activo = 1
GROUP BY c.id_cliente, c.nombre
ORDER BY total_gastado DESC
LIMIT 3;

SELECT 
    nombre AS ingrediente,
    stock AS stock_actual,
    stock_minimo,
    (stock_minimo * 2) AS stock_sugerido_optimo,
    ((stock_minimo * 2) - stock) AS cantidad_a_comprar
FROM ingredientes
WHERE stock < stock_minimo;

SELECT AVG(cantidad_de_pizzas) AS promedio_pizzas_por_pedido
FROM (
    SELECT id_pedido, SUM(cantidad) AS cantidad_de_pizzas
    FROM pedido_pizzas
    GROUP BY id_pedido
) AS subconsulta;

SELECT stock INTO @stock_previo_queso FROM ingredientes WHERE id_ingrediente = 1;
SELECT stock INTO @stock_previo_pepp FROM ingredientes WHERE id_ingrediente = 2;

CALL registrar_pedido_completo(1, 'efectivo', '[{"id_pizza": 3, "cantidad": 1}]', @nuevo_pedido_id);

SELECT * FROM pedidos WHERE id_pedido = @nuevo_pedido_id;
SELECT * FROM pedido_pizzas WHERE id_pedido = @nuevo_pedido_id;

SELECT nombre, stock AS stock_actual, 
       IF(nombre='Queso Mozzarella', @stock_previo_queso - 2, @stock_previo_pepp - 3) AS stock_esperado
FROM ingredientes WHERE id_ingrediente IN (1, 2);

SELECT COUNT(*) INTO @pedidos_antes FROM pedidos;
SELECT COUNT(*) INTO @detalles_antes FROM pedido_pizzas;

UPDATE clientes 
SET telefono = '555-9999', direccion = 'Nueva Avenida Principal # 123'
WHERE id_cliente = 2;

SELECT * FROM auditoria_clientes WHERE id_cliente = 2;

UPDATE clientes 
SET activo = 0 
WHERE id_cliente = 4;

SELECT id_cliente, nombre, activo FROM clientes WHERE id_cliente = 4;

SELECT * FROM vista_pedidos_pendientes_despacho;

SELECT id_repartidor, nombre, estado FROM repartidores WHERE estado = 'disponible' LIMIT 1;

CALL despachar_pedido(@nuevo_pedido_id, 4.20, 5000.00);

SELECT * FROM pedidos WHERE id_pedido = @nuevo_pedido_id;
SELECT * FROM domicilios WHERE id_pedido = @nuevo_pedido_id;
SELECT id_repartidor, nombre, estado FROM repartidores;

SELECT nombre, stock FROM ingredientes;

SELECT id_repartidor, estado FROM repartidores WHERE id_repartidor = 1;

CALL cancelar_pedido(@nuevo_pedido_id);

SELECT nombre, stock FROM ingredientes;
SELECT id_repartidor, estado FROM repartidores WHERE id_repartidor = 1;
SELECT * FROM pedidos WHERE id_pedido = @nuevo_pedido_id;

SELECT calcular_descuento_cliente(3) AS descuento_cliente_frecuente;
SELECT calcular_descuento_cliente(1) AS descuento_cliente_comun;

SELECT calcular_comision_repartidor(1, MONTH(NOW()), YEAR(NOW())) AS comisiones_repartidor_1;



-- 1: SISTEMA DE DOMICILIOS Y REPARTIDORES


-- Entregas realizadas por cada repartidor
-- Muestra el nombre, cantidad de entregas con estado 'entregado' y el total facturado en esos pedidos.
SELECT 
    r.nombre AS repartidor,
    COUNT(d.id_domicilio) AS entregas_realizadas,
    COALESCE(SUM(p.total_pedido), 0.00) AS total_acumulado_entregado
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor
LEFT JOIN pedidos p ON d.id_pedido = p.id_pedido AND p.estado = 'entregado'
GROUP BY r.id_repartidor, r.nombre;


-- Muestra los pedidos cuya entrega tomó más de 40 minutos entre hora_salida y hora_entrega.
SELECT 
    id_pedido,
    hora_salida,
    hora_entrega,
    TIMESTAMPDIFF(MINUTE, hora_salida, hora_entrega) AS minutos_transcurridos
FROM domicilios
WHERE hora_entrega IS NOT NULL 
  AND TIMESTAMPDIFF(MINUTE, hora_salida, hora_entrega) > 40;


-- Muestra los repartidores con estado 'disponible' (activo) que no tienen ningún domicilio registrado en el sistema.
SELECT 
    r.id_repartidor,
    r.nombre,
    r.zona_asignada
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor
WHERE r.estado = 'disponible' 
  AND d.id_domicilio IS NULL;



--2: INVENTARIO, INGREDIENTES Y RECETAS


--  Cantidad de ingredientes distintos utilizados por cada pizza
SELECT 
    p.nombre AS pizza,
    p.tamano,
    COUNT(pi.id_ingrediente) AS cantidad_ingredientes_distintos
FROM pizzas p
LEFT JOIN pizza_ingredientes pi ON p.id_pizza = pi.id_pizza
GROUP BY p.id_pizza, p.nombre, p.tamano;

-- Alerta de ingredientes con stock crítico
SELECT 
    nombre AS ingrediente,
    stock AS stock_actual,
    stock_minimo,
    (stock_minimo * 2) AS stock_sugerido_optimo,
    ((stock_minimo * 2) - stock) AS cantidad_a_comprar
FROM ingredientes
WHERE stock < stock_minimo;

--  Ingredientes registrados sin asignar a ninguna pizza
SELECT 
    i.id_ingrediente,
    i.nombre AS ingrediente_sin_uso
FROM ingredientes i
LEFT JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
WHERE pi.id_pizza IS NULL;



-- 3: MENÚ DE PIZZAS E HISTORIAL DE PRECIOS


--  Resumen de precios por tipo y tamaño de pizza
SELECT 
    tipo,
    tamano,
    COUNT(id_pizza) AS cantidad_pizzas,
    ROUND(AVG(precio_base), 2) AS precio_promedio,
    MAX(precio_base) AS precio_maximo
FROM pizzas
GROUP BY tipo, tamano;

--  Pizzas con incrementos de precio superiores a 5,000 en su historial
SELECT 
    p.nombre AS pizza,
    hp.precio_anterior,
    hp.precio_nuevo,
    (hp.precio_nuevo - hp.precio_anterior) AS incremento,
    hp.fecha_cambio
FROM historial_precios hp
JOIN pizzas p ON hp.id_pizza = p.id_pizza
WHERE (hp.precio_nuevo - hp.precio_anterior) > 5000.00;

-- Pizzas del menú que nunca han sido vendidas
SELECT 
    p.id_pizza,
    p.nombre,
    p.precio_base
FROM pizzas p
LEFT JOIN pedido_pizzas pp ON p.id_pizza = pp.id_pizza
WHERE pp.id_pizza IS NULL;



--  VENTAS Y FIDELIZACIÓN DE CLIENTES


-- Ventas por cliente (pedidos entregados)
SELECT 
    c.nombre AS cliente,
    COUNT(p.id_pedido) AS total_pedidos_realizados,
    COALESCE(SUM(p.total_pedido), 0.00) AS total_gastado
FROM clientes c
LEFT JOIN pedidos p ON c.id_cliente = p.id_cliente AND p.estado = 'entregado'
GROUP BY c.id_cliente, c.nombre;

--  Clientes VIP (gasto acumulado > 50,000)
SELECT 
    c.nombre AS cliente,
    SUM(p.total_pedido) AS gasto_total
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.estado = 'entregado'
GROUP BY c.id_cliente, c.nombre
HAVING gasto_total > 50000.00;

--  Clientes registrados sin pedidos
SELECT 
    c.id_cliente,
    c.nombre AS cliente_sin_pedidos,
    c.correo_electronico
FROM clientes c
LEFT JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.id_pedido IS NULL;


