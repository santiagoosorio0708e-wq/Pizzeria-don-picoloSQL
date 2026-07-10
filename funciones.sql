USE pizzeria_don_piccolo;

DELIMITER //

-- Función para calcular el total de un pedido
CREATE FUNCTION calcular_total_pedido(p_id_pedido INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_pizzas DECIMAL(10,2) DEFAULT 0;
    DECLARE costo_envio DECIMAL(10,2) DEFAULT 0;
    DECLARE iva DECIMAL(10,2) DEFAULT 0.19; -- Asumiendo 19% de IVA
    DECLARE total_final DECIMAL(10,2) DEFAULT 0;

    -- Obtener la suma del costo de las pizzas del pedido
    SELECT COALESCE(SUM(cantidad * precio_unitario), 0) INTO total_pizzas
    FROM pedido_pizzas
    WHERE id_pedido = p_id_pedido;

    -- Obtener el costo de envío
    SELECT COALESCE(costo_envio, 0) INTO costo_envio
    FROM domicilios
    WHERE id_pedido = p_id_pedido;

    -- Calcular el total final con IVA
    SET total_final = (total_pizzas + costo_envio) * (1 + iva);

    RETURN total_final;
END //

-- Función para calcular la ganancia neta diaria
-- Asumiremos que el costo de cada ingrediente es un valor constante para simplificar o tendríamos que agregar una columna de costo en la tabla ingredientes.
-- Añadiremos una estimación de costo base para calcular la ganancia (ej. 40% del precio de la pizza es costo de ingredientes)
CREATE FUNCTION calcular_ganancia_diaria(p_fecha DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_ventas DECIMAL(10,2) DEFAULT 0;
    DECLARE total_costos DECIMAL(10,2) DEFAULT 0;
    DECLARE ganancia_neta DECIMAL(10,2) DEFAULT 0;

    -- Calcular las ventas totales del día (solo pedidos entregados)
    SELECT COALESCE(SUM(total_pedido), 0) INTO total_ventas
    FROM pedidos
    WHERE DATE(fecha_hora) = p_fecha AND estado = 'entregado';

    -- Calcular los costos (estimado al 40% del precio base de las pizzas para simplificar)
    SELECT COALESCE(SUM(pp.cantidad * pp.precio_unitario * 0.40), 0) INTO total_costos
    FROM pedido_pizzas pp
    JOIN pedidos p ON pp.id_pedido = p.id_pedido
    WHERE DATE(p.fecha_hora) = p_fecha AND p.estado = 'entregado';

    SET ganancia_neta = total_ventas - total_costos;
    RETURN ganancia_neta;
END //

-- Procedimiento para registrar hora de entrega y cambiar estado
CREATE PROCEDURE registrar_entrega_pedido(IN p_id_domicilio INT, IN p_hora_entrega DATETIME)
BEGIN
    DECLARE v_id_pedido INT;

    -- Obtener el ID del pedido asociado al domicilio
    SELECT id_pedido INTO v_id_pedido
    FROM domicilios
    WHERE id_domicilio = p_id_domicilio;

    -- Actualizar la hora de entrega
    UPDATE domicilios
    SET hora_entrega = p_hora_entrega
    WHERE id_domicilio = p_id_domicilio;

    -- Cambiar el estado del pedido
    UPDATE pedidos
    SET estado = 'entregado'
    WHERE id_pedido = v_id_pedido;
END //

DELIMITER ;
