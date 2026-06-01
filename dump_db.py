import mysql.connector
import os

conn = mysql.connector.connect(
    host='instancia-iot.cpcio88easmg.us-east-2.rds.amazonaws.com',
    user='admin',
    password='izy_BGCquTvR_x5',
    database='carrito_iot'
)
cursor = conn.cursor()

cursor.execute("SHOW TABLES")
tables = [row[0] for row in cursor.fetchall()]

sql_dump = "CREATE DATABASE IF NOT EXISTS carrito_iot;\nUSE carrito_iot;\n\n"

for table in tables:
    cursor.execute(f"SHOW CREATE TABLE {table}")
    create_stmt = cursor.fetchone()[1]
    sql_dump += f"-- Estructura de la tabla {table}\n"
    sql_dump += create_stmt + ";\n\n"

cursor.execute("SHOW PROCEDURE STATUS WHERE Db = 'carrito_iot'")
procedures = [row[1] for row in cursor.fetchall()]

for proc in procedures:
    cursor.execute(f"SHOW CREATE PROCEDURE {proc}")
    res = cursor.fetchone()
    create_stmt = res[2] if len(res) > 2 else ""
    if create_stmt:
        sql_dump += f"-- Stored Procedure: {proc}\n"
        sql_dump += "DELIMITER //\n"
        sql_dump += create_stmt + "\n"
        sql_dump += "//\nDELIMITER ;\n\n"

os.makedirs('SQL_Scripts', exist_ok=True)
with open('SQL_Scripts/esquema_bd_y_sp.sql', 'w', encoding='utf-8') as f:
    f.write(sql_dump)

print("SQL Script Generado en SQL_Scripts/esquema_bd_y_sp.sql")
