USE pizzeria_don_piccolo;

DELIMITER //

CREATE FUNCTION calcular_total_pedido(p_id_pedido INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_pizzas DECIMAL(10,2) DEFAULT 0;
    DECLARE costo_envio DECIMAL(10,2) DEFAULT 0;
    DECLARE iva DECIMAL(10,2) DEFAULT 0.19;
    DECLARE total_final DECIMAL(10,2) DEFAULT 0;

    SELECT COALESCE(SUM(cantidad * precio_unitario), 0) INTO total_pizzas
    FROM pedido_pizzas
    WHERE id_pedido = p_id_pedido;

    SELECT COALESCE(costo_envio, 0) INTO costo_envio
    FROM domicilios
    WHERE id_pedido = p_id_pedido;

    SET total_final = (total_pizzas + costo_envio) * (1 + iva);

    RETURN total_final;
END //

CREATE FUNCTION calcular_ganancia_diaria(p_fecha DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_ventas DECIMAL(10,2) DEFAULT 0;
    DECLARE total_costos DECIMAL(10,2) DEFAULT 0;
    DECLARE ganancia_neta DECIMAL(10,2) DEFAULT 0;

    SELECT COALESCE(SUM(total_pedido), 0) INTO total_ventas
    FROM pedidos
    WHERE DATE(fecha_hora) = p_fecha AND estado = 'entregado';

    SELECT COALESCE(SUM(pp.cantidad * pp.precio_unitario * 0.40), 0) INTO total_costos
    FROM pedido_pizzas pp
    JOIN pedidos p ON pp.id_pedido = p.id_pedido
    WHERE DATE(p.fecha_hora) = p_fecha AND p.estado = 'entregado';

    SET ganancia_neta = total_ventas - total_costos;
    RETURN ganancia_neta;
END //

CREATE PROCEDURE registrar_entrega_pedido(IN p_id_domicilio INT, IN p_hora_entrega DATETIME)
BEGIN
    DECLARE v_id_pedido INT;

    SELECT id_pedido INTO v_id_pedido
    FROM domicilios
    WHERE id_domicilio = p_id_domicilio;

    UPDATE domicilios
    SET hora_entrega = p_hora_entrega
    WHERE id_domicilio = p_id_domicilio;

    UPDATE pedidos
    SET estado = 'entregado'
    WHERE id_pedido = v_id_pedido;
END //

CREATE PROCEDURE registrar_pedido_completo(
    IN p_id_cliente INT,
    IN p_metodo_pago VARCHAR(50),
    IN p_pizzas_json JSON,
    OUT p_id_pedido_creado INT
)
BEGIN
    DECLARE v_id_pedido INT;
    DECLARE v_id_pizza INT;
    DECLARE v_cantidad INT;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_nombre_ingrediente VARCHAR(100);
    DECLARE i INT DEFAULT 0;
    DECLARE n INT DEFAULT 0;

    -- Manejo de excepciones para deshacer los cambios en caso de cualquier error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Iniciamos la transacción
    START TRANSACTION;

    -- Validar que el cliente exista
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = p_id_cliente) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El cliente no existe.';
    END IF;

    -- Crear el registro principal del pedido
    INSERT INTO pedidos (id_cliente, metodo_pago, estado, total_pedido)
    VALUES (p_id_cliente, p_metodo_pago, 'pendiente', 0);
    
    SET v_id_pedido = LAST_INSERT_ID();
    SET n = JSON_LENGTH(p_pizzas_json);

    -- Ciclo para procesar las pizzas contenidas en el JSON
    WHILE i < n DO
        SET v_id_pizza = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_pizzas_json, CONCAT('$[', i, '].id_pizza'))) AS SIGNED);
        SET v_cantidad = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_pizzas_json, CONCAT('$[', i, '].cantidad'))) AS SIGNED);

        -- Obtener y validar el precio base de la pizza
        SET v_precio = NULL;
        SELECT precio_base INTO v_precio FROM pizzas WHERE id_pizza = v_id_pizza;

        IF v_precio IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Una o más pizzas especificadas no existen.';
        END IF;

        IF v_cantidad <= 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: La cantidad de pizzas debe ser mayor a 0.';
        END IF;

        -- Insertar el detalle del pedido (esto disparará el trigger tr_actualizar_stock_ingredientes)
        INSERT INTO pedido_pizzas (id_pedido, id_pizza, cantidad, precio_unitario)
        VALUES (v_id_pedido, v_id_pizza, v_cantidad, v_precio);

        SET i = i + 1;
    END WHILE;

    -- Verificar si el stock de algún ingrediente cayó por debajo de cero
    IF EXISTS (SELECT 1 FROM ingredientes WHERE stock < 0) THEN
        SELECT nombre INTO v_nombre_ingrediente FROM ingredientes WHERE stock < 0 LIMIT 1;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = CONCAT('Error: Stock insuficiente para el ingrediente: ', v_nombre_ingrediente);
    END IF;

    -- Si el pedido es a domicilio, podemos calcular el total final considerando el envío si existiera.
    -- Para este procedimiento base, calculamos el total de las pizzas asociadas.
    SELECT COALESCE(SUM(cantidad * precio_unitario), 0) INTO v_total
    FROM pedido_pizzas
    WHERE id_pedido = v_id_pedido;

    -- Si hay un domicilio registrado para este pedido, sumar costo de envío + IVA
    -- (Nota: la función calcular_total_pedido asume que el domicilio ya podría existir, pero si es un pedido nuevo
    -- recién ingresado, calculamos directamente el total acumulado de las pizzas más IVA básico 19%)
    SET v_total = v_total * 1.19;

    UPDATE pedidos
    SET total_pedido = v_total
    WHERE id_pedido = v_id_pedido;

    -- Confirmar los cambios
    COMMIT;

    SET p_id_pedido_creado = v_id_pedido;
