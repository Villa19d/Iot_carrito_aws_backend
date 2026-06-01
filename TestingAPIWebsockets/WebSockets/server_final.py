# server_final.py
import socket
import threading
import json
import hashlib
import base64
import re
import time
from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector

# ========== CONFIGURACIÓN BD ==========
DB_CONFIG = {
    'host': 'instancia-iot.cpcio88easmg.us-east-2.rds.amazonaws.com',
    'user': 'admin',
    'password': 'izy_BGCquTvR_x5',
    'database': 'carrito_iot',
    'port': 3306,
    'autocommit': True,
    'charset': 'utf8mb4'
}

# ========== MAPEO DE MOVIMIENTOS ==========
MOVIMIENTOS_MAP = {
    1: "Adelante",
    2: "Atrás",
    3: "Detener",
    4: "Vuelta adelante derecha",
    5: "Vuelta adelante izquierda",
    6: "Vuelta atrás derecha",
    7: "Vuelta atrás izquierda",
    8: "Giro 90° derecha",
    9: "Giro 90° izquierda",
    10: "Giro 360° derecha",
    11: "Giro 360° izquierda"
}

# Movimientos que NO deben verse afectados por la velocidad global
MOVIMIENTOS_VELOCIDAD_FIJA = {8, 9, 10, 11}  # IDs de giros

# Tiempos especiales (ms) – se mantienen
TIEMPOS_ESPECIALES = {
    1: 500,  # 0.5s para Adelante (útil para zig zag y cuadrado)
    8: 600,
    9: 600,
    10: 2000,
    11: 2000
}

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

websocket_clients = []
VELOCIDAD_GLOBAL = 1.0

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

def cargar_velocidad_global():
    global VELOCIDAD_GLOBAL
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT valor_parametro FROM parametros WHERE clave_parametro = 'VELOCIDAD'")
        res = cursor.fetchone()
        if res:
            VELOCIDAD_GLOBAL = float(res[0]) / 255.0
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Error cargando velocidad: {e}")

# ========== ENDPOINTS API ==========

@app.route('/api/movimientos', methods=['GET'])
def get_movimientos():
    movimientos = [{"id_movimiento": k, "nombre_movimiento": v} for k, v in MOVIMIENTOS_MAP.items()]
    return jsonify({'success': True, 'data': movimientos})

@app.route('/api/ultimo_movimiento', methods=['GET'])
def get_ultimo_movimiento():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT cm.id_movimiento, cm.nombre_movimiento, cmm.mia_pwm, cmm.mda_pwm, cmm.mi_time, mr.fecha_hora
        FROM movimientos_registrados mr
        JOIN cat_movimientos cm ON mr.id_movimiento = cm.id_movimiento
        JOIN config_motor_movimiento cmm ON cm.id_movimiento = cmm.id_movimiento
        ORDER BY mr.fecha_hora DESC LIMIT 1
    """)
    resultado = cursor.fetchone()
    cursor.close()
    conn.close()
    if resultado:
        nombre_correcto = MOVIMIENTOS_MAP.get(resultado['id_movimiento'], resultado['nombre_movimiento'])
        resultado['nombre_movimiento'] = nombre_correcto
    return jsonify({'success': True, 'data': resultado})

@app.route('/api/velocidad', methods=['GET'])
def get_velocidad():
    return jsonify({'success': True, 'velocidad': int(VELOCIDAD_GLOBAL * 255)})

@app.route('/api/velocidad', methods=['POST'])
def set_velocidad():
    global VELOCIDAD_GLOBAL
    data = request.get_json()
    nuevo_valor = data.get('velocidad')
    if nuevo_valor is None:
        return jsonify({'success': False, 'error': 'Falta velocidad'})
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE parametros SET valor_parametro = %s WHERE clave_parametro = 'VELOCIDAD'", (nuevo_valor,))
    conn.commit()
    cursor.close()
    conn.close()
    VELOCIDAD_GLOBAL = nuevo_valor / 255.0
    return jsonify({'success': True, 'velocidad': nuevo_valor})

@app.route('/api/enviar_movimiento', methods=['POST'])
def enviar_movimiento():
    data = request.get_json()
    nombre_movimiento = data.get('movimiento')
    identificador = data.get('identificador', 'ESP8266-CAR-001')
    
    id_movimiento = None
    for kid, nombre in MOVIMIENTOS_MAP.items():
        if nombre == nombre_movimiento:
            id_movimiento = kid
            break
    if not id_movimiento:
        return jsonify({'success': False, 'error': 'Movimiento no encontrado'})
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id_dispositivo FROM dispositivos WHERE identificador_unico = %s", (identificador,))
    dispositivo = cursor.fetchone()
    if not dispositivo:
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'error': 'Dispositivo no encontrado'})
    id_dispositivo = dispositivo[0]
    
    cursor.execute("INSERT INTO movimientos_registrados (id_dispositivo, id_movimiento) VALUES (%s, %s)", (id_dispositivo, id_movimiento))
    conn.commit()
    cursor.close()
    conn.close()
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT mia_pwm, mda_pwm, mi_time FROM config_motor_movimiento WHERE id_movimiento = %s", (id_movimiento,))
    config = cursor.fetchone()
    cursor.close()
    conn.close()
    
    if not config:
        return jsonify({'success': False, 'error': 'Configuración no encontrada'})
    
    # Calcular PWM respetando la velocidad global solo si NO es giro fijo
    if id_movimiento in MOVIMIENTOS_VELOCIDAD_FIJA:
        pwm_izq = int(config['mia_pwm'])
        pwm_der = int(config['mda_pwm'])
    else:
        pwm_izq = int(int(config['mia_pwm']) * VELOCIDAD_GLOBAL)
        pwm_der = int(int(config['mda_pwm']) * VELOCIDAD_GLOBAL)
    
    tiempo = TIEMPOS_ESPECIALES.get(id_movimiento, config['mi_time'] if config['mi_time'] > 0 else 2000)
    
    comando = {
        'movimiento': MOVIMIENTOS_MAP[id_movimiento],
        'mia_pwm': pwm_izq,
        'mda_pwm': pwm_der,
        'mi_time': tiempo
    }
    mensaje = json.dumps({'success': True, 'data': comando})
    print(f"📤 Enviando: {mensaje}")
    
    for client in websocket_clients[:]:
        try:
            client.send(encode_websocket_frame(mensaje))
        except:
            if client in websocket_clients:
                websocket_clients.remove(client)
    
    return jsonify({'success': True, 'message': f'Movimiento {nombre_movimiento} enviado'})

@app.route('/api/demos', methods=['GET'])
def get_demos():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT sd.id_secuencia, sd.nombre_secuencia, sd.descripcion, COUNT(dsd.id_detalle) as total_movimientos
        FROM secuencias_demo sd
        LEFT JOIN detalle_secuencia_demo dsd ON sd.id_secuencia = dsd.id_secuencia
        GROUP BY sd.id_secuencia, sd.nombre_secuencia, sd.descripcion
    """)
    demos = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify({'success': True, 'data': demos})

