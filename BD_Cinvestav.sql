-- Creación de la base de datos
CREATE DATABASE IF NOT EXISTS inventario_laboratorio;
USE inventario_laboratorio;

-- Tabla de roles de usuario
CREATE TABLE roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255)
);

-- Tabla de usuarios
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    id_rol INT NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso DATETIME,
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
);

-- Tabla de laboratorios
CREATE TABLE laboratorios (
    id_laboratorio INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ubicacion VARCHAR(255),
    id_encargado INT,
    FOREIGN KEY (id_encargado) REFERENCES usuarios(id_usuario)
);

-- Tabla de categorías de materiales
CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255)
);

-- Tabla de unidades de medida
CREATE TABLE unidades_medida (
    id_unidad INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    abreviatura VARCHAR(10) NOT NULL
);

-- Tabla de materiales (incluye tanto reactivos como cristalería)
CREATE TABLE materiales (
    id_material INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    id_categoria INT NOT NULL,
    id_unidad INT,
    es_reactivo BOOLEAN NOT NULL DEFAULT FALSE,
    es_cristaleria BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    FOREIGN KEY (id_unidad) REFERENCES unidades_medida(id_unidad)
);

-- Tabla de inventario por laboratorio
CREATE TABLE inventario (
    id_inventario INT AUTO_INCREMENT PRIMARY KEY,
    id_laboratorio INT NOT NULL,
    id_material INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    stock_minimo DECIMAL(10,2),
    ubicacion_en_lab VARCHAR(100),
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_laboratorio) REFERENCES laboratorios(id_laboratorio),
    FOREIGN KEY (id_material) REFERENCES materiales(id_material),
    UNIQUE KEY inventario_unico (id_laboratorio, id_material)
);

-- Tabla de préstamos
CREATE TABLE prestamos (
    id_prestamo INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_solicitante INT NOT NULL,
    id_usuario_autoriza INT NOT NULL,
    id_laboratorio INT NOT NULL,
    fecha_solicitud DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_autorizacion DATETIME,
    fecha_devolucion_esperada DATETIME,
    fecha_devolucion_real DATETIME,
    estado ENUM('Solicitado', 'Autorizado', 'Rechazado', 'Devuelto', 'Devuelto parcialmente') NOT NULL DEFAULT 'Solicitado',
    observaciones TEXT,
    FOREIGN KEY (id_usuario_solicitante) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_usuario_autoriza) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_laboratorio) REFERENCES laboratorios(id_laboratorio)
);

-- Tabla de detalles de préstamos
CREATE TABLE detalles_prestamo (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_prestamo INT NOT NULL,
    id_material INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    cantidad_devuelta DECIMAL(10,2) DEFAULT 0,
    estado ENUM('Prestado', 'Devuelto', 'Dañado', 'Perdido') NOT NULL DEFAULT 'Prestado',
    observaciones TEXT,
    FOREIGN KEY (id_prestamo) REFERENCES prestamos(id_prestamo),
    FOREIGN KEY (id_material) REFERENCES materiales(id_material)
);

