import mysql.connector

DB_CONFIG = {
    'host': 'instancia-iot.cpcio88easmg.us-east-2.rds.amazonaws.com',
    'user': 'admin',
    'password': 'izy_BGCquTvR_x5',
    'database': 'carrito_iot',
    'port': 3306,
    'connect_timeout': 10
}

try:
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    # Obtener todas las secuencias
    cursor.execute("SELECT id_secuencia, nombre_secuencia FROM secuencias_demo ORDER BY id_secuencia")
    demos = cursor.fetchall()
    
    counter = 1
    for demo in demos:
        id_seq = demo[0]
        name = demo[1].lower()
        
        # Ignorar las demos internas de testing que no se muestran
        if 'final' in name or 'testing' in name:
            continue
            
        new_name = f"Demo {counter}"
        cursor.execute("UPDATE secuencias_demo SET nombre_secuencia = %s WHERE id_secuencia = %s", (new_name, id_seq))
        counter += 1
        
    conn.commit()
    cursor.close()
    conn.close()
    print("Demos renombradas a Demo 1, Demo 2, etc. exitosamente.")
except Exception as e:
    print(f"Error: {e}")
