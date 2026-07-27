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

### Diagrama de Entidad-Relación

![Esquema Base de Datos](./img/esquemadrawsql.png)

### Explicación de Relaciones
- **Clientes y Pedidos (1:N)**: Un cliente puede realizar múltiples pedidos a lo largo del tiempo, pero cada pedido pertenece a un único cliente.
- **Pizzas e Ingredientes (M:N)**: Una pizza está compuesta por varios ingredientes, y a su vez, un ingrediente puede formar parte de diferentes pizzas. Esta relación de muchos a muchos se resuelve a través de la tabla intermedia `pizza_ingredientes`.
- **Pedidos y Pizzas (M:N)**: Un pedido puede incluir una o varias pizzas, y una pizza puede estar presente en múltiples pedidos. Se resuelve con la tabla intermedia `pedido_pizzas`.
- **Pedidos y Domicilios (1:1)**: Cada pedido para entrega a domicilio tiene asociado un único registro de envío en la tabla `domicilios`.
- **Repartidores y Domicilios (1:N)**: Un repartidor puede realizar múltiples entregas de domicilios, pero cada domicilio es entregado por un solo repartidor.
- **Pizzas e Historial de Precios (1:N)**: Cuando se actualiza el precio de una pizza, el trigger inserta un registro histórico. Una pizza puede tener múltiples cambios registrados en su historial.

## Scripts del Proyecto
- `database.sql`: Creación de la base de datos, tablas y llaves foráneas.
- `funciones.sql`: Funciones para cálculo de totales, ganancias y procedimientos de actualización.
- `triggers.sql`: Triggers de actualización de stock, auditoría y liberación de repartidores.
- `vistas.sql`: Vistas para reportes rápidos (resumen de clientes, desempeño de repartidores, stock crítico).
- `consultas.sql`: Consultas avanzadas requeridas por el negocio (uso de JOIN, HAVING, BETWEEN, subconsultas, etc.).

## Ejemplos de Consultas Requeridas y Resultados

A continuación se presentan las 7 consultas solicitadas, su implementación en SQL, su respectiva captura de pantalla y la explicación de lo que arroja cada una:

### 1. Clientes con pedidos entre dos fechas (BETWEEN)
Obtiene la lista única de clientes que han hecho pedidos dentro de un rango de fechas específico.
```sql
SELECT DISTINCT c.nombre, c.telefono, p.fecha_hora
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.fecha_hora BETWEEN '2023-01-01 00:00:00' AND '2023-12-31 23:59:59';
```
![Resultado Consulta 1](./img/consulta1.png)
* **Resultado**: Retorna el nombre, teléfono y fecha/hora exacta del pedido para los clientes que realizaron pedidos durante el año 2023.

---

### 2. Pizzas más vendidas (GROUP BY y COUNT/SUM)
Agrupa las pizzas vendidas por su identificador y calcula la cantidad total vendida de cada una.
```sql
SELECT pz.nombre, SUM(pp.cantidad) AS cantidad_vendida
FROM pizzas pz
JOIN pedido_pizzas pp ON pz.id_pizza = pp.id_pizza
GROUP BY pz.id_pizza, pz.nombre
ORDER BY cantidad_vendida DESC;
```
![Resultado Consulta 2](./img/consulta2.png)
* **Resultado**: Muestra un ranking ordenado de mayor a menor con el nombre de la pizza y la sumatoria total de unidades vendidas.

---

### 3. Pedidos por repartidor (JOIN)
Muestra la lista de pedidos asociados a cada repartidor con el estado actual de la entrega.
```sql
SELECT r.nombre AS repartidor, p.id_pedido, p.estado, d.hora_entrega
FROM repartidores r
JOIN domicilios d ON r.id_repartidor = d.id_repartidor
JOIN pedidos p ON d.id_pedido = p.id_pedido;
```
![Resultado Consulta 3](./img/consulta3.png)
* **Resultado**: Lista el nombre del repartidor junto al ID del pedido asignado, el estado del pedido y la hora en la que fue o será entregado.

---

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
![Resultado Consulta 4](./img/consulta4.png)
* **Resultado**: Entrega el promedio de tiempo (en minutos) que tardan las entregas desde la salida hasta la entrega efectiva, clasificado por zona geográfica.

---

### 5. Clientes que gastaron más de un monto (HAVING)
Agrupa por cliente, suma su gasto total y filtra aquellos que superaron un monto definido (en este caso, 50,000).
```sql
SELECT c.nombre, SUM(p.total_pedido) AS gasto_total
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre
HAVING gasto_total > 50000;
```
![Resultado Consulta 5](./img/consulta5.png)
* **Resultado**: Retorna el nombre de los clientes VIP y el acumulado de sus compras, filtrando únicamente a aquellos que han gastado más de 50,000.

---

### 6. Búsqueda por coincidencia parcial de nombre de pizza (LIKE)
Permite buscar pizzas cuyos nombres coincidan parcialmente con un término de búsqueda (en este caso, 'Queso').
```sql
SELECT id_pizza, nombre, tipo, precio_base
FROM pizzas
WHERE nombre LIKE '%Queso%';
```
![Resultado Consulta 6](./img/consulta6.png)
* **Resultado**: Devuelve la información de las pizzas que contienen la palabra "Queso" en cualquier parte de su nombre.

---

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
![Resultado Consulta 7](./img/consulta7.png)
* **Resultado**: Retorna los datos de contacto de aquellos clientes frecuentes que registran un volumen superior a 5 pedidos en el sistema.

---

### 8. Cantidad de entregas por repartidor
Muestra el total acumulado de domicilios despachados por cada repartidor registrado.
```sql
SELECT r.id_repartidor, r.nombre, COUNT(d.id_domicilio) AS total_entregas
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor
GROUP BY r.id_repartidor, r.nombre
ORDER BY total_entregas DESC;
```
* **Resultado**: Entrega la métrica de cuántas entregas exitosas u ordenadas ha realizado cada miembro del equipo de reparto.

---

### 9. Entregas a domicilio por pizza del menú
Calcula cuántas entregas se han realizado agrupado por cada tipo/nombre de pizza.
```sql
SELECT pz.nombre AS pizza, COUNT(DISTINCT d.id_domicilio) AS total_domicilios_entregados
FROM pizzas pz
JOIN pedido_pizzas pp ON pz.id_pizza = pp.id_pizza
JOIN pedidos p ON pp.id_pedido = p.id_pedido
JOIN domicilios d ON p.id_pedido = d.id_pedido
WHERE p.estado = 'entregado'
GROUP BY pz.id_pizza, pz.nombre
ORDER BY total_domicilios_entregados DESC;
```
* **Resultado**: Ranking de pizzas de acuerdo a su frecuencia en los pedidos despachados a domicilio.

---

### 10. Ingresos y cantidad de pedidos por método de pago
Permite analizar los métodos de pago preferidos de los clientes y los ingresos totales que reporta cada uno.
```sql
SELECT metodo_pago, COUNT(id_pedido) AS total_pedidos, SUM(total_pedido) AS ingresos_totales
FROM pedidos
WHERE estado = 'entregado'
GROUP BY metodo_pago
ORDER BY ingresos_totales DESC;
```
* **Resultado**: Consolidado de transacciones exitosas y facturación según efectivo, tarjeta o app.

---

### 11. Clientes frecuentes con múltiples domicilios
Identifica a los clientes que han requerido entregas a domicilio más de una vez.
```sql
SELECT c.nombre AS cliente, COUNT(d.id_domicilio) AS total_domicilios
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
JOIN domicilios d ON p.id_pedido = d.id_pedido
GROUP BY c.id_cliente, c.nombre
HAVING total_domicilios > 1
ORDER BY total_domicilios DESC;
```
* **Resultado**: Listado de clientes frecuentes en la modalidad de entrega a domicilio.

---

