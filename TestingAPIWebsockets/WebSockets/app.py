# app.py
import sys
import os

# Agregar la ruta actual al path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Importar directamente el servidor WebSocket
from websocket.socket_server import WebSocketServer

if __name__ == '__main__':
    print("🚀 Iniciando servidor WebSocket para Carrito IoT")
    print("=" * 50)
    print("📡 Servidor de control para ESP8266")
    print("🔌 Conectando a base de datos...")
    print("=" * 50)
    
    server = WebSocketServer(host='0.0.0.0', port=5000)
    
    try:
        server.start()
    except KeyboardInterrupt:
        server.stop()
        print("\n👋 Servidor finalizado")