@app.route('/api/ejecutar_demo', methods=['POST'])
def ejecutar_demo():
    data = request.get_json()
    demo_id = data.get('demo_id')
    demo_nombre = data.get('demo_nombre')
    identificador = data.get('identificador', 'ESP8266-CAR-001')
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    if demo_id:
        cursor.execute("SELECT id_secuencia FROM secuencias_demo WHERE id_secuencia = %s", (demo_id,))
    else:
        cursor.execute("SELECT id_secuencia FROM secuencias_demo WHERE nombre_secuencia = %s", (demo_nombre,))
    demo = cursor.fetchone()
    if not demo:
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'error': 'Demo no encontrada'})
    id_secuencia = demo['id_secuencia']
    
    cursor.execute("SELECT id_movimiento, orden_ejecucion FROM detalle_secuencia_demo WHERE id_secuencia = %s ORDER BY orden_ejecucion", (id_secuencia,))
    movimientos_db = cursor.fetchall()
    cursor.close()
    conn.close()
    
    if not movimientos_db:
        return jsonify({'success': False, 'error': 'La demo no tiene movimientos'})
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id_dispositivo FROM dispositivos WHERE identificador_unico = %s", (identificador,))
    dispositivo = cursor.fetchone()
    cursor.close()
    conn.close()
    if not dispositivo:
        return jsonify({'success': False, 'error': 'Dispositivo no encontrado'})
    id_dispositivo = dispositivo[0]
    
    movimientos_preparados = []
    for mov in movimientos_db:
        id_mov = mov['id_movimiento']
        nombre = MOVIMIENTOS_MAP.get(id_mov, "Adelante")
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT mia_pwm, mda_pwm, mi_time FROM config_motor_movimiento WHERE id_movimiento = %s", (id_mov,))
        config = cursor.fetchone()
        cursor.close()
        conn.close()
        if not config:
            continue
        
        # Aplicar regla de velocidad fija para giros
        if id_mov in MOVIMIENTOS_VELOCIDAD_FIJA:
            pwm_izq = int(config['mia_pwm'])
            pwm_der = int(config['mda_pwm'])
        else:
            pwm_izq = int(int(config['mia_pwm']) * VELOCIDAD_GLOBAL)
            pwm_der = int(int(config['mda_pwm']) * VELOCIDAD_GLOBAL)
        
        tiempo = TIEMPOS_ESPECIALES.get(id_mov, config['mi_time'] if config['mi_time'] > 0 else 2000)
        movimientos_preparados.append({
            'nombre': nombre,
            'mia_pwm': pwm_izq,
            'mda_pwm': pwm_der,
            'mi_time': tiempo,
            'id_movimiento': id_mov
        })
    
    conn = get_db_connection()
    cursor = conn.cursor()
    for mov in movimientos_preparados:
        cursor.execute("INSERT INTO movimientos_registrados (id_dispositivo, id_movimiento) VALUES (%s, %s)", (id_dispositivo, mov['id_movimiento']))
    conn.commit()
    cursor.close()
    conn.close()
    
    def ejecutar_secuencia():
        for mov in movimientos_preparados:
            comando = {
                'movimiento': mov['nombre'],
                'mia_pwm': mov['mia_pwm'],
                'mda_pwm': mov['mda_pwm'],
                'mi_time': mov['mi_time']
            }
            mensaje = json.dumps({'success': True, 'data': comando})
            print(f"📤 Demo -> ESP: {mensaje}")
            for client in websocket_clients[:]:
                try:
                    client.send(encode_websocket_frame(mensaje))
                except:
                    if client in websocket_clients:
                        websocket_clients.remove(client)
            
            # Esperar a que el movimiento termine físicamente
            pausa = (mov['mi_time'] + 150) / 1000.0
            time.sleep(pausa)
            
            # INYECCIÓN CRÍTICA: Enviar 'Detener' explícitamente para cancelar la inercia infinita del ESP8266
            detener_cmd = {
                'movimiento': 'Detener',
                'mia_pwm': 0,
                'mda_pwm': 0,
                'mi_time': 0
            }
            msg_detener = json.dumps({'success': True, 'data': detener_cmd})
            for client in websocket_clients[:]:
                try:
                    client.send(encode_websocket_frame(msg_detener))
                except:
                    pass
            time.sleep(0.1) # Pequeña pausa de estabilización antes del siguiente movimiento
            
        print("✅ Demo completada")
    
    threading.Thread(target=ejecutar_secuencia, daemon=True).start()
    return jsonify({'success': True, 'message': f'Demo iniciada con {len(movimientos_preparados)} movimientos'})