### 12. Consumo acumulado de ingredientes en pedidos entregados
Calcula el desgaste real del inventario considerando las cantidades asociadas a cada receta de pizza despachada.
```sql
SELECT i.nombre AS ingrediente, SUM(pi.cantidad * pp.cantidad) AS cantidad_usada
FROM ingredientes i
JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
JOIN pedido_pizzas pp ON pi.id_pizza = pp.id_pizza
JOIN pedidos p ON pp.id_pedido = p.id_pedido
WHERE p.estado = 'entregado'
GROUP BY i.id_ingrediente, i.nombre
ORDER BY cantidad_usada DESC;
```
* **Resultado**: Muestra la cantidad total de cada ingrediente consumido y facturado en pizzas entregadas.

---

### 13. Ranking de Clientes VIP
Encuentra a los 3 mejores clientes activos basándose en su gasto histórico acumulado.
```sql
SELECT c.id_cliente, c.nombre, SUM(p.total_pedido) AS total_gastado, COUNT(p.id_pedido) AS total_pedidos
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.estado = 'entregado' AND c.activo = 1
GROUP BY c.id_cliente, c.nombre
ORDER BY total_gastado DESC
LIMIT 3;
```
* **Resultado**: Reporte de los tres clientes que mayor rentabilidad generan para el negocio.

---

### 14. Reporte de compra sugerida de insumos
Indica qué ingredientes se encuentran por debajo del stock mínimo y sugiere la cantidad de compra necesaria para alcanzar un nivel óptimo.
```sql
SELECT 
    nombre AS ingrediente,
    stock AS stock_actual,
    stock_minimo,
    (stock_minimo * 2) AS stock_sugerido_optimo,
    ((stock_minimo * 2) - stock) AS cantidad_a_comprar
FROM ingredientes
WHERE stock < stock_minimo;
```
* **Resultado**: Listado de insumos críticos con recomendaciones cuantitativas de reposición.

---

### 15. Promedio de pizzas por pedido
Calcula el tamaño medio del pedido de los clientes (unidades de pizza por ticket).
```sql
SELECT AVG(cantidad_de_pizzas) AS promedio_pizzas_por_pedido
FROM (
    SELECT id_pedido, SUM(cantidad) AS cantidad_de_pizzas
    FROM pedido_pizzas
    GROUP BY id_pedido
) AS subconsulta;
```
* **Resultado**: Indica la media de pizzas contenidas por cada transacción.

---

## Pruebas de Funciones, Triggers y Vistas

A continuación se presentan las evidencias de las pruebas unitarias realizadas para verificar el correcto funcionamiento de las funciones, triggers y vistas:

### Prueba 1: Creación de Base de Datos y Tablas
![Creación de Tablas](./img/captura1.png)
* **Descripción**: Muestra la ejecución de `database.sql`, creando la estructura relacional sin errores.

### Prueba 2: Función `calcular_total_pedido`
![Prueba calcular_total_pedido](./img/captura2.png)
* **Descripción**: Verifica el cálculo del total de un pedido sumando el precio de las pizzas, el costo del envío e incorporando la tasa de IVA.

### Prueba 3: Función `calcular_ganancia_diaria`
![Prueba calcular_ganancia_diaria](./img/captura3.png)
* **Descripción**: Ejecución de la función que calcula las ganancias netas de un día deduciendo los costos de insumos estimulados de las ventas totales.

### Prueba 4: Procedimiento `registrar_entrega_pedido`
![Prueba registrar_entrega_pedido](./img/captura4.png)
* **Descripción**: Demuestra la ejecución del procedimiento para actualizar la hora de entrega, lo cual desencadena el cambio de estado del pedido a 'entregado'.

### Prueba 5: Trigger `tr_actualizar_stock_ingredientes`
![Prueba tr_actualizar_stock_ingredientes](./img/captura5.png)
* **Descripción**: Muestra el decremento automático del stock de los ingredientes cada vez que ingresa una nueva pizza en un pedido.