-- Tabla de historial de movimientos
CREATE TABLE historial_movimientos (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_material INT NOT NULL,
    id_laboratorio INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_movimiento ENUM('Entrada', 'Salida', 'Préstamo', 'Devolución', 'Ajuste') NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    fecha_movimiento DATETIME DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    FOREIGN KEY (id_material) REFERENCES materiales(id_material),
    FOREIGN KEY (id_laboratorio) REFERENCES laboratorios(id_laboratorio),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- Insertando datos iniciales para roles
INSERT INTO roles (nombre_rol, descripcion) VALUES 
('Super Usuario', 'Acceso total al sistema'),
('Encargado de Laboratorio', 'Gestión de un laboratorio específico'),
('Usuario Regular', 'Acceso limitado para solicitar préstamos');

-- Insertando categorías básicas
INSERT INTO categorias (nombre, descripcion) VALUES 
('Reactivos Químicos', 'Sustancias químicas utilizadas en laboratorio'),
('Cristalería', 'Equipos de vidrio para laboratorio'),
('Equipos Electrónicos', 'Dispositivos electrónicos de laboratorio'),
('Consumibles', 'Materiales de uso regular y consumible');

-- Insertando unidades de medida
INSERT INTO unidades_medida (nombre, abreviatura) VALUES 
('Unidad', 'u'),
('Mililitro', 'ml'),
('Gramo', 'g'),
('Kilogramo', 'kg'),
('Litro', 'L'),
('Miligramo', 'mg');

-- Creando vistas para facilitar consultas

-- Vista de inventario completo
CREATE VIEW vista_inventario AS
SELECT 
    i.id_inventario,
    l.nombre AS laboratorio,
    m.codigo,
    m.nombre AS material,
    c.nombre AS categoria,
    CASE 
        WHEN m.es_reactivo = 1 THEN 'Reactivo'
        WHEN m.es_cristaleria = 1 THEN 'Cristalería'
        ELSE 'Otro'
    END AS tipo,
    i.cantidad,
    um.nombre AS unidad,
    i.stock_minimo,
    i.ubicacion_en_lab,
    i.fecha_actualizacion
FROM inventario i
JOIN laboratorios l ON i.id_laboratorio = l.id_laboratorio
JOIN materiales m ON i.id_material = m.id_material
JOIN categorias c ON m.id_categoria = c.id_categoria
LEFT JOIN unidades_medida um ON m.id_unidad = um.id_unidad;

-- Vista de préstamos activos
CREATE VIEW vista_prestamos_activos AS
SELECT 
    p.id_prestamo,
    CONCAT(us.nombre, ' ', us.apellido) AS solicitante,
    CONCAT(ua.nombre, ' ', ua.apellido) AS autoriza,
    l.nombre AS laboratorio,
    p.fecha_solicitud,
    p.fecha_autorizacion,
    p.fecha_devolucion_esperada,
    p.estado
FROM prestamos p
JOIN usuarios us ON p.id_usuario_solicitante = us.id_usuario
JOIN usuarios ua ON p.id_usuario_autoriza = ua.id_usuario
JOIN laboratorios l ON p.id_laboratorio = l.id_laboratorio
WHERE p.estado IN ('Solicitado', 'Autorizado');

-- Procedimiento para registrar un préstamo
DELIMITER //
CREATE PROCEDURE registrar_prestamo(
    IN p_id_usuario_solicitante INT,
    IN p_id_usuario_autoriza INT,
    IN p_id_laboratorio INT,
    IN p_fecha_devolucion_esperada DATETIME,
    IN p_observaciones TEXT
)
BEGIN
    INSERT INTO prestamos (
        id_usuario_solicitante,
        id_usuario_autoriza,
        id_laboratorio,
        fecha_devolucion_esperada,
        observaciones
    ) VALUES (
        p_id_usuario_solicitante,
        p_id_usuario_autoriza,
        p_id_laboratorio,
        p_fecha_devolucion_esperada,
        p_observaciones
    );
    
    SELECT LAST_INSERT_ID() AS id_prestamo;
END //
DELIMITER ;

-- Procedimiento para agregar un material al préstamo
DELIMITER //
CREATE PROCEDURE agregar_material_prestamo(
    IN p_id_prestamo INT,
    IN p_id_material INT,
    IN p_cantidad DECIMAL(10,2)
)
BEGIN
    DECLARE stock_actual DECIMAL(10,2);
    DECLARE lab_id INT;
    
    -- Obtener el laboratorio del préstamo
    SELECT id_laboratorio INTO lab_id FROM prestamos WHERE id_prestamo = p_id_prestamo;
    
    -- Verificar stock disponible
    SELECT cantidad INTO stock_actual 
    FROM inventario 
    WHERE id_laboratorio = lab_id AND id_material = p_id_material;
    
    IF stock_actual >= p_cantidad THEN
        -- Agregar el material al préstamo
        INSERT INTO detalles_prestamo (
            id_prestamo,
            id_material,
            cantidad
        ) VALUES (
            p_id_prestamo,
            p_id_material,
            p_cantidad
        );
        
        -- Actualizar el inventario
        UPDATE inventario 
        SET cantidad = cantidad - p_cantidad 
        WHERE id_laboratorio = lab_id AND id_material = p_id_material;
        
        -- Registrar el movimiento
        INSERT INTO historial_movimientos (
            id_material,
            id_laboratorio,
            id_usuario,
            tipo_movimiento,
            cantidad,
            observaciones
        ) VALUES (
            p_id_material,
            lab_id,
            (SELECT id_usuario_solicitante FROM prestamos WHERE id_prestamo = p_id_prestamo),
            'Préstamo',
            p_cantidad,
            CONCAT('Préstamo #', p_id_prestamo)
        );
        
        SELECT 'Material agregado correctamente' AS mensaje;
    ELSE
        SELECT 'Error: Stock insuficiente' AS mensaje;
    END IF;
END //
DELIMITER ;

-- Procedimiento para registrar devolución de préstamo
DELIMITER //
CREATE PROCEDURE registrar_devolucion(
    IN p_id_prestamo INT,
    IN p_id_material INT,
    IN p_cantidad_devuelta DECIMAL(10,2),
    IN p_estado ENUM('Devuelto', 'Dañado', 'Perdido'),
    IN p_observaciones TEXT
)
BEGIN
    DECLARE cantidad_original DECIMAL(10,2);
    DECLARE lab_id INT;
    
    -- Obtener cantidad original y laboratorio
    SELECT dp.cantidad, p.id_laboratorio 
    INTO cantidad_original, lab_id
    FROM detalles_prestamo dp
    JOIN prestamos p ON dp.id_prestamo = p.id_prestamo
    WHERE dp.id_prestamo = p_id_prestamo AND dp.id_material = p_id_material;
    
    -- Actualizar detalle de préstamo
    UPDATE detalles_prestamo 
    SET cantidad_devuelta = p_cantidad_devuelta,
        estado = p_estado,
        observaciones = p_observaciones
    WHERE id_prestamo = p_id_prestamo AND id_material = p_id_material;
    
    -- Actualizar inventario solo si el estado es 'Devuelto'
    IF p_estado = 'Devuelto' THEN
        UPDATE inventario 
        SET cantidad = cantidad + p_cantidad_devuelta 
        WHERE id_laboratorio = lab_id AND id_material = p_id_material;
        
        -- Registrar el movimiento
        INSERT INTO historial_movimientos (
            id_material,
            id_laboratorio,
            id_usuario,
            tipo_movimiento,
            cantidad,
            observaciones
        ) VALUES (
            p_id_material,
            lab_id,
            (SELECT id_usuario_autoriza FROM prestamos WHERE id_prestamo = p_id_prestamo),
            'Devolución',
            p_cantidad_devuelta,
            CONCAT('Devolución de préstamo #', p_id_prestamo)
        );
    END IF;
    
    -- Verificar si todos los materiales han sido devueltos
    IF NOT EXISTS (
        SELECT 1 FROM detalles_prestamo 
        WHERE id_prestamo = p_id_prestamo 
        AND cantidad > cantidad_devuelta
    ) THEN
        UPDATE prestamos 
        SET estado = 'Devuelto', 
            fecha_devolucion_real = NOW() 
        WHERE id_prestamo = p_id_prestamo;
    ELSE
        UPDATE prestamos 
        SET estado = 'Devuelto parcialmente' 
        WHERE id_prestamo = p_id_prestamo;
    END IF;
    
    SELECT 'Devolución registrada correctamente' AS mensaje;
END //
DELIMITER ;

-- Trigger para actualizar el inventario cuando se registra un nuevo material
DELIMITER //
CREATE TRIGGER after_material_insert
AFTER INSERT ON materiales
FOR EACH ROW
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE lab_id INT;
    DECLARE cur CURSOR FOR SELECT id_laboratorio FROM laboratorios;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO lab_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        INSERT INTO inventario (id_laboratorio, id_material, cantidad, stock_minimo)
        VALUES (lab_id, NEW.id_material, 0, 0);
    END LOOP;
    CLOSE cur;
END //
DELIMITER ;

-- Índices para mejorar rendimiento
CREATE INDEX idx_inventario_material ON inventario(id_material);
CREATE INDEX idx_inventario_laboratorio ON inventario(id_laboratorio);
CREATE INDEX idx_prestamos_usuario ON prestamos(id_usuario_solicitante);
CREATE INDEX idx_prestamos_estado ON prestamos(estado);
CREATE INDEX idx_detalles_prestamo ON detalles_prestamo(id_prestamo);
CREATE INDEX idx_movimientos_material ON historial_movimientos(id_material);
CREATE INDEX idx_movimientos_laboratorio ON historial_movimientos(id_laboratorio);
CREATE INDEX idx_movimientos_usuario ON historial_movimientos(id_usuario);