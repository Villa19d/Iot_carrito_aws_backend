# controllers/movimiento_controller.py
from model.movimiento import MovimientoModel
import json

class MovimientoController:
    def __init__(self):
        self.model = MovimientoModel()
    
    def get_ultimo_movimiento(self):
        """Controlador para obtener último movimiento"""
        movimiento = self.model.get_ultimo_movimiento()
        if movimiento:
            return {
                'success': True,
                'data': {
                    'id_registro': movimiento.get('id_registro'),
                    'movimiento': movimiento.get('movimiento'),
                    'mia_estado': movimiento.get('mia_estado'),
                    'mia_pwm': movimiento.get('mia_pwm'),
                    'mi_time': movimiento.get('mi_time'),
                    'mda_estado': movimiento.get('mda_estado'),
                    'mda_pwm': movimiento.get('mda_pwm'),
                    'md_time': movimiento.get('md_time'),
                    'fecha_hora': str(movimiento.get('fecha_hora')),
                    'nombre_dispositivo': movimiento.get('nombre_dispositivo'),
                    'identificador_unico': movimiento.get('identificador_unico'),
                    'ip_address': movimiento.get('ip_address'),
                    'pais': movimiento.get('pais'),
                    'ciudad': movimiento.get('ciudad')
                }
            }
        return {
            'success': False,
            'data': None,
            'error': 'No hay movimientos registrados'
        }
    
    def get_ultimos_10_movimientos(self):
        """Controlador para obtener últimos 10 movimientos"""
        movimientos = self.model.get_ultimos_10_movimientos()
        return {
            'success': True,
            'data': [
                {
                    'movimiento': m.get('movimiento'),
                    'fecha_hora': str(m.get('fecha_hora'))
                }
                for m in movimientos
            ]
        }
    
    def agregar_movimiento(self, identificador_unico, nombre_movimiento):
        """Controlador para agregar movimiento"""
        resultado = self.model.agregar_movimiento(identificador_unico, nombre_movimiento)
        return {
            'success': True,
            'message': 'Movimiento registrado correctamente',
            'id_registro': resultado.get('id_registro')
        }
    
    def actualizar_parametro(self, clave, valor):
        """Controlador para actualizar parámetro"""
        resultado = self.model.actualizar_parametro(clave, valor)
        if resultado:
            return {
                'success': True,
                'message': f'Parámetro {clave} actualizado a {valor}',
                'data': resultado
            }
        return {
            'success': False,
            'error': 'Error al actualizar parámetro'
        }
    
    def get_ultimo_obstaculo(self):
        """Controlador para obtener último obstáculo"""
        obstaculo = self.model.get_ultimo_obstaculo()
        if obstaculo:
            return {
                'success': True,
                'data': {
                    'nombre_estatus': obstaculo.get('nombre_estatus'),
                    'distancia_cm': obstaculo.get('distancia_cm'),
                    'fecha_hora': str(obstaculo.get('fecha_hora'))
                }
            }
        return {
            'success': False,
            'data': None,
            'error': 'No hay obstáculos registrados'
        }
    
    def agregar_obstaculo(self, identificador_unico, nombre_estatus, distancia_cm):
        """Controlador para agregar obstáculo"""
        resultado = self.model.agregar_obstaculo(identificador_unico, nombre_estatus, distancia_cm)
        return {
            'success': True,
            'message': 'Obstáculo registrado correctamente',
            'id_obstaculo': resultado.get('id_obstaculo')
        }


    def get_ultimo_movimiento_esp(self):
      movimiento = self.model.get_ultimo_movimiento_esp()
      if movimiento:
        return {
            'success': True,
            'data': {
                'movimiento': movimiento.get('movimiento'),
                'mia_pwm': int(movimiento.get('mia_pwm', 0)),
                'mda_pwm': int(movimiento.get('mda_pwm', 0)),
                'mi_time': int(movimiento.get('mi_time', 0))
            }
        }
      return {'success': False, 'data': None}