END //

CREATE PROCEDURE despachar_pedido(
    IN p_id_pedido INT,
    IN p_distancia_km DECIMAL(5,2),
    IN p_costo_envio DECIMAL(10,2)
)
BEGIN
    DECLARE v_id_repartidor INT DEFAULT NULL;
    DECLARE v_estado_pedido VARCHAR(50);

    -- Manejador de excepciones
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Validar que el pedido exista y ver su estado
    SELECT estado INTO v_estado_pedido FROM pedidos WHERE id_pedido = p_id_pedido;

    IF v_estado_pedido IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El pedido especificado no existe.';
    END IF;

    IF v_estado_pedido NOT IN ('pendiente', 'en preparación') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El pedido no está en un estado que permita despacho (debe ser pendiente o en preparación).';
    END IF;

    -- Validar si ya cuenta con un domicilio registrado
    IF EXISTS (SELECT 1 FROM domicilios WHERE id_pedido = p_id_pedido) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Este pedido ya tiene una entrega a domicilio registrada.';
    END IF;

    -- Buscar el primer repartidor disponible
    SELECT id_repartidor INTO v_id_repartidor
    FROM repartidores
    WHERE estado = 'disponible'
    LIMIT 1;

    IF v_id_repartidor IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No hay repartidores disponibles en este momento.';
    END IF;

    -- Marcar al repartidor como no disponible
    UPDATE repartidores
    SET estado = 'no disponible'
    WHERE id_repartidor = v_id_repartidor;

    -- Crear el registro en la tabla de domicilios
    INSERT INTO domicilios (id_pedido, id_repartidor, hora_salida, distancia_km, costo_envio)
    VALUES (p_id_pedido, v_id_repartidor, NOW(), p_distancia_km, p_costo_envio);

    -- Cambiar el estado del pedido a 'en camino'
    UPDATE pedidos
    SET estado = 'en camino'
    WHERE id_pedido = p_id_pedido;

    -- Recalcular el total del pedido usando la función oficial calcular_total_pedido (que ahora sumará el costo_envio)
    UPDATE pedidos
    SET total_pedido = calcular_total_pedido(p_id_pedido)
    WHERE id_pedido = p_id_pedido;

    COMMIT;
END //

CREATE PROCEDURE cancelar_pedido(
    IN p_id_pedido INT
)
BEGIN
    DECLARE v_estado VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT estado INTO v_estado FROM pedidos WHERE id_pedido = p_id_pedido;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El pedido especificado no existe.';
    END IF;

    IF v_estado = 'entregado' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede cancelar un pedido que ya ha sido entregado.';
    END IF;

    IF v_estado = 'cancelado' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Este pedido ya se encuentra cancelado.';
    END IF;

    -- Actualizar el estado
    UPDATE pedidos
    SET estado = 'cancelado'
    WHERE id_pedido = p_id_pedido;

    COMMIT;
END //

DELIMITER ;

