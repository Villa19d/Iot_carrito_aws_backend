# model/movimiento.py
from model.database import Database
import json

class MovimientoModel:
    def __init__(self):
        self.db = Database()
    
    def get_ultimo_movimiento(self):
        """Obtener el último movimiento registrado"""
        result = self.db.call_procedure('sp_ultimo_movimiento', ())
        if result and len(result) > 0:
            return result[0]
        return None
    
    def get_ultimos_10_movimientos(self):
        """Obtener los últimos 10 movimientos"""
        result = self.db.call_procedure('sp_ultimos_10_movimientos', ())
        return result if result else []
    
    def agregar_movimiento(self, identificador_unico, nombre_movimiento):
        """Registrar un nuevo movimiento"""
        result = self.db.call_procedure(
            'sp_agregar_movimiento', 
            (identificador_unico, nombre_movimiento)
        )
        if result and len(result) > 0:
            return result[0]
        return {'id_registro': None}
    
    def actualizar_parametro(self, clave, valor):
        """Actualizar un parámetro de configuración"""
        result = self.db.call_procedure(
            'sp_actualizar_parametro',
            (clave, float(valor))
        )
        if result and len(result) > 0:
            return result[0]
        return None

    def get_ultimo_movimiento_esp(self):
        """Obtener último movimiento simplificado para ESP8266"""
        result = self.db.call_procedure('sp_ultimo_movimiento_esp', ())
        if result and len(result) > 0:
          return result[0]
        return None

    
    def get_ultimo_obstaculo(self):
        """Obtener el último obstáculo registrado"""
        result = self.db.call_procedure('sp_ultimo_obstaculo', ())
        if result and len(result) > 0:
            return result[0]
        return None
    
    def agregar_obstaculo(self, identificador_unico, nombre_estatus, distancia_cm):
        """Registrar un obstáculo"""
        result = self.db.call_procedure(
            'sp_agregar_obstaculo',
            (identificador_unico, nombre_estatus, distancia_cm)
        )
        if result and len(result) > 0:
            return result[0]
        return None