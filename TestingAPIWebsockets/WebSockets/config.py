# config.py
#
# All values now come from environment variables (see .env.example at the
# repository root). No host, user or password is hard-coded anymore.
import os

class Config:
    # Database configuration (originally a MySQL instance on AWS RDS).
    DB_HOST = os.environ.get('DB_HOST', '')
    DB_USER = os.environ.get('DB_USER', '')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', '')
    DB_NAME = os.environ.get('DB_NAME', 'carrito_iot')
    DB_PORT = int(os.environ.get('DB_PORT', '3306'))

    # WebSocket server configuration.
    # 0.0.0.0 listens on every interface.
    WS_HOST = os.environ.get('WS_HOST', '0.0.0.0')
    WS_PORT = int(os.environ.get('WS_PORT', '5000'))

    # Public IP/host clients (and the ESP8266) should connect to.
    PUBLIC_IP = os.environ.get('PUBLIC_IP', '')

# Connection check (for debugging). Never prints the password.
if __name__ == '__main__':
    print("Configuración actual:")
    print(f"   DB Host: {Config.DB_HOST or '(not set)'}")
    print(f"   DB User: {Config.DB_USER or '(not set)'}")
    print(f"   DB Name: {Config.DB_NAME}")
    print(f"   DB Port: {Config.DB_PORT}")
    print(f"   WS Endpoint: ws://{Config.PUBLIC_IP or '(not set)'}:{Config.WS_PORT}")