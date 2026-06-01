# db_query.py
import mysql.connector

conn = mysql.connector.connect(
    host='instancia-iot.cpcio88easmg.us-east-2.rds.amazonaws.com',
    user='admin',
    password='izy_BGCquTvR_x5',
    database='carrito_iot'
)

cursor = conn.cursor()
cursor.execute("SELECT * FROM cat_movimientos")
for row in cursor.fetchall():
    print(row)

cursor.close()
conn.close()