# ========== WEBSOCKET (igual que antes) ==========
def encode_websocket_frame(message):
    message_bytes = message.encode('utf-8')
    length = len(message_bytes)
    frame = bytearray()
    frame.append(0x81)
    if length <= 125:
        frame.append(length)
    elif length <= 65535:
        frame.append(126)
        frame.extend(length.to_bytes(2, 'big'))
    else:
        frame.append(127)
        frame.extend(length.to_bytes(8, 'big'))
    frame.extend(message_bytes)
    return bytes(frame)

def handle_websocket(client_socket, address):
    global websocket_clients
    try:
        request = client_socket.recv(1024).decode('utf-8')
        key_pattern = r'Sec-WebSocket-Key: (.*)'
        key_match = re.search(key_pattern, request)
        if not key_match:
            client_socket.close()
            return
        key = key_match.group(1).strip()
        GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        combined = key + GUID
        sha1 = hashlib.sha1(combined.encode('utf-8'))
        accept = base64.b64encode(sha1.digest()).decode('utf-8')
        response = (
            "HTTP/1.1 101 Switching Protocols\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            f"Sec-WebSocket-Accept: {accept}\r\n\r\n"
        )
        client_socket.send(response.encode('utf-8'))
        websocket_clients.append(client_socket)
        print(f"🔌 ESP8266 conectado desde {address}")
        while True:
            data = client_socket.recv(4096)
            if not data:
                break
            if len(data) >= 2:
                opcode = data[0] & 0x0F
                if opcode == 0x8:  # Close frame
                    break
                elif opcode == 0x9:  # Ping frame, enviar Pong
                    try:
                        client_socket.send(bytes([0x8A, 0x00]))
                    except:
                        break
    except:
        pass
    finally:
        if client_socket in websocket_clients:
            websocket_clients.remove(client_socket)
        client_socket.close()
        print(f"🔌 ESP8266 desconectado")

def keep_alive():
    while True:
        time.sleep(5)
        for client in websocket_clients[:]:
            try:
                # Enviar PING frame para mantener viva la conexión TCP
                client.send(bytes([0x89, 0x00]))
            except:
                if client in websocket_clients:
                    websocket_clients.remove(client)

def start_websocket_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', 5000))
    server.listen(5)
    print("✅ Servidor WebSocket corriendo en ws://0.0.0.0:5000")
    
    # Iniciar hilo de mantenimiento de conexión (Ping)
    threading.Thread(target=keep_alive, daemon=True).start()
    
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_websocket, args=(client, addr), daemon=True).start()

if __name__ == '__main__':
    cargar_velocidad_global()
    print("╔════════════════════════════════════════╗")
    print("║   CARRITO IoT - VELOCIDAD FIJA GIROS   ║")
    print("╚════════════════════════════════════════╝")
    threading.Thread(target=start_websocket_server, daemon=True).start()
    print("✅ API HTTP corriendo en http://0.0.0.0:5001")
    app.run(host='0.0.0.0', port=5001, debug=False, use_reloader=False)