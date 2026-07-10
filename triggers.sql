USE pizzeria_don_piccolo;

DELIMITER //

CREATE TRIGGER tr_actualizar_stock_ingredientes
AFTER INSERT ON pedido_pizzas
FOR EACH ROW
BEGIN
    UPDATE ingredientes i
    INNER JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
    SET i.stock = i.stock - (pi.cantidad * NEW.cantidad)
    WHERE pi.id_pizza = NEW.id_pizza;
END //

CREATE TRIGGER tr_auditoria_precio_pizza
AFTER UPDATE ON pizzas
FOR EACH ROW
BEGIN
    IF OLD.precio_base <> NEW.precio_base THEN
        INSERT INTO historial_precios (id_pizza, precio_anterior, precio_nuevo)
        VALUES (OLD.id_pizza, OLD.precio_base, NEW.precio_base);
    END IF;
END //

CREATE TRIGGER tr_liberar_repartidor
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    IF OLD.hora_entrega IS NULL AND NEW.hora_entrega IS NOT NULL THEN
        UPDATE repartidores
        SET estado = 'disponible'
        WHERE id_repartidor = NEW.id_repartidor;
    END IF;
END //

DELIMITER ;
