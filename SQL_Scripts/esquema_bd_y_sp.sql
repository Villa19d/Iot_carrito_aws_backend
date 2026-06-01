CREATE DATABASE IF NOT EXISTS carrito_iot;
USE carrito_iot;

-- Estructura de la tabla cat_estatus_obstaculo
CREATE TABLE `cat_estatus_obstaculo` (
  `id_estatus` int NOT NULL AUTO_INCREMENT,
  `nombre_estatus` varchar(50) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_estatus`),
  UNIQUE KEY `nombre_estatus` (`nombre_estatus`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla cat_movimientos
CREATE TABLE `cat_movimientos` (
  `id_movimiento` int NOT NULL AUTO_INCREMENT,
  `nombre_movimiento` varchar(100) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_movimiento`),
  UNIQUE KEY `nombre_movimiento` (`nombre_movimiento`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla config_motor_movimiento
CREATE TABLE `config_motor_movimiento` (
  `id_configuracion` int NOT NULL AUTO_INCREMENT,
  `id_movimiento` int NOT NULL,
  `mia_estado` varchar(20) NOT NULL,
  `mia_pwm` varchar(20) NOT NULL,
  `mi_time` int NOT NULL DEFAULT '0',
  `mda_estado` varchar(20) NOT NULL,
  `mda_pwm` varchar(20) NOT NULL,
  `md_time` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_configuracion`),
  UNIQUE KEY `id_movimiento` (`id_movimiento`),
  CONSTRAINT `fk_config_movimiento` FOREIGN KEY (`id_movimiento`) REFERENCES `cat_movimientos` (`id_movimiento`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla detalle_secuencia_demo
CREATE TABLE `detalle_secuencia_demo` (
  `id_detalle` int NOT NULL AUTO_INCREMENT,
  `id_secuencia` int NOT NULL,
  `id_movimiento` int NOT NULL,
  `orden_ejecucion` int NOT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `fk_detalle_secuencia` (`id_secuencia`),
  KEY `fk_detalle_movimiento` (`id_movimiento`),
  CONSTRAINT `fk_detalle_movimiento` FOREIGN KEY (`id_movimiento`) REFERENCES `cat_movimientos` (`id_movimiento`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_detalle_secuencia` FOREIGN KEY (`id_secuencia`) REFERENCES `secuencias_demo` (`id_secuencia`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=76 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla dispositivos
CREATE TABLE `dispositivos` (
  `id_dispositivo` int NOT NULL AUTO_INCREMENT,
  `nombre_dispositivo` varchar(100) NOT NULL,
  `identificador_unico` varchar(100) DEFAULT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `pais` varchar(100) DEFAULT NULL,
  `ciudad` varchar(100) DEFAULT NULL,
  `latitud` decimal(10,7) DEFAULT NULL,
  `longitud` decimal(10,7) DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `fecha_registro` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_dispositivo`),
  UNIQUE KEY `identificador_unico` (`identificador_unico`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla ejecuciones_secuencia_demo
CREATE TABLE `ejecuciones_secuencia_demo` (
  `id_ejecucion` int NOT NULL AUTO_INCREMENT,
  `id_secuencia` int NOT NULL,
  `id_dispositivo` int NOT NULL,
  `id_telemetria` bigint DEFAULT NULL,
  `fecha_ejecucion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_ejecucion`),
  KEY `fk_ejecucion_secuencia` (`id_secuencia`),
  KEY `fk_ejecucion_dispositivo` (`id_dispositivo`),
  KEY `fk_ejecucion_telemetria` (`id_telemetria`),
  KEY `idx_ejecuciones_fecha` (`fecha_ejecucion` DESC),
  CONSTRAINT `fk_ejecucion_dispositivo` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivos` (`id_dispositivo`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ejecucion_secuencia` FOREIGN KEY (`id_secuencia`) REFERENCES `secuencias_demo` (`id_secuencia`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_ejecucion_telemetria` FOREIGN KEY (`id_telemetria`) REFERENCES `telemetria_dispositivo` (`id_telemetria`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla movimientos_registrados
CREATE TABLE `movimientos_registrados` (
  `id_registro` bigint NOT NULL AUTO_INCREMENT,
  `id_dispositivo` int NOT NULL,
  `id_movimiento` int NOT NULL,
  `fecha_hora` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_registro`),
  KEY `fk_mov_reg_movimiento` (`id_movimiento`),
  KEY `idx_movimientos_fecha` (`fecha_hora` DESC),
  KEY `idx_movimientos_dispositivo` (`id_dispositivo`),
  CONSTRAINT `fk_mov_reg_dispositivo` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivos` (`id_dispositivo`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_mov_reg_movimiento` FOREIGN KEY (`id_movimiento`) REFERENCES `cat_movimientos` (`id_movimiento`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=793 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla obstaculos_registrados
CREATE TABLE `obstaculos_registrados` (
  `id_obstaculo` bigint NOT NULL AUTO_INCREMENT,
  `id_dispositivo` int NOT NULL,
  `id_estatus` int NOT NULL,
  `distancia_cm` decimal(10,2) DEFAULT NULL,
  `fecha_hora` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_obstaculo`),
  KEY `fk_obs_estatus` (`id_estatus`),
  KEY `idx_obstaculos_fecha` (`fecha_hora` DESC),
  KEY `idx_obstaculos_dispositivo` (`id_dispositivo`),
  CONSTRAINT `fk_obs_dispositivo` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivos` (`id_dispositivo`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_obs_estatus` FOREIGN KEY (`id_estatus`) REFERENCES `cat_estatus_obstaculo` (`id_estatus`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla parametros
CREATE TABLE `parametros` (
  `id_parametro` int NOT NULL AUTO_INCREMENT,
  `clave_parametro` varchar(50) NOT NULL,
  `valor_parametro` decimal(10,2) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `ultima_actualizacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_parametro`),
  UNIQUE KEY `clave_parametro` (`clave_parametro`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla secuencias_demo
CREATE TABLE `secuencias_demo` (
  `id_secuencia` int NOT NULL AUTO_INCREMENT,
  `nombre_secuencia` varchar(100) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_secuencia`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Estructura de la tabla telemetria_dispositivo
CREATE TABLE `telemetria_dispositivo` (
  `id_telemetria` bigint NOT NULL AUTO_INCREMENT,
  `id_dispositivo` int NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `pais` varchar(100) DEFAULT NULL,
  `ciudad` varchar(100) DEFAULT NULL,
  `latitud` decimal(10,7) DEFAULT NULL,
  `longitud` decimal(10,7) DEFAULT NULL,
  `fecha_registro` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_telemetria`),
  KEY `idx_telemetria_fecha` (`fecha_registro` DESC),
  KEY `idx_telemetria_dispositivo` (`id_dispositivo`),
  CONSTRAINT `fk_telemetria_dispositivo` FOREIGN KEY (`id_dispositivo`) REFERENCES `dispositivos` (`id_dispositivo`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Stored Procedure: sp_actualizar_parametro
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_actualizar_parametro`(

    IN p_clave VARCHAR(50),

    IN p_valor DECIMAL(10,2)

)
BEGIN

    -- Verificar si el par+?metro existe

    IF EXISTS (SELECT 1 FROM parametros WHERE clave_parametro = p_clave) THEN

        -- Actualizar existente

        UPDATE parametros 

        SET valor_parametro = p_valor,

            ultima_actualizacion = CURRENT_TIMESTAMP

        WHERE clave_parametro = p_clave;

    ELSE

        -- Insertar nuevo

        INSERT INTO parametros (clave_parametro, valor_parametro)

        VALUES (p_clave, p_valor);

    END IF;

    

    -- Devolver el par+?metro actualizado

    SELECT clave_parametro, valor_parametro, ultima_actualizacion

    FROM parametros 

    WHERE clave_parametro = p_clave;

END
//
DELIMITER ;

-- Stored Procedure: sp_agregar_movimiento
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_agregar_movimiento`(

    IN p_identificador_unico VARCHAR(100),

    IN p_nombre_movimiento VARCHAR(100)

)
BEGIN

    DECLARE v_id_dispositivo INT;

    DECLARE v_id_movimiento INT;

    

    -- Obtener ID del dispositivo por identificador +?nico (solo activos)

    SELECT id_dispositivo INTO v_id_dispositivo 

    FROM dispositivos 

    WHERE identificador_unico = p_identificador_unico AND activo = TRUE;

    

    -- Obtener ID del movimiento por nombre (solo activos)

    SELECT id_movimiento INTO v_id_movimiento 

    FROM cat_movimientos 

    WHERE nombre_movimiento = p_nombre_movimiento AND activo = TRUE;

    

    -- Insertar el movimiento registrado

    INSERT INTO movimientos_registrados (id_dispositivo, id_movimiento)

    VALUES (v_id_dispositivo, v_id_movimiento);

    

    SELECT LAST_INSERT_ID() AS id_registro;

END
//
DELIMITER ;

-- Stored Procedure: sp_agregar_movimiento_a_demo
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_agregar_movimiento_a_demo`(

    IN p_id_secuencia INT,

    IN p_nombre_movimiento VARCHAR(100),

    IN p_orden INT

)
BEGIN

    DECLARE v_id_movimiento INT;

    

    SELECT id_movimiento INTO v_id_movimiento 

    FROM cat_movimientos 

    WHERE nombre_movimiento = p_nombre_movimiento AND activo = TRUE;

    

    INSERT INTO detalle_secuencia_demo (id_secuencia, id_movimiento, orden_ejecucion)

    VALUES (p_id_secuencia, v_id_movimiento, p_orden);

END
//
DELIMITER ;

-- Stored Procedure: sp_agregar_movimiento_por_id
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_agregar_movimiento_por_id`(

    IN p_identificador_unico VARCHAR(100),

    IN p_id_movimiento INT

)
BEGIN

    DECLARE v_id_dispositivo INT;

    

    -- Obtener ID del dispositivo por identificador +?nico (solo activos)

    SELECT id_dispositivo INTO v_id_dispositivo 

    FROM dispositivos 

    WHERE identificador_unico = p_identificador_unico AND activo = TRUE;

    

    -- Insertar el movimiento registrado usando el ID directamente

    INSERT INTO movimientos_registrados (id_dispositivo, id_movimiento)

    VALUES (v_id_dispositivo, p_id_movimiento);

    

    SELECT LAST_INSERT_ID() AS id_registro;

END
//
DELIMITER ;

-- Stored Procedure: sp_agregar_obstaculo
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_agregar_obstaculo`(

    IN p_identificador_unico VARCHAR(100),

    IN p_nombre_estatus VARCHAR(50),

    IN p_distancia_cm DECIMAL(10,2)

)
BEGIN

    DECLARE v_id_dispositivo INT;

    DECLARE v_id_estatus INT;

    

    SELECT id_dispositivo INTO v_id_dispositivo 

    FROM dispositivos 

    WHERE identificador_unico = p_identificador_unico AND activo = TRUE;

    

    SELECT id_estatus INTO v_id_estatus 

    FROM cat_estatus_obstaculo 

    WHERE nombre_estatus = p_nombre_estatus;

    

    INSERT INTO obstaculos_registrados (id_dispositivo, id_estatus, distancia_cm)

    VALUES (v_id_dispositivo, v_id_estatus, p_distancia_cm);

    

    SELECT LAST_INSERT_ID() AS id_obstaculo;

END
//
DELIMITER ;

-- Stored Procedure: sp_crear_demo
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_crear_demo`(

    IN p_nombre_secuencia VARCHAR(100),

    IN p_descripcion VARCHAR(255)

)
BEGIN

    INSERT INTO secuencias_demo (nombre_secuencia, descripcion)

    VALUES (p_nombre_secuencia, p_descripcion);

    

    SELECT LAST_INSERT_ID() AS id_secuencia;

END
//
DELIMITER ;

-- Stored Procedure: sp_generar_configuracion_motores
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_generar_configuracion_motores`()
BEGIN

    DECLARE v_velocidad DECIMAL(10,2);

    DECLARE v_factor_vuelta DECIMAL(10,2);

    DECLARE v_factor_tiempo DECIMAL(10,2);

    DECLARE v_factor_giro_90 DECIMAL(10,2);



    DECLARE v_velocidad_vuelta DECIMAL(10,2);

    DECLARE v_tiempo_vuelta INT;

    DECLARE v_tiempo_giro_90 INT;

    DECLARE v_tiempo_giro_360 INT;



    -- Obtener par+?metros

    SELECT valor INTO v_velocidad

    FROM parametros

    WHERE clave = 'VELOCIDAD';



    SELECT valor INTO v_factor_vuelta

    FROM parametros

    WHERE clave = 'FACTOR_VUELTA';

    SELECT valor INTO v_factor_tiempo

    FROM parametros

    WHERE clave = 'FACTOR_TIEMPO';

    SELECT valor INTO v_factor_giro_90

    FROM parametros

    WHERE clave = 'FACTOR_GIRO_90';

    -- Calcular valores derivados

    SET v_velocidad_vuelta = v_velocidad * v_factor_vuelta;

    SET v_tiempo_vuelta = ROUND(v_factor_tiempo);

    SET v_tiempo_giro_90 = ROUND(v_factor_tiempo * v_factor_giro_90);

    SET v_tiempo_giro_360 = ROUND(v_factor_tiempo * v_factor_giro_90 * 4);

    -- Limpiar configuraciones anteriores

    DELETE FROM config_motor_movimiento;

    -- 1. Adelante

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, 'LOW', CAST(v_velocidad AS CHAR), 0, CAST(v_velocidad AS CHAR), 'LOW', 0

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Adelante';

    -- 2. Atr+?s

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad AS CHAR), 'LOW', 0, 'LOW', CAST(v_velocidad AS CHAR), 0

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Atr+?s';

    -- 3. Detener

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, 'LOW', 'LOW', 0, 'LOW', 'LOW', 0

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Detener';

    -- 4. Vuelta derecha adelante

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_vuelta, CAST(v_velocidad_vuelta AS CHAR), 'LOW', v_tiempo_vuelta

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Vuelta derecha adelante';

    -- 5. Vuelta izquierda adelante

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad_vuelta AS CHAR), 'LOW', v_tiempo_vuelta, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_vuelta

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Vuelta izquierda adelante';

    -- 6. Vuelta derecha atr+?s

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_vuelta, 'LOW', CAST(v_velocidad_vuelta AS CHAR), v_tiempo_vuelta

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Vuelta derecha atr+?s';

    -- 7. Vuelta izquierda atr+?s

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad_vuelta AS CHAR), 'LOW', v_tiempo_vuelta, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_vuelta

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Vuelta izquierda atr+?s';

    -- 8. Giro 90-? derecha

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_giro_90, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_giro_90

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Giro 90-? derecha';

    -- 9. Giro 90-? izquierda

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_giro_90, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_giro_90

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Giro 90-? izquierda';

    -- 10. Giro 360-? derecha

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_giro_360, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_giro_360

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Giro 360-? derecha';

    -- 11. Giro 360-? izquierda

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_giro_360, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_giro_360

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Giro 360-? izquierda';



END
//
DELIMITER ;

-- Stored Procedure: sp_repetir_demo
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_repetir_demo`(

    IN p_nombre_secuencia VARCHAR(100),

    IN p_identificador_unico VARCHAR(100)

)
BEGIN

    DECLARE v_id_dispositivo INT;

    DECLARE v_id_secuencia INT;

    DECLARE v_id_movimiento INT;

    DECLARE v_orden INT;

    DECLARE v_finished INT DEFAULT 0;

    DECLARE v_movimientos_insertados INT DEFAULT 0;

    DECLARE cur_movimientos CURSOR FOR

        SELECT dsd.id_movimiento, dsd.orden_ejecucion

        FROM secuencias_demo sd

        INNER JOIN detalle_secuencia_demo dsd ON sd.id_secuencia = dsd.id_secuencia

        WHERE sd.nombre_secuencia = p_nombre_secuencia

        ORDER BY dsd.orden_ejecucion;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;

    

    -- Manejo de errores para cuando no se encuentra el dispositivo

    DECLARE EXIT HANDLER FOR SQLEXCEPTION

    BEGIN

        SELECT 'Error: No se pudo ejecutar la demo. Verifica que el dispositivo y la demo existan.' AS mensaje;

    END;

    

    -- Obtener ID del dispositivo (con manejo de no encontrado)

    SELECT id_dispositivo INTO v_id_dispositivo 

    FROM dispositivos 

    WHERE identificador_unico = p_identificador_unico AND activo = TRUE;

    

    -- Si no se encontr+? el dispositivo, mostrar error y salir

    IF v_id_dispositivo IS NULL THEN

        SELECT CONCAT('Error: Dispositivo "', p_identificador_unico, '" no encontrado o inactivo.') AS mensaje;

    ELSE

        -- Obtener ID de la secuencia (con LIMIT 1 para evitar m+?ltiples resultados)

        SELECT id_secuencia INTO v_id_secuencia 

        FROM secuencias_demo 

        WHERE nombre_secuencia = p_nombre_secuencia

        LIMIT 1;

        

        -- Si no se encontr+? la demo, mostrar error y salir

        IF v_id_secuencia IS NULL THEN

            SELECT CONCAT('Error: Demo "', p_nombre_secuencia, '" no encontrada.') AS mensaje;

        ELSE

            -- Insertar cada movimiento de la demo como un movimiento registrado

            OPEN cur_movimientos;

            

            read_loop: LOOP

                FETCH cur_movimientos INTO v_id_movimiento, v_orden;

                IF v_finished = 1 THEN

                    LEAVE read_loop;

                END IF;

                

                INSERT INTO movimientos_registrados (id_dispositivo, id_movimiento)

                VALUES (v_id_dispositivo, v_id_movimiento);

                

                SET v_movimientos_insertados = v_movimientos_insertados + 1;

                

            END LOOP;

            

            CLOSE cur_movimientos;

            

            -- Devolver mensaje de +?xito

            SELECT CONCAT('??? Demo "', p_nombre_secuencia, '" ejecutada correctamente en dispositivo "', 

                         p_identificador_unico, '". Movimientos insertados: ', v_movimientos_insertados) AS mensaje;

        END IF;

    END IF;

END
//
DELIMITER ;

-- Stored Procedure: sp_ultimos_10_movimientos
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_ultimos_10_movimientos`()
BEGIN

    SELECT 

        cm.nombre_movimiento AS movimiento,

        mr.fecha_hora

    FROM movimientos_registrados mr

    INNER JOIN cat_movimientos cm ON mr.id_movimiento = cm.id_movimiento

    ORDER BY mr.fecha_hora DESC

    LIMIT 10;

END
//
DELIMITER ;

-- Stored Procedure: sp_ultimos_10_obstaculos
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_ultimos_10_obstaculos`()
BEGIN

    SELECT 

        ceo.nombre_estatus,

        o.distancia_cm,

        o.fecha_hora

    FROM obstaculos_registrados o

    INNER JOIN cat_estatus_obstaculo ceo ON o.id_estatus = ceo.id_estatus

    ORDER BY o.fecha_hora DESC

    LIMIT 10;

END
//
DELIMITER ;

-- Stored Procedure: sp_ultimo_movimiento
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_ultimo_movimiento`()
BEGIN

    SELECT 

        mr.id_registro,

        cm.nombre_movimiento AS movimiento,

        cmm.mia_estado, cmm.mia_pwm, cmm.mi_time,

        cmm.mda_estado, cmm.mda_pwm, cmm.md_time,

        mr.fecha_hora,

        d.nombre_dispositivo,

        d.identificador_unico,

        d.ip_address,

        d.pais,

        d.ciudad,

        d.latitud,

        d.longitud

    FROM movimientos_registrados mr

    INNER JOIN dispositivos d ON mr.id_dispositivo = d.id_dispositivo

    INNER JOIN cat_movimientos cm ON mr.id_movimiento = cm.id_movimiento

    INNER JOIN config_motor_movimiento cmm ON cm.id_movimiento = cmm.id_movimiento

    WHERE d.activo = TRUE

    ORDER BY mr.fecha_hora DESC

    LIMIT 1;

END
//
DELIMITER ;

-- Stored Procedure: sp_ultimo_movimiento_esp
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_ultimo_movimiento_esp`()
BEGIN
    SELECT 
        cm.nombre_movimiento AS movimiento,
        cmm.mia_pwm,
        cmm.mda_pwm,
        cmm.mi_time
    FROM movimientos_registrados mr
    INNER JOIN dispositivos d ON mr.id_dispositivo = d.id_dispositivo
    INNER JOIN cat_movimientos cm ON mr.id_movimiento = cm.id_movimiento
    INNER JOIN config_motor_movimiento cmm ON cm.id_movimiento = cmm.id_movimiento
    WHERE d.activo = TRUE
    ORDER BY mr.fecha_hora DESC
    LIMIT 1;
END
//
DELIMITER ;

-- Stored Procedure: sp_ultimo_obstaculo
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_ultimo_obstaculo`()
BEGIN

    SELECT 

        ceo.nombre_estatus,

        o.distancia_cm,

        o.fecha_hora

    FROM obstaculos_registrados o

    INNER JOIN cat_estatus_obstaculo ceo ON o.id_estatus = ceo.id_estatus

    ORDER BY o.fecha_hora DESC

    LIMIT 1;

END
//
DELIMITER ;

-- Stored Procedure: sp_visualizar_demo
DELIMITER //
CREATE DEFINER=`admin`@`%` PROCEDURE `sp_visualizar_demo`(

    IN p_nombre_secuencia VARCHAR(100)

)
BEGIN

    SELECT 

        sd.nombre_secuencia AS demo,

        sd.descripcion,

        cm.nombre_movimiento AS movimiento,

        dsd.orden_ejecucion

    FROM secuencias_demo sd

    INNER JOIN detalle_secuencia_demo dsd ON sd.id_secuencia = dsd.id_secuencia

    INNER JOIN cat_movimientos cm ON dsd.id_movimiento = cm.id_movimiento

    WHERE sd.nombre_secuencia = p_nombre_secuencia

    ORDER BY dsd.orden_ejecucion;

END
//
DELIMITER ;

