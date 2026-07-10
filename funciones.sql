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

DELIMITER ;
