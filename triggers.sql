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

CREATE TRIGGER tr_auditoria_clientes
AFTER UPDATE ON clientes
FOR EACH ROW
BEGIN
    IF OLD.nombre <> NEW.nombre THEN
        INSERT INTO auditoria_clientes (id_cliente, campo_modificado, valor_anterior, valor_nuevo, usuario)
        VALUES (OLD.id_cliente, 'nombre', OLD.nombre, NEW.nombre, USER());
    END IF;
    IF OLD.telefono <> NEW.telefono THEN
        INSERT INTO auditoria_clientes (id_cliente, campo_modificado, valor_anterior, valor_nuevo, usuario)
        VALUES (OLD.id_cliente, 'telefono', OLD.telefono, NEW.telefono, USER());
    END IF;
    IF OLD.direccion <> NEW.direccion THEN
        INSERT INTO auditoria_clientes (id_cliente, campo_modificado, valor_anterior, valor_nuevo, usuario)
        VALUES (OLD.id_cliente, 'direccion', OLD.direccion, NEW.direccion, USER());
    END IF;
    IF OLD.correo_electronico <> NEW.correo_electronico THEN
        INSERT INTO auditoria_clientes (id_cliente, campo_modificado, valor_anterior, valor_nuevo, usuario)
        VALUES (OLD.id_cliente, 'correo_electronico', OLD.correo_electronico, NEW.correo_electronico, USER());
    END IF;
    IF OLD.activo <> NEW.activo THEN
        INSERT INTO auditoria_clientes (id_cliente, campo_modificado, valor_anterior, valor_nuevo, usuario)
        VALUES (OLD.id_cliente, 'activo', CAST(OLD.activo AS CHAR), CAST(NEW.activo AS CHAR), USER());
    END IF;
END //

CREATE TRIGGER tr_pedido_cancelado
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado AND NEW.estado = 'cancelado' THEN
        -- 1. Liberar repartidor si estaba asignado
        UPDATE repartidores r
        INNER JOIN domicilios d ON r.id_repartidor = d.id_repartidor
        SET r.estado = 'disponible'
        WHERE d.id_pedido = NEW.id_pedido;

        -- 2. Devolver stock de ingredientes
        UPDATE ingredientes i
        INNER JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
        INNER JOIN pedido_pizzas pp ON pi.id_pizza = pp.id_pizza
        SET i.stock = i.stock + (pi.cantidad * pp.cantidad)
        WHERE pp.id_pedido = NEW.id_pedido;
    END IF;
END //

DELIMITER ;
