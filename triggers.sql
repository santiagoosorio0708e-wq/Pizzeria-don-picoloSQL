USE pizzeria_don_piccolo;

DELIMITER //

-- Trigger para actualizar stock de ingredientes al insertar un pedido
CREATE TRIGGER tr_actualizar_stock_ingredientes
AFTER INSERT ON pedido_pizzas
FOR EACH ROW
BEGIN
    -- Se reduce el stock de los ingredientes que componen la pizza
    -- multiplicando por la cantidad de pizzas solicitadas
    UPDATE ingredientes i
    INNER JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
    SET i.stock = i.stock - (pi.cantidad * NEW.cantidad)
    WHERE pi.id_pizza = NEW.id_pizza;
END //

-- Trigger de auditoría para cambios de precio en pizzas
CREATE TRIGGER tr_auditoria_precio_pizza
AFTER UPDATE ON pizzas
FOR EACH ROW
BEGIN
    IF OLD.precio_base <> NEW.precio_base THEN
        INSERT INTO historial_precios (id_pizza, precio_anterior, precio_nuevo)
        VALUES (OLD.id_pizza, OLD.precio_base, NEW.precio_base);
    END IF;
END //

-- Trigger para liberar al repartidor cuando termina el domicilio
CREATE TRIGGER tr_liberar_repartidor
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    -- Si se registró la hora de entrega y antes estaba vacía
    IF OLD.hora_entrega IS NULL AND NEW.hora_entrega IS NOT NULL THEN
        UPDATE repartidores
        SET estado = 'disponible'
        WHERE id_repartidor = NEW.id_repartidor;
    END IF;
END //

DELIMITER ;
