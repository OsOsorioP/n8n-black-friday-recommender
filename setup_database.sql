-- Crear tabla de ventas
CREATE TABLE ventas (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    producto VARCHAR(255) NOT NULL,
    fecha DATE NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ÍNDICES CRÍTICOS PARA PERFORMANCE
CREATE INDEX idx_user_fecha ON ventas(user_id, fecha);
CREATE INDEX idx_categoria ON ventas(categoria);
CREATE INDEX idx_fecha ON ventas(fecha);

-- Ingesta de datos para prueba realistas
-- Usuario 1: Compra mucha tecnología (15 compras)
INSERT INTO ventas (user_id, categoria, producto, fecha, precio)
SELECT 
    1,
    'Tecnologia',
    'Laptop Dell ' || gs.i,
    CURRENT_DATE - INTERVAL '1 day' * (gs.i * 10),
    500 + (gs.i * 50)
FROM generate_series(1, 15) as gs(i);

-- Usuario 2: Compra moda (10 compras)
INSERT INTO ventas (user_id, categoria, producto, fecha, precio)
SELECT 
    2,
    'Moda',
    'Camisa ' || gs.i,
    CURRENT_DATE - INTERVAL '1 day' * (gs.i * 5),
    50 + (gs.i * 10)
FROM generate_series(1, 10) as gs(i);

-- Usuario 3: Compra mixta (más moda que tecnología)
INSERT INTO ventas (user_id, categoria, producto, fecha, precio)
VALUES 
    (3, 'Moda', 'Jeans', CURRENT_DATE - INTERVAL '5 days', 80),
    (3, 'Moda', 'Zapatos', CURRENT_DATE - INTERVAL '15 days', 120),
    (3, 'Tecnologia', 'Mouse', CURRENT_DATE - INTERVAL '30 days', 25),
    (3, 'Moda', 'Chaqueta', CURRENT_DATE - INTERVAL '45 days', 150);

-- Usuario 999: Sin compras (para probar este caso)
-- No se insertar nada

-- En esta parte se verifica que los índices estén funcionando
EXPLAIN ANALYZE
SELECT 
    categoria,
    COUNT(*) as total_compras
FROM ventas
WHERE user_id = 1
    AND fecha >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY categoria
ORDER BY total_compras DESC
LIMIT 1;