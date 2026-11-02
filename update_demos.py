import mysql.connector

DB_CONFIG = {
    'host': 'instancia-iot.cpcio88easmg.us-east-2.rds.amazonaws.com',
    'user': 'admin',
    'password': 'izy_BGCquTvR_x5',
    'database': 'carrito_iot',
    'port': 3306,
    'connect_timeout': 10
}

# 1: Adelante, 2: Atrás, 3: Detener, 4: Vuelta adelante derecha, 5: Vuelta adelante izquierda
# 6: Vuelta atrás derecha, 7: Vuelta atrás izquierda, 8: Giro 90° derecha, 9: Giro 90° izquierda
# 10: Giro 360° derecha, 11: Giro 360° izquierda

demos = {
    "Zig Zag": [1, 4, 5, 1, 5, 4, 1], # 7 movs
    "Cuadrado": [1, 4, 4, 1, 4, 4, 1, 4, 4, 1, 4, 4], # 12 movs
    "Estacionar": [1, 7, 2, 4], # Adelante, Vuelta atrás izq, Atrás, Vuelta adelante der
    "Giro en U": [5, 5, 5], # 3 veces Vuelta adelante izquierda
    "Baile": [10, 11, 2, 1, 8, 9, 7] # 7 movs
}

try:
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    for name, moves in demos.items():
        cursor.execute("SELECT id_secuencia FROM secuencias_demo WHERE nombre_secuencia LIKE %s LIMIT 1", (f"%{name}%",))
        res = cursor.fetchone()
        if res:
            id_seq = res[0]
            print(f"Actualizando '{name}' (ID: {id_seq})...")
            cursor.execute("DELETE FROM detalle_secuencia_demo WHERE id_secuencia = %s", (id_seq,))
            
            for i, mov in enumerate(moves):
                cursor.execute("INSERT INTO detalle_secuencia_demo (id_secuencia, id_movimiento, orden_ejecucion) VALUES (%s, %s, %s)", (id_seq, mov, i+1))
        else:
            print(f"No se encontró la demo '{name}', creándola...")
            cursor.execute("INSERT INTO secuencias_demo (nombre_secuencia, descripcion) VALUES (%s, %s)", (f"Demo {name}", f"Secuencia de {name}"))
            id_seq = cursor.lastrowid
            for i, mov in enumerate(moves):
                cursor.execute("INSERT INTO detalle_secuencia_demo (id_secuencia, id_movimiento, orden_ejecucion) VALUES (%s, %s, %s)", (id_seq, mov, i+1))

    conn.commit()
    cursor.close()
    conn.close()
    print("✅ Demos actualizadas exitosamente.")
except Exception as e:
    print(f"❌ Error: {e}")
