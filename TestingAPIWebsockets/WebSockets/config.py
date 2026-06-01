# config.py
import os

class Config:
    # Configuración de base de datos (AWS Educate)
    DB_HOST = os.environ.get('DB_HOST', 'instancia-iot.cpcio88easmg.us-east-2.rds.amazonaws.com')
    DB_USER = os.environ.get('DB_USER', 'admin')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', 'izy_BGCquTvR_x5')
    DB_NAME = os.environ.get('DB_NAME', 'carrito_iot')
    DB_PORT = 3306
    
    # Configuración del servidor WebSocket
    # La IP 0.0.0.0 escucha en todas las interfaces (incluyendo la IP pública 50.16.92.186)
    WS_HOST = '0.0.0.0'
    WS_PORT = 5000
    
    # IP pública del servidor (para que el ESP8266 se conecte)
    PUBLIC_IP = '50.16.92.186'

# Prueba de conexión (para depuración)
if __name__ == '__main__':
    print(f"🔧 Configuración actual:")
    print(f"   DB Host: {Config.DB_HOST}")
    print(f"   DB User: {Config.DB_USER}")
    print(f"   DB Name: {Config.DB_NAME}")
    print(f"   DB Port: {Config.DB_PORT}")
    print(f"   WS Endpoint: ws://{Config.PUBLIC_IP}:{Config.WS_PORT}")