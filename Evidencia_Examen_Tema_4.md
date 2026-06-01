# [Insertar Logo de la Institución Aquí]

## INGENIERÍA EN SISTEMAS COMPUTACIONALES
### Implementación de soluciones IoT

**Materia:** Implementación de soluciones IoT
**Tema:** 4.1 Examen Tema 4. Desarrollo de aplicaciones IoT
**Maestro:** M.C. Víctor Manuel Pinedo Fernández
**Alumno:** [Escribe tu nombre completo aquí]
**Fecha:** [Escribe la fecha de hoy]

---

# Desarrollo de la Solución

El presente documento describe la solución desarrollada para el control y monitoreo de un vehículo IoT, cumpliendo con las reglas de negocio establecidas. *(Nota: De acuerdo con los alcances del proyecto actual, el módulo de detección de obstáculos ha sido descartado de la implementación).*

## 1. Arquitectura de la Solución
La solución se compone de tres elementos principales:
- **Base de Datos (AWS RDS):** Se implementó una base de datos MySQL alojada en Amazon RDS para garantizar alta disponibilidad. Se utilizan Stored Procedures (Procedimientos Almacenados) para registrar y consultar eventos de manera eficiente y segura.
- **Back-end (Flask + WebSockets):** Desarrollado en Python, ejecutándose en una instancia de AWS. El servidor expone una API REST (HTTP en el puerto 5001) para la comunicación con la aplicación web, y un motor de WebSockets nativos (puerto 5000) para enviar comandos en tiempo real al dispositivo de hardware ESP8266.
- **Front-end (Control y Monitoreo):** Dos aplicaciones web desarrolladas con React y Three.js (para la visualización 3D interactiva del auto). Estáticas y listas para ser desplegadas en GitHub Pages.

## 2. Aplicación Web de Control
- **Panel de Control:** Interfaz con botones para enviar los 11 comandos de movimiento exigidos.
- **Estética:** Se utilizó un diseño inmersivo estilo Synthwave Neon para el vehículo, renderizado en tiempo real en una sola pantalla sin necesidad de hacer scroll.
- **Características:** Favicon integrado, llamadas a APIs REST para guardar historial, manejo de estado para las velocidades globales y rutinas para ejecutar secuencias en modo DEMO.

## 3. Aplicación Web de Monitoreo
- Se implementó un dashboard en el Front-end que consume los eventos a través de la API REST.
- Muestra los últimos registros de estatus del vehículo consultando la base de datos de manera periódica, presentando el historial de forma visualmente atractiva en una sola pantalla.

---

# Documentación de las APIs

A continuación se documentan los endpoints HTTP y eventos WebSocket expuestos por el Back-end para la solución IoT.

**Servidor Base:** `http://50.16.92.186:5001`

### 1. API HTTP: Lista de Movimientos (`GET /api/movimientos`)
- **Descripción:** Devuelve el catálogo de los 11 movimientos disponibles con sus nombres e IDs.
- **Respuesta:**
  ```json
  {
    "success": true,
    "data": [
      {"id_movimiento": 1, "nombre_movimiento": "Adelante"}
    ]
  }
  ```

### 2. API HTTP: Obtener Último Movimiento (`GET /api/ultimo_movimiento`)
- **Descripción:** Obtiene el último movimiento registrado en la base de datos (incluye nombre, PWM, tiempo, fecha y datos del dispositivo).
- **Stored Procedure utilizado:** `sp_ultimo_movimiento`
- **Respuesta:**
  ```json
  {
    "success": true,
    "data": {
      "id_movimiento": 1,
      "nombre_movimiento": "Adelante",
      "mia_pwm": 255,
      "mda_pwm": 255,
      "mi_time": 800,
      "fecha_hora": "2026-05-29 15:30:00"
    }
  }
  ```

### 3. API HTTP: Control de Velocidad (`GET /api/velocidad` y `POST /api/velocidad`)
- **Descripción:** Obtiene o actualiza la velocidad global del carrito (escala de 0 a 255). El servidor escalará los PWM de los motores en base a este valor (excepto en giros de ángulo fijo).
- **Payload POST:** `{"velocidad": 150}`
- **Respuesta POST:** `{"success": true, "velocidad": 150}`

### 4. API HTTP: Enviar Movimiento (`POST /api/enviar_movimiento`)
- **Descripción:** Envía un comando de movimiento al dispositivo IoT y guarda el registro en la base de datos.
- **Stored Procedure utilizado:** `sp_agregar_movimiento`
- **Payload:**
  ```json
  {
    "movimiento": "Adelante",
    "identificador": "ESP8266-CAR-001"
  }
  ```
- **Respuesta:** `{"success": true, "message": "Movimiento Adelante enviado"}`

### 5. API HTTP: Secuencias DEMO (`GET /api/demos` y `POST /api/ejecutar_demo`)
- **Descripción:** Obtiene la lista de secuencias DEMO y permite ejecutarlas. El servidor envía cada comando de la secuencia por WebSocket respetando los tiempos reales de retraso.
- **Stored Procedures vinculados a DEMO:** `sp_crear_demo`, `sp_agregar_movimiento_a_demo`, `sp_repetir_demo`

### 6. Comunicación WebSocket (IoT - Tiempo Real)
- **Servidor Base:** `ws://50.16.92.186:5000`
- **Descripción:** Protocolo nativo (RFC 6455). El servidor envía directamente los comandos de hardware al ESP8266. El ESP8266 ejecuta el comando en sus motores físicos y se detiene según el tiempo (`mi_time`).
  ```json
  {
    "success": true,
    "data": {
      "movimiento": "Adelante",
      "mia_pwm": 255,
      "mda_pwm": 255,
      "mi_time": 800
    }
  }
  ```

---

# Enlaces Entregables (Añadir a la Plataforma)

**Nota para el alumno:** Pega estos enlaces en la caja de texto de tu entrega junto con tus conclusiones.

- **URL de la aplicación Web de control:** [Pegar URL de Github Pages]
- **URL de la aplicación Web de monitoreo:** [Pegar URL de Github Pages]
- **Código Fuente Front-end:** `https://github.com/Villa19d/Iot_carrito_aws_frontend`
- **Código Fuente Back-end:** `https://github.com/Villa19d/Iot_carrito_aws_backend`
- **SQL Scripts:** `https://github.com/Villa19d/Iot_carrito_aws_backend/tree/main/SQL_Scripts`

*(Al final de tu entrega en la plataforma, redacta tus conclusiones personales sobre el aprendizaje de AWS, WebSockets y desarrollo Web).*
