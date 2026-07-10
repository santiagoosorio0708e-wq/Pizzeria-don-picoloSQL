USE pizzeria_don_piccolo;

INSERT INTO clientes (nombre, telefono, direccion, correo_electronico) VALUES
('Juan Perez', '555-0192', 'Calle 10 # 4-50', 'juan.perez@email.com'),
('Maria Gomez', '555-0183', 'Av. Santander # 45-12', 'maria.gomez@email.com'),
('Carlos Ruiz', '555-0174', 'Carrera 15 # 8-30', 'carlos.ruiz@email.com'),
('Ana Silva', '555-0165', 'Calle 80 # 12-25', 'ana.silva@email.com');

INSERT INTO ingredientes (nombre, stock, stock_minimo) VALUES
('Queso Mozzarella', 100, 15),
('Pepperoni', 50, 10),
('Champiñones', 8, 10),
('Pimentón', 30, 8),
('Jamón', 40, 10),
('Piña', 5, 10);

INSERT INTO pizzas (nombre, tamano, precio_base, tipo) VALUES
('Pizza Especial de Jamón y Queso', 'familiar', 35000.00, 'especial'),
('Pizza Vegetariana Especial', 'mediana', 25000.00, 'vegetariana'),
('Pizza Pepperoni Clásica', 'familiar', 30000.00, 'clásica'),
('Pizza Hawaiana', 'pequeña', 18000.00, 'clásica');

INSERT INTO pizza_ingredientes (id_pizza, id_ingrediente, cantidad) VALUES
(1, 1, 2),
(1, 5, 2),
(2, 1, 1),
(2, 3, 2),
(2, 4, 2),
(3, 1, 2),
(3, 2, 3);

INSERT INTO repartidores (nombre, zona_asignada, estado) VALUES
('Diego Torres', 'Zona Norte', 'disponible'),
('Andres Mejia', 'Zona Sur', 'disponible');

INSERT INTO pedidos (id_cliente, fecha_hora, metodo_pago, estado, total_pedido) VALUES
(1, NOW() - INTERVAL 5 DAY, 'efectivo', 'entregado', 35000.00),
(2, NOW() - INTERVAL 3 DAY, 'tarjeta', 'entregado', 60000.00);

INSERT INTO pedidos (id_cliente, fecha_hora, metodo_pago, estado, total_pedido) VALUES
(3, NOW() - INTERVAL 10 HOUR, 'app', 'entregado', 30000.00),
(3, NOW() - INTERVAL 9 HOUR, 'app', 'entregado', 25000.00),
(3, NOW() - INTERVAL 8 HOUR, 'app', 'entregado', 18000.00),
(3, NOW() - INTERVAL 7 HOUR, 'app', 'entregado', 35000.00),
(3, NOW() - INTERVAL 6 HOUR, 'app', 'entregado', 30000.00),
(3, NOW() - INTERVAL 5 HOUR, 'app', 'pendiente', 25000.00);

INSERT INTO pedido_pizzas (id_pedido, id_pizza, cantidad, precio_unitario) VALUES
(1, 1, 1, 35000.00),
(2, 3, 2, 30000.00),
(3, 3, 1, 30000.00),
(4, 2, 1, 25000.00),
(5, 4, 1, 18000.00),
(6, 1, 1, 35000.00),
(7, 3, 1, 30000.00),
(8, 2, 1, 25000.00);

INSERT INTO domicilios (id_pedido, id_repartidor, hora_salida, hora_entrega, distancia_km, costo_envio) VALUES
(1, 1, NOW() - INTERVAL 5 DAY - INTERVAL 30 MINUTE, NOW() - INTERVAL 5 DAY - INTERVAL 10 MINUTE, 3.5, 5000.00),
(2, 2, NOW() - INTERVAL 3 DAY - INTERVAL 40 MINUTE, NOW() - INTERVAL 3 DAY - INTERVAL 15 MINUTE, 5.0, 7000.00),
(3, 1, NOW() - INTERVAL 10 HOUR - INTERVAL 25 MINUTE, NOW() - INTERVAL 10 HOUR - INTERVAL 5 MINUTE, 2.0, 3000.00);