### Prueba 6: Trigger `tr_auditoria_precio_pizza`
![Prueba tr_auditoria_precio_pizza](./img/captura6.png)
* **Descripción**: Evidencia cómo el trigger registra en la tabla `historial_precios` el valor anterior y nuevo tras actualizar el precio de una pizza.

### Prueba 7: Trigger `tr_liberar_repartidor`
![Prueba tr_liberar_repartidor](./img/captura7.png)
* **Descripción**: Muestra cómo el estado del repartidor cambia automáticamente a 'disponible' cuando se asienta la hora de entrega del domicilio.

### Prueba 8: Vista `vista_resumen_clientes`
![Vista resumen clientes](./img/captura8.png)
* **Descripción**: Consulta a la vista que resume la cantidad de pedidos y el total acumulado por cada cliente.

### Prueba 9: Vista `vista_desempeno_repartidores`
![Vista desempeño repartidores](./img/captura9.png)
* **Descripción**: Consulta a la vista que consolida las métricas de rendimiento de cada repartidor (entregas totales y su tiempo promedio en minutos).

### Prueba 10: Vista `vista_stock_critico`
![Vista stock crítico](./img/captura10.png)
* **Descripción**: Muestra los insumos cuyo stock disponible es menor a su límite mínimo permitido.

---

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

---

## Módulos Adicionales de Análisis Integrados

El repositorio incluye la solución para **4 variantes o módulos de análisis** basados en la estructura unificada de la base de datos. Las consultas y vistas específicas de cada módulo se encuentran debidamente etiquetadas en [consultas.sql](file:///c:/Users/osori/Desktop/proyecto%20sql-2/pizzeria-don-piccolo/consultas.sql) y [vistas.sql](file:///c:/Users/osori/Desktop/proyecto%20sql-2/pizzeria-don-piccolo/vistas.sql) bajo comentarios aclaratorios:

### Módulo 1: Sistema de Domicilios y Repartidores
* **Objetivo:** Analizar el flujo de entregas a domicilio y desempeño de repartidores.
* **Consultas:** 
  1. *Entregas por repartidor:* Total de entregas con estado 'entregado' y monto total acumulado.
  2. *Pedidos demorados:* Aquellos con duración mayor a 40 minutos.
  3. *Repartidores disponibles:* Repartidores activos sin entregas asociadas.
* **Vistas:** `vista_desempeno_repartidor`.

### Módulo 2: Inventario, Ingredientes y Recetas
* **Objetivo:** Evaluar la relación de muchos a muchos entre pizzas e ingredientes y control de stock.
* **Consultas:**
  1. *Ingredientes distintos por pizza:* Conteo de insumos en la receta.
  2. *Alerta de stock crítico:* Insumos bajo el límite y cálculo de compra sugerida.
  3. *Ingredientes sin uso:* Elementos del almacén que no pertenecen a ninguna pizza del menú.
* **Vistas:** `vista_inventario_critico`.

### Módulo 3: Menú de Pizzas e Historial de Precios
* **Objetivo:** Auditar cambios de precios y evaluar el comportamiento de la oferta de productos.
* **Consultas:**
  1. *Resumen de precios:* Precio promedio y máximo por tipo y tamaño.
  2. *Auditoría de incrementos:* Cambios históricos de precios donde la diferencia superó los 5,000.
  3. *Pizzas no vendidas:* Productos del catálogo que nunca han figurado en un pedido.
* **Vistas:** `vista_resumen_precios`.

### Módulo 4: Ventas y Fidelización de Clientes
* **Objetivo:** Analizar el consumo, identificar clientes VIP y detectar usuarios inactivos.
* **Consultas:**
  1. *Consumo por cliente:* Cantidad de transacciones e ingresos generados.
  2. *Clientes VIP:* Clientes con compras acumuladas mayores a 50,000.
  3. *Clientes inactivos:* Clientes registrados en el sistema que aún no tienen compras.
* **Vistas:** `vista_resumen_clientes` (incluida en el núcleo del proyecto).


