# websocket/socket_server.py
import socket
import threading
import json
import hashlib
import base64
import re
import sys
import os

# Agregar la ruta padre para poder importar los controladores
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from controller.movimiento_controller import MovimientoController

class WebSocketServer:
    def __init__(self, host='0.0.0.0', port=5000):
        self.host = host
        self.port = port
        self.server_socket = None
        self.clients = []
        self.controller = MovimientoController()
        self.running = True
        
    def start(self):
        """Iniciar servidor WebSocket"""
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(5)
        print(f"✅ Servidor WebSocket corriendo en ws://{self.host}:{self.port}")
        
        # Hilo para enviar actualizaciones periódicas
        update_thread = threading.Thread(target=self._send_periodic_updates)
        update_thread.daemon = True
        update_thread.start()
        
        while self.running:
            try:
                client_socket, address = self.server_socket.accept()
                print(f"📱 Cliente conectado desde {address}")
                
                # Manejar handshake WebSocket
                self._handshake(client_socket)
                
                # Hilo para manejar mensajes del cliente
                client_thread = threading.Thread(target=self._handle_client, args=(client_socket, address))
                client_thread.daemon = True
                client_thread.start()
                self.clients.append(client_socket)
            except Exception as e:
                print(f"❌ Error aceptando conexión: {e}")
    
    def _handshake(self, client_socket):
        """Realizar handshake WebSocket"""
        try:
            request = client_socket.recv(1024).decode('utf-8')
        except:
            return False
        
        # Extraer key del handshake
        key_pattern = r'Sec-WebSocket-Key: (.*)'
        key_match = re.search(key_pattern, request)
        
        if key_match:
            key = key_match.group(1).strip()
            accept = self._generate_accept_key(key)
            
            response = (
                "HTTP/1.1 101 Switching Protocols\r\n"
                "Upgrade: websocket\r\n"
                "Connection: Upgrade\r\n"
                f"Sec-WebSocket-Accept: {accept}\r\n\r\n"
            )
            client_socket.send(response.encode('utf-8'))
            return True
        return False
    
    def _generate_accept_key(self, key):
        """Generar clave de aceptación WebSocket"""
        GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        combined = key + GUID
        sha1 = hashlib.sha1(combined.encode('utf-8'))
        return base64.b64encode(sha1.digest()).decode('utf-8')
    
    def _decode_frame(self, data):
        """Decodificar frame WebSocket"""
        if len(data) < 2:
            return None
        
        opcode = data[0] & 0x0F
        if opcode == 0x08:  # Close frame
            return None
        
        masked = data[1] & 0x80
        payload_len = data[1] & 0x7F
        
        offset = 2
        if payload_len == 126:
            payload_len = int.from_bytes(data[offset:offset+2], 'big')
            offset += 2
        elif payload_len == 127:
            payload_len = int.from_bytes(data[offset:offset+8], 'big')
            offset += 8
        
        if masked:
            mask = data[offset:offset+4]
            offset += 4
            payload = bytearray(data[offset:offset+payload_len])
            for i in range(len(payload)):
                payload[i] ^= mask[i % 4]
            return payload.decode('utf-8')
        else:
            return data[offset:offset+payload_len].decode('utf-8')
    
    def _encode_frame(self, message):
        """Codificar frame WebSocket"""
        if isinstance(message, dict):
            message = json.dumps(message)
        
        message_bytes = message.encode('utf-8')
        length = len(message_bytes)
        
        frame = bytearray()
        frame.append(0x81)  # Text frame
        
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
    
    def _handle_client(self, client_socket, address):
        """Manejar mensajes de un cliente"""
        try:
            while self.running:
                data = client_socket.recv(4096)
                if not data:
                    break
                
                # Decodificar mensaje
                message = self._decode_frame(data)
                if message is None:
                    break
                
                print(f"📨 Mensaje de {address}: {message}")
                
                # Procesar mensaje
                response = self._process_message(message)
                
                # Enviar respuesta
                if response:
                    encoded = self._encode_frame(response)
                    client_socket.send(encoded)
        except Exception as e:
            print(f"❌ Error manejando cliente {address}: {e}")
        finally:
            if client_socket in self.clients:
                self.clients.remove(client_socket)
            client_socket.close()
            print(f"📱 Cliente {address} desconectado")
    
    def _process_message(self, message):
        """Procesar mensaje y retornar respuesta"""
        try:
            data = json.loads(message)
            action = data.get('action')
            
            if action == 'get_ultimo_movimiento':
                return self.controller.get_ultimo_movimiento()
            
            elif action == 'get_ultimos_10_movimientos':
                return self.controller.get_ultimos_10_movimientos()
            
            elif action == 'agregar_movimiento':
                identificador = data.get('identificador_unico', 'ESP8266-CAR-001')
                movimiento = data.get('nombre_movimiento')
                if movimiento:
                    return self.controller.agregar_movimiento(identificador, movimiento)
                return {'success': False, 'error': 'Falta nombre_movimiento'}
            
            elif action == 'actualizar_parametro':
                clave = data.get('clave')
                valor = data.get('valor')
                if clave and valor:
                    return self.controller.actualizar_parametro(clave, valor)
                return {'success': False, 'error': 'Faltan clave o valor'}
            
            elif action == 'get_ultimo_obstaculo':
                return self.controller.get_ultimo_obstaculo()
            
            elif action == 'agregar_obstaculo':
                identificador = data.get('identificador_unico', 'ESP8266-CAR-001')
                estatus = data.get('nombre_estatus')
                distancia = data.get('distancia_cm')
                if estatus:
                    return self.controller.agregar_obstaculo(identificador, estatus, distancia)
                return {'success': False, 'error': 'Falta nombre_estatus'}
            elif action == 'get_ultimo_movimiento_esp':
               return self.controller.get_ultimo_movimiento_esp()
            
            else:
                return {'success': False, 'error': f'Acción desconocida: {action}'}
        except json.JSONDecodeError:
            return {'success': False, 'error': 'Formato JSON inválido'}
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def _send_periodic_updates(self):
        """Enviar actualizaciones periódicas a todos los clientes"""
        import time
        last_movimiento_id = None
        
        while self.running:
            try:
                # Verificar si hay nuevos movimientos
                ultimo = self.controller.get_ultimo_movimiento()
                if ultimo and ultimo.get('success') and ultimo.get('data'):
                    current_id = ultimo['data'].get('id_registro')
                    
                    if current_id != last_movimiento_id:
                        last_movimiento_id = current_id
                        # Notificar a todos los clientes
                        message = self._encode_frame(json.dumps({
                            'type': 'nuevo_movimiento',
                            'data': ultimo['data']
                        }))
                        
                        for client in self.clients[:]:
                            try:
                                client.send(message)
                            except:
                                if client in self.clients:
                                    self.clients.remove(client)
            except Exception as e:
                print(f"❌ Error en actualización periódica: {e}")
            
            time.sleep(2)  # Revisar cada 2 segundos
    
    def stop(self):
        """Detener servidor"""
        self.running = False
        for client in self.clients:
            try:
                client.close()
            except:
                pass
        if self.server_socket:
            self.server_socket.close()
        print("🛑 Servidor detenido")


# Para ejecutar directamente
if __name__ == '__main__':
    server = WebSocketServer()
    try:
        server.start()
    except KeyboardInterrupt:
        server.stop()