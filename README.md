# Pizzería Don Piccolo - Base de Datos

Este proyecto consiste en el diseño e implementación de una base de datos relacional en MySQL para la **Pizzería Don Piccolo**, permitiendo la gestión eficiente de pedidos, clientes, ingredientes y repartidores.

## Descripción del Proyecto
El sistema fue creado para resolver los problemas de gestión manual de la pizzería, permitiendo un control automatizado desde el registro del pedido hasta la entrega a domicilio, además de calcular ganancias y automatizar el control de stock de los ingredientes.

## Estructura de Tablas y Relaciones
La base de datos contiene las siguientes tablas principales:
- **clientes**: Almacena la información de contacto de los clientes.
- **pizzas**: Catálogo de pizzas disponibles, sus tamaños y precios base.
- **ingredientes**: Inventario de ingredientes para la preparación.
- **pizza_ingredientes**: Tabla intermedia que relaciona qué ingredientes y en qué cantidad componen cada pizza.
- **pedidos**: Registro de cada compra realizada por un cliente.
- **pedido_pizzas**: Detalle de las pizzas solicitadas en cada pedido.
- **repartidores**: Personal de entrega y su estado de disponibilidad.
- **domicilios**: Detalles de cada entrega (hora de salida, entrega, distancia y costo).
- **historial_precios**: Tabla de auditoría alimentada por un trigger para guardar el historial de cambios en el precio de las pizzas.

## Scripts del Proyecto
- `database.sql`: Creación de la base de datos, tablas y llaves foráneas.
- `funciones.sql`: Funciones para cálculo de totales, ganancias y procedimientos de actualización.
- `triggers.sql`: Triggers de actualización de stock, auditoría y liberación de repartidores.
- `vistas.sql`: Vistas para reportes rápidos (resumen de clientes, desempeño de repartidores, stock crítico).
- `consultas.sql`: Consultas avanzadas requeridas por el negocio (uso de JOIN, HAVING, BETWEEN, subconsultas, etc.).

## Ejemplos de Consultas Requeridas

A continuación se presentan las 7 consultas solicitadas y su implementación en SQL:

### 1. Clientes con pedidos entre dos fechas (BETWEEN)
Obtiene la lista única de clientes que han hecho pedidos dentro de un rango de fechas específico.
```sql
SELECT DISTINCT c.nombre, c.telefono, p.fecha_hora
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.fecha_hora BETWEEN '2023-01-01 00:00:00' AND '2023-12-31 23:59:59';
```

### 2. Pizzas más vendidas (GROUP BY y COUNT/SUM)
Agrupa las pizzas vendidas por su identificador y calcula la cantidad total vendida de cada una.
```sql
SELECT pz.nombre, SUM(pp.cantidad) AS cantidad_vendida
FROM pizzas pz
JOIN pedido_pizzas pp ON pz.id_pizza = pp.id_pizza
GROUP BY pz.id_pizza, pz.nombre
ORDER BY cantidad_vendida DESC;
```

### 3. Pedidos por repartidor (JOIN)
Muestra la lista de pedidos asociados a cada repartidor con el estado actual de la entrega.
```sql
SELECT r.nombre AS repartidor, p.id_pedido, p.estado, d.hora_entrega
FROM repartidores r
JOIN domicilios d ON r.id_repartidor = d.id_repartidor
JOIN pedidos p ON d.id_pedido = p.id_pedido;
```

### 4. Promedio de entrega por zona (AVG y JOIN)
Calcula el tiempo promedio de entrega en minutos agrupado por las diferentes zonas de reparto asignadas.
```sql
SELECT r.zona_asignada, 
       AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)) AS tiempo_promedio_entrega_minutos
FROM repartidores r
JOIN domicilios d ON r.id_repartidor = d.id_repartidor
WHERE d.hora_entrega IS NOT NULL
GROUP BY r.zona_asignada;
```

### 5. Clientes que gastaron más de un monto (HAVING)
Agrupa por cliente, suma su gasto total y filtra aquellos que superaron un monto definido (ej: 50,000).
```sql
SELECT c.nombre, SUM(p.total_pedido) AS gasto_total
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre
HAVING gasto_total > 50000;
```

### 6. Búsqueda por coincidencia parcial de nombre de pizza (LIKE)
Permite buscar pizzas cuyos nombres coincidan parcialmente con un término de búsqueda (ej: 'Queso').
```sql
SELECT id_pizza, nombre, tipo, precio_base
FROM pizzas
WHERE nombre LIKE '%Queso%';
```

### 7. Subconsulta para obtener los clientes frecuentes (más de 5 pedidos mensuales)
Identifica los clientes que han registrado más de 5 pedidos a través de una subconsulta.
```sql
SELECT nombre, telefono, correo_electronico
FROM clientes
WHERE id_cliente IN (
    SELECT id_cliente
    FROM pedidos
    GROUP BY id_cliente
    HAVING COUNT(id_pedido) > 5
);
```


## Instrucciones para ejecutar el script
1. Abre tu cliente de base de datos preferido (MySQL Workbench, DBeaver, o consola de MySQL).
2. Conéctate a tu servidor MySQL.
3. Ejecuta los scripts en el siguiente orden para evitar problemas de dependencias:
   - `database.sql`
   - `funciones.sql`
   - `triggers.sql`
   - `vistas.sql`
   - `datos_prueba.sql` (para poblar la base de datos con información de pruebas)
   - `consultas.sql` (para probar el comportamiento de las consultas)
