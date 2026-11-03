-- ============================================================================
-- 02_parche_esp_nov2026.sql  -  Carrito IoT  -  COMPLETE DATABASE SCRIPT
-- ============================================================================
-- Self-contained script: recreates the whole `carrito_iot` database and then
-- applies the ESP8266 compatibility corrections. Run it once and you are done.
--
-- WHAT IT DOES, IN ORDER
--   1) CREATE DATABASE `carrito_iot` (utf8mb4) + USE it.
--   2) Creates the 11 tables (each preceded by DROP TABLE IF EXISTS, so the
--      script is safe to re-run and rebuilds from scratch).
--   3) Inserts the initial data / catalogs: cat_movimientos, parametros,
--      secuencias_demo, detalle_secuencia_demo, dispositivos,
--      config_motor_movimiento, etc.
--   4) Creates the 13 stored procedures from the original dump.
--   5) CORRECTION SECTION (bottom of the file): creates the missing
--      `sp_ultimo_movimiento_esp` and re-creates
--      `sp_generar_configuracion_motores` with the correct column names.
--   6) Regenerates the motor configuration and validates the ESP procedure.
--
-- EXPECTED RESULT AFTER RUNNING
--   * 11 tables
--   * 14 stored procedures
--   * initial data loaded
--
-- HOW TO RUN (VS Code MySQL/RDS connection)
--   * Open this file and "Run" the entire script, OR
--   * mysql CLI:  mysql -h <host> -u <user> -p < 02_parche_esp_nov2026.sql
--   * If your client does not support `DELIMITER //`, run each
--     CREATE PROCEDURE block separately.
--
-- SECURITY NOTE
--   The original dump's server banner was redacted (`-- Host: (redacted)`) and
--   all `DEFINER=...` clauses were removed for portability. No credentials are
--   stored in this file.
-- ============================================================================


-- MySQL dump 10.13  Distrib 8.4.7, for Win64 (x86_64)
--
-- Host: (redacted)
-- ------------------------------------------------------
-- Server version	8.4.7

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Current Database: `carrito_iot`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `carrito_iot` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `carrito_iot`;

-- ---------------------------------------------------------------------------
-- IMPORTANT: keep foreign-key checks DISABLED while the dump is loaded.
-- Some seed rows reference parent rows that are inserted LATER in this file
-- (e.g. `detalle_secuencia_demo`.`id_secuencia` -> `secuencias_demo`), so with
-- FK checks ON those INSERTs fail. This is an EXPLICIT `SET` (not a /*! */
-- version comment) so clients that run the script statement-by-statement do
-- not skip it. It is restored at the end of the file.
-- ---------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;

--
-- Table structure for table `cat_estatus_obstaculo`
--

DROP TABLE IF EXISTS `cat_estatus_obstaculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cat_estatus_obstaculo` (
  `id_estatus` int NOT NULL AUTO_INCREMENT,
  `nombre_estatus` varchar(50) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_estatus`),
  UNIQUE KEY `nombre_estatus` (`nombre_estatus`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cat_estatus_obstaculo`
--

LOCK TABLES `cat_estatus_obstaculo` WRITE;
/*!40000 ALTER TABLE `cat_estatus_obstaculo` DISABLE KEYS */;
INSERT INTO `cat_estatus_obstaculo` VALUES (1,'LIBRE','No se detecta obstáculo'),(2,'OBSTACULO','Se detecta obstáculo a distancia media'),(3,'MUY_CERCA','Obstáculo a menos de 10cm - peligro de colisión');
/*!40000 ALTER TABLE `cat_estatus_obstaculo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cat_movimientos`
--

DROP TABLE IF EXISTS `cat_movimientos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cat_movimientos` (
  `id_movimiento` int NOT NULL AUTO_INCREMENT,
  `nombre_movimiento` varchar(100) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_movimiento`),
  UNIQUE KEY `nombre_movimiento` (`nombre_movimiento`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cat_movimientos`
--

LOCK TABLES `cat_movimientos` WRITE;
/*!40000 ALTER TABLE `cat_movimientos` DISABLE KEYS */;
INSERT INTO `cat_movimientos` VALUES (1,'Adelante',1),(2,'Atrás',1),(3,'Detener',1),(4,'Vuelta adelante derecha',1),(5,'Vuelta adelante izquierda',1),(6,'Vuelta atrás derecha',1),(7,'Vuelta atrás izquierda',1),(8,'Giro 90° derecha',1),(9,'Giro 90° izquierda',1),(10,'Giro 360° derecha',1),(11,'Giro 360° izquierda',1);
/*!40000 ALTER TABLE `cat_movimientos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `config_motor_movimiento`
--

DROP TABLE IF EXISTS `config_motor_movimiento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `config_motor_movimiento`
--

LOCK TABLES `config_motor_movimiento` WRITE;
/*!40000 ALTER TABLE `config_motor_movimiento` DISABLE KEYS */;
INSERT INTO `config_motor_movimiento` VALUES (8,1,'LOW','255',0,'LOW','255',0),(9,2,'LOW','255',0,'LOW','255',0),(10,3,'LOW','0',0,'LOW','0',0),(11,4,'LOW','200',500,'LOW','255',500),(12,5,'LOW','255',500,'LOW','200',500),(13,6,'LOW','200',500,'LOW','255',500),(14,7,'LOW','255',500,'LOW','200',500),(15,8,'LOW','255',500,'LOW','255',500),(16,9,'LOW','255',500,'LOW','255',500),(17,10,'LOW','255',2000,'LOW','255',2000),(18,11,'LOW','255',2000,'LOW','255',2000);
/*!40000 ALTER TABLE `config_motor_movimiento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_secuencia_demo`
--
use `carrito_iot`;
DROP TABLE IF EXISTS `detalle_secuencia_demo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_secuencia_demo`
--

LOCK TABLES `detalle_secuencia_demo` WRITE;
/*!40000 ALTER TABLE `detalle_secuencia_demo` DISABLE KEYS */;
INSERT INTO `detalle_secuencia_demo` VALUES (6,3,1,1),(7,3,4,2),(8,3,1,3),(9,3,4,4),(10,3,1,5),(11,3,4,6),(12,3,1,7),(13,3,4,8),(14,4,1,1),(15,4,3,2),(16,4,2,3),(17,4,3,4),(18,5,4,1),(19,5,4,2),(20,6,1,1),(21,6,2,2),(22,6,5,3),(23,6,1,4),(24,6,4,5),(25,6,2,6),(26,6,3,7),(32,9,1,1),(33,9,4,2),(34,9,1,3),(35,9,5,4),(36,9,1,5);
/*!40000 ALTER TABLE `detalle_secuencia_demo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispositivos`
--

DROP TABLE IF EXISTS `dispositivos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispositivos`
--

LOCK TABLES `dispositivos` WRITE;
/*!40000 ALTER TABLE `dispositivos` DISABLE KEYS */;
INSERT INTO `dispositivos` VALUES (1,'Carrito Principal','ESP8266-CAR-001','Carrito IoT principal con sensor ultrasónico','192.168.1.100','México','CDMX',19.4326080,-99.1332090,1,'2026-03-23 06:37:47'),(2,'Carrito Secundario','ESP8266-CAR-002','Carrito de pruebas','192.168.1.101','México','Guadalajara',20.6596990,-103.3496090,1,'2026-03-23 06:37:47');
/*!40000 ALTER TABLE `dispositivos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ejecuciones_secuencia_demo`
--

DROP TABLE IF EXISTS `ejecuciones_secuencia_demo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ejecuciones_secuencia_demo`
--

LOCK TABLES `ejecuciones_secuencia_demo` WRITE;
/*!40000 ALTER TABLE `ejecuciones_secuencia_demo` DISABLE KEYS */;
/*!40000 ALTER TABLE `ejecuciones_secuencia_demo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `movimientos_registrados`
--

DROP TABLE IF EXISTS `movimientos_registrados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `movimientos_registrados`
--

LOCK TABLES `movimientos_registrados` WRITE;
/*!40000 ALTER TABLE `movimientos_registrados` DISABLE KEYS */;
INSERT INTO `movimientos_registrados` VALUES (1,1,1,'2026-03-23 06:41:56'),(2,1,1,'2026-03-23 06:42:04'),(3,1,4,'2026-03-23 06:42:06'),(4,1,1,'2026-03-23 06:42:07'),(5,2,2,'2026-03-23 06:42:08'),(6,2,3,'2026-03-23 06:42:09'),(7,1,1,'2026-03-23 06:43:56'),(8,1,4,'2026-03-23 06:43:56'),(9,1,1,'2026-03-23 06:43:56'),(10,1,4,'2026-03-23 06:43:56'),(11,1,1,'2026-03-23 06:43:56'),(12,1,4,'2026-03-23 06:43:56'),(13,1,1,'2026-03-23 06:43:56'),(14,1,4,'2026-03-23 06:43:56'),(15,2,1,'2026-03-23 06:43:58'),(16,2,2,'2026-03-23 06:43:58'),(17,2,5,'2026-03-23 06:43:58'),(18,2,1,'2026-03-23 06:43:58'),(19,2,4,'2026-03-23 06:43:58'),(20,2,2,'2026-03-23 06:43:58'),(21,2,3,'2026-03-23 06:43:58'),(22,1,1,'2026-03-23 08:20:32'),(23,1,1,'2026-03-23 18:11:56'),(24,1,7,'2026-03-23 18:22:29'),(25,1,7,'2026-03-23 18:23:43'),(26,1,7,'2026-03-23 18:33:19');
/*!40000 ALTER TABLE `movimientos_registrados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `obstaculos_registrados`
--

DROP TABLE IF EXISTS `obstaculos_registrados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `obstaculos_registrados`
--

LOCK TABLES `obstaculos_registrados` WRITE;
/*!40000 ALTER TABLE `obstaculos_registrados` DISABLE KEYS */;
INSERT INTO `obstaculos_registrados` VALUES (1,1,1,NULL,'2026-03-23 06:42:19'),(2,1,2,15.50,'2026-03-23 06:42:20'),(3,1,3,5.20,'2026-03-23 06:42:21'),(4,2,1,NULL,'2026-03-23 06:42:22'),(5,1,2,25.30,'2026-03-23 08:22:08'),(6,1,2,25.30,'2026-03-23 08:22:32'),(7,1,1,NULL,'2026-03-23 17:52:49'),(8,1,1,NULL,'2026-03-23 18:14:04'),(9,1,2,15.50,'2026-03-23 18:14:08');
/*!40000 ALTER TABLE `obstaculos_registrados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `parametros`
--

DROP TABLE IF EXISTS `parametros`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `parametros` (
  `id_parametro` int NOT NULL AUTO_INCREMENT,
  `clave_parametro` varchar(50) NOT NULL,
  `valor_parametro` decimal(10,2) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `ultima_actualizacion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_parametro`),
  UNIQUE KEY `clave_parametro` (`clave_parametro`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `parametros`
--

LOCK TABLES `parametros` WRITE;
/*!40000 ALTER TABLE `parametros` DISABLE KEYS */;
INSERT INTO `parametros` VALUES (1,'VELOCIDAD',255.00,'Velocidad base del carrito','2026-05-13 17:58:51'),(2,'FACTOR_VUELTA',0.75,'Factor multiplicador para vueltas','2026-05-13 17:58:51'),(3,'FACTOR_TIEMPO',1000.00,'Tiempo base en ms','2026-05-13 17:58:51'),(4,'FACTOR_GIRO_90',0.50,'Factor multiplicador para giro de 90 grados','2026-05-13 17:58:51');
/*!40000 ALTER TABLE `parametros` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `secuencias_demo`
--

DROP TABLE IF EXISTS `secuencias_demo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `secuencias_demo` (
  `id_secuencia` int NOT NULL AUTO_INCREMENT,
  `nombre_secuencia` varchar(100) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_secuencia`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `secuencias_demo`
--

LOCK TABLES `secuencias_demo` WRITE;
/*!40000 ALTER TABLE `secuencias_demo` DISABLE KEYS */;
INSERT INTO `secuencias_demo` VALUES (1,'Zig Zag','Secuencia para esquivar obstáculos'),(3,'Cuadrado','Recorrido de un cuadrado'),(4,'Estacionar','Maniobra para estacionar'),(5,'Giro en U','Giro de 180 grados'),(6,'Baile','Secuencia divertida'),(7,'Demo Final','Prueba de funcionamiento'),(9,'Testing','Secuencia para esquivar obstáculos');
/*!40000 ALTER TABLE `secuencias_demo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `telemetria_dispositivo`
--

DROP TABLE IF EXISTS `telemetria_dispositivo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `telemetria_dispositivo`
--

LOCK TABLES `telemetria_dispositivo` WRITE;
/*!40000 ALTER TABLE `telemetria_dispositivo` DISABLE KEYS */;
INSERT INTO `telemetria_dispositivo` VALUES (1,1,'192.168.1.100','México','CDMX',19.4326080,-99.1332090,'2026-03-23 07:02:04'),(2,2,'192.168.1.101','México','Guadalajara',20.6596990,-103.3496090,'2026-03-23 07:02:04');
/*!40000 ALTER TABLE `telemetria_dispositivo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'carrito_iot'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_actualizar_parametro` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_actualizar_parametro`(

    IN p_clave VARCHAR(50),

    IN p_valor DECIMAL(10,2)

)
BEGIN

    -- Verificar si el parámetro existe

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

    

    -- Devolver el parámetro actualizado

    SELECT clave_parametro, valor_parametro, ultima_actualizacion

    FROM parametros 

    WHERE clave_parametro = p_clave;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_agregar_movimiento` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_agregar_movimiento`(

    IN p_identificador_unico VARCHAR(100),

    IN p_nombre_movimiento VARCHAR(100)

)
BEGIN

    DECLARE v_id_dispositivo INT;

    DECLARE v_id_movimiento INT;

    

    -- Obtener ID del dispositivo por identificador único (solo activos)

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

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_agregar_movimiento_a_demo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_agregar_movimiento_a_demo`(

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

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_agregar_movimiento_por_id` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_agregar_movimiento_por_id`(

    IN p_identificador_unico VARCHAR(100),

    IN p_id_movimiento INT

)
BEGIN

    DECLARE v_id_dispositivo INT;

    

    -- Obtener ID del dispositivo por identificador único (solo activos)

    SELECT id_dispositivo INTO v_id_dispositivo 

    FROM dispositivos 

    WHERE identificador_unico = p_identificador_unico AND activo = TRUE;

    

    -- Insertar el movimiento registrado usando el ID directamente

    INSERT INTO movimientos_registrados (id_dispositivo, id_movimiento)

    VALUES (v_id_dispositivo, p_id_movimiento);

    

    SELECT LAST_INSERT_ID() AS id_registro;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_agregar_obstaculo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_agregar_obstaculo`(

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

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_demo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_crear_demo`(

    IN p_nombre_secuencia VARCHAR(100),

    IN p_descripcion VARCHAR(255)

)
BEGIN

    INSERT INTO secuencias_demo (nombre_secuencia, descripcion)

    VALUES (p_nombre_secuencia, p_descripcion);

    

    SELECT LAST_INSERT_ID() AS id_secuencia;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_generar_configuracion_motores` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_generar_configuracion_motores`()
BEGIN

    DECLARE v_velocidad DECIMAL(10,2);

    DECLARE v_factor_vuelta DECIMAL(10,2);

    DECLARE v_factor_tiempo DECIMAL(10,2);

    DECLARE v_factor_giro_90 DECIMAL(10,2);



    DECLARE v_velocidad_vuelta DECIMAL(10,2);

    DECLARE v_tiempo_vuelta INT;

    DECLARE v_tiempo_giro_90 INT;

    DECLARE v_tiempo_giro_360 INT;



    -- Obtener parámetros

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

    -- 2. Atrás

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad AS CHAR), 'LOW', 0, 'LOW', CAST(v_velocidad AS CHAR), 0

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Atrás';

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

    -- 6. Vuelta derecha atrás

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_vuelta, 'LOW', CAST(v_velocidad_vuelta AS CHAR), v_tiempo_vuelta

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Vuelta derecha atrás';

    -- 7. Vuelta izquierda atrás

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad_vuelta AS CHAR), 'LOW', v_tiempo_vuelta, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_vuelta

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Vuelta izquierda atrás';

    -- 8. Giro 90° derecha

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_giro_90, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_giro_90

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Giro 90° derecha';

    -- 9. Giro 90° izquierda

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_giro_90, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_giro_90

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Giro 90° izquierda';

    -- 10. Giro 360° derecha

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_giro_360, 'LOW', CAST(v_velocidad AS CHAR), v_tiempo_giro_360

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Giro 360° derecha';

    -- 11. Giro 360° izquierda

    INSERT INTO config_motor_movimiento (id_movimiento, MIA, MIB, MITime, MDA, MDB, MDTime)

    SELECT id_movimiento, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_giro_360, CAST(v_velocidad AS CHAR), 'LOW', v_tiempo_giro_360

    FROM cat_movimientos

    WHERE nombre_movimiento = 'Giro 360° izquierda';



END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_repetir_demo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_repetir_demo`(

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

    

    -- Si no se encontró el dispositivo, mostrar error y salir

    IF v_id_dispositivo IS NULL THEN

        SELECT CONCAT('Error: Dispositivo "', p_identificador_unico, '" no encontrado o inactivo.') AS mensaje;

    ELSE

        -- Obtener ID de la secuencia (con LIMIT 1 para evitar múltiples resultados)

        SELECT id_secuencia INTO v_id_secuencia 

        FROM secuencias_demo 

        WHERE nombre_secuencia = p_nombre_secuencia

        LIMIT 1;

        

        -- Si no se encontró la demo, mostrar error y salir

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

            

            -- Devolver mensaje de éxito

            SELECT CONCAT('✅ Demo "', p_nombre_secuencia, '" ejecutada correctamente en dispositivo "', 

                         p_identificador_unico, '". Movimientos insertados: ', v_movimientos_insertados) AS mensaje;

        END IF;

    END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_ultimos_10_movimientos` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_ultimos_10_movimientos`()
BEGIN

    SELECT 

        cm.nombre_movimiento AS movimiento,

        mr.fecha_hora

    FROM movimientos_registrados mr

    INNER JOIN cat_movimientos cm ON mr.id_movimiento = cm.id_movimiento

    ORDER BY mr.fecha_hora DESC

    LIMIT 10;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_ultimos_10_obstaculos` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_ultimos_10_obstaculos`()
BEGIN

    SELECT 

        ceo.nombre_estatus,

        o.distancia_cm,

        o.fecha_hora

    FROM obstaculos_registrados o

    INNER JOIN cat_estatus_obstaculo ceo ON o.id_estatus = ceo.id_estatus

    ORDER BY o.fecha_hora DESC

    LIMIT 10;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_ultimo_movimiento` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_ultimo_movimiento`()
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

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_ultimo_obstaculo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_ultimo_obstaculo`()
BEGIN

    SELECT 

        ceo.nombre_estatus,

        o.distancia_cm,

        o.fecha_hora

    FROM obstaculos_registrados o

    INNER JOIN cat_estatus_obstaculo ceo ON o.id_estatus = ceo.id_estatus

    ORDER BY o.fecha_hora DESC

    LIMIT 1;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_visualizar_demo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_visualizar_demo`(

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

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-24 14:01:22

-- ============================================================================
-- CORRECTION SECTION  (originally the standalone 02_parche_esp_nov2026.sql)
-- ----------------------------------------------------------------------------
--   Applied AFTER the base dump above, so it overrides two procedures:
--     1) Creates `sp_ultimo_movimiento_esp` (it was MISSING from the dump).
--     2) Re-creates `sp_generar_configuracion_motores` targeting the REAL
--        columns of `config_motor_movimiento`
--        (mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time),
--        replacing the broken MIA/MIB/MITime/MDA/MDB/MDTime names.
--     3) Regenerates the motor configuration and validates the ESP SP.
--
-- NOTES
--   * `DELIMITER //` is a client-side directive; if your client does not
--     support it, run each CREATE PROCEDURE block separately.
--   * `CALL sp_ultimo_movimiento_esp()` may return an EMPTY result set when
--     there are no recent movements; that is expected and is NOT an error.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Create the missing stored procedure for the ESP8266
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `sp_ultimo_movimiento_esp`;
DELIMITER //
CREATE PROCEDURE `sp_ultimo_movimiento_esp`()
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
END //
DELIMITER ;

-- ---------------------------------------------------------------------------
-- 2. Fix sp_generar_configuracion_motores (real config_motor_movimiento columns)
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `sp_generar_configuracion_motores`;
DELIMITER //
CREATE PROCEDURE `sp_generar_configuracion_motores`()
BEGIN
    DECLARE v_velocidad DECIMAL(10,2);
    DECLARE v_factor_vuelta DECIMAL(10,2);
    DECLARE v_factor_tiempo DECIMAL(10,2);
    DECLARE v_factor_giro_90 DECIMAL(10,2);
    DECLARE v_velocidad_vuelta DECIMAL(10,2);
    DECLARE v_tiempo_vuelta INT;
    DECLARE v_tiempo_giro_90 INT;
    DECLARE v_tiempo_giro_360 INT;
    SELECT valor_parametro INTO v_velocidad FROM parametros WHERE clave_parametro = 'VELOCIDAD';
    SELECT valor_parametro INTO v_factor_vuelta FROM parametros WHERE clave_parametro = 'FACTOR_VUELTA';
    SELECT valor_parametro INTO v_factor_tiempo FROM parametros WHERE clave_parametro = 'FACTOR_TIEMPO';
    SELECT valor_parametro INTO v_factor_giro_90 FROM parametros WHERE clave_parametro = 'FACTOR_GIRO_90';
    SET v_velocidad_vuelta = v_velocidad * v_factor_vuelta;
    SET v_tiempo_vuelta = ROUND(v_factor_tiempo * 0.5);
    SET v_tiempo_giro_90 = ROUND(v_factor_tiempo * v_factor_giro_90);
    SET v_tiempo_giro_360 = 2000;
    DELETE FROM config_motor_movimiento;
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), 0, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), 0 FROM cat_movimientos WHERE nombre_movimiento = 'Adelante';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), 0, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), 0 FROM cat_movimientos WHERE nombre_movimiento = 'Atrás';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', '0', 0, 'LOW', '0', 0 FROM cat_movimientos WHERE nombre_movimiento = 'Detener';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad_vuelta) AS CHAR), v_tiempo_vuelta, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_vuelta FROM cat_movimientos WHERE nombre_movimiento = 'Vuelta adelante derecha';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_vuelta, 'LOW', CAST(ROUND(v_velocidad_vuelta) AS CHAR), v_tiempo_vuelta FROM cat_movimientos WHERE nombre_movimiento = 'Vuelta adelante izquierda';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad_vuelta) AS CHAR), v_tiempo_vuelta, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_vuelta FROM cat_movimientos WHERE nombre_movimiento = 'Vuelta atrás derecha';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_vuelta, 'LOW', CAST(ROUND(v_velocidad_vuelta) AS CHAR), v_tiempo_vuelta FROM cat_movimientos WHERE nombre_movimiento = 'Vuelta atrás izquierda';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_giro_90, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_giro_90 FROM cat_movimientos WHERE nombre_movimiento = 'Giro 90° derecha';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_giro_90, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_giro_90 FROM cat_movimientos WHERE nombre_movimiento = 'Giro 90° izquierda';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_giro_360, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_giro_360 FROM cat_movimientos WHERE nombre_movimiento = 'Giro 360° derecha';
    INSERT INTO config_motor_movimiento (id_movimiento, mia_estado, mia_pwm, mi_time, mda_estado, mda_pwm, md_time)
    SELECT id_movimiento, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_giro_360, 'LOW', CAST(ROUND(v_velocidad) AS CHAR), v_tiempo_giro_360 FROM cat_movimientos WHERE nombre_movimiento = 'Giro 360° izquierda';
END //
DELIMITER ;

-- ---------------------------------------------------------------------------
-- 3. Regenerate the initial motor configuration
-- ---------------------------------------------------------------------------
CALL sp_generar_configuracion_motores();

-- ---------------------------------------------------------------------------
-- 4. Validate the ESP8266 procedure (empty result set is OK)
-- ---------------------------------------------------------------------------
CALL sp_ultimo_movimiento_esp();

-- ---------------------------------------------------------------------------
-- Restore normal foreign-key enforcement (was disabled right after USE).
-- ---------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;


-- ---------------------------------------------------------------------------
-- Checamos si tenemos todo en orden
-- ---------------------------------------------------------------------------
SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='carrito_iot';
SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='carrito_iot' AND ROUTINE_TYPE='PROCEDURE';