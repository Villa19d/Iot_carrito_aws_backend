# model/database.py
import mysql.connector
from mysql.connector import Error
import threading
from config import Config

class Database:
    _instance = None
    _lock = threading.Lock()
    
    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._initialize()
        return cls._instance
    
    def _initialize(self):
        self.connection = None
        self._connect()
    
    def _connect(self):
        try:
            print(f"🔄 Conectando a {Config.DB_HOST}:{Config.DB_PORT}...")
            self.connection = mysql.connector.connect(
                host=Config.DB_HOST,
                user=Config.DB_USER,
                password=Config.DB_PASSWORD,
                database=Config.DB_NAME,
                port=Config.DB_PORT,
                autocommit=True
            )
            print("✅ Conexión a base de datos establecida")
        except Error as e:
            print(f"❌ Error conectando a BD: {e}")
            self.connection = None
    
    def get_cursor(self):
        if self.connection is None or not self.connection.is_connected():
            self._connect()
            if self.connection is None:
                return None
        return self.connection.cursor(dictionary=True)
    
    def execute_query(self, query, params=None):
        cursor = self.get_cursor()
        if cursor is None:
            print("❌ No hay conexión a BD")
            return None
        try:
            cursor.execute(query, params)
            result = cursor.fetchall()
            return result
        except Error as e:
            print(f"❌ Error en consulta: {e}")
            return None
        finally:
            cursor.close()
    
    def call_procedure(self, proc_name, args=()):
        """
        Llama a un stored procedure en MySQL.
        Args debe ser una tupla o lista de argumentos.
        Para procedimientos sin argumentos, pasar () o None
        """
        cursor = self.get_cursor()
        if cursor is None:
            print(f"❌ No hay conexión a BD para llamar {proc_name}")
            return None
        try:
            # Asegurar que args sea una secuencia
            if args is None:
                args = ()
            elif not isinstance(args, (tuple, list)):
                args = (args,)
            
            print(f"📞 Llamando SP: {proc_name} con args={args}")
            cursor.callproc(proc_name, args)
            
            # Recuperar resultados
            result = []
            for result_set in cursor.stored_results():
                rows = result_set.fetchall()
                if rows:
                    result.extend(rows)
            return result
        except Error as e:
            print(f"❌ Error llamando SP {proc_name}: {e}")
            return None
        finally:
            cursor.close()