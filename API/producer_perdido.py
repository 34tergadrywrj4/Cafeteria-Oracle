import json
import oracledb
import pika

# === CONFIGURACIÓN ORACLE ===
ORACLE_USER = "cafeteria"
ORACLE_PASSWORD = "cafeteria123"
ORACLE_DSN = "localhost:1521/XE"

# === CONFIGURACIÓN RABBITMQ ===
RABBIT_HOST = "localhost"
RABBIT_PORT = 5672
RABBIT_USER = "guest"
RABBIT_PASSWORD = "guest"
QUEUE_NAME = "pedidos"


def conectar_oracle():
    return oracledb.connect(
        user=ORACLE_USER,
        password=ORACLE_PASSWORD,
        dsn=ORACLE_DSN
    )


def enviar_a_rabbit(mensaje):
    credenciales = pika.PlainCredentials(RABBIT_USER, RABBIT_PASSWORD)

    conexion = pika.BlockingConnection(
        pika.ConnectionParameters(
            host=RABBIT_HOST,
            port=RABBIT_PORT,
            virtual_host="/",
            credentials=credenciales
        )
    )

    canal = conexion.channel()

    canal.queue_declare(
        queue=QUEUE_NAME,
        durable=True
    )

    canal.basic_publish(
        exchange="",
        routing_key=QUEUE_NAME,
        body=json.dumps(mensaje, ensure_ascii=False),
        properties=pika.BasicProperties(
            delivery_mode=2
        )
    )

    conexion.close()


def crear_pedido():
    conexion = conectar_oracle()
    cursor = conexion.cursor()

    try:
        # Nuevo ID de pedido
        cursor.execute("SELECT seq_pedido.NEXTVAL FROM dual")
        id_pedido = cursor.fetchone()[0]

        # Crear pedido en estado PENDIENTE
        cursor.execute("""
            INSERT INTO PEDIDO (ID_PEDIDO, ID_ALUMNO, ID_EMPLEADO, ESTADO)
            VALUES (:id_pedido, :id_alumno, :id_empleado, 'PENDIENTE')
        """, {
            "id_pedido": id_pedido,
            "id_alumno": 1,
            "id_empleado": 1
        })

        # Productos del pedido de prueba
        productos = [
            {"id_producto": 3, "cantidad": 1},  # Cafe
            {"id_producto": 4, "cantidad": 2}   # Taco de guisado
        ]

        productos_mensaje = []

        for item in productos:
            id_producto = item["id_producto"]
            cantidad = item["cantidad"]

            cursor.execute("""
                SELECT NOMBRE, PRECIO
                FROM PRODUCTO
                WHERE ID_PRODUCTO = :id_producto
            """, {
                "id_producto": id_producto
            })

            producto = cursor.fetchone()

            if producto is None:
                raise Exception(f"Producto con ID {id_producto} no existe")

            nombre = producto[0]
            precio = float(producto[1])
            subtotal = precio * cantidad

            cursor.execute("SELECT seq_detalle.NEXTVAL FROM dual")
            id_detalle = cursor.fetchone()[0]

            cursor.execute("""
                INSERT INTO DETALLE_PEDIDO
                (ID_DETALLE, ID_PEDIDO, ID_PRODUCTO, CANTIDAD, SUBTOTAL)
                VALUES (:id_detalle, :id_pedido, :id_producto, :cantidad, :subtotal)
            """, {
                "id_detalle": id_detalle,
                "id_pedido": id_pedido,
                "id_producto": id_producto,
                "cantidad": cantidad,
                "subtotal": subtotal
            })

            productos_mensaje.append({
                "producto": nombre,
                "cantidad": cantidad,
                "precio": precio,
                "subtotal": subtotal
            })

        # El trigger actualiza el total
        cursor.execute("""
            SELECT TOTAL
            FROM PEDIDO
            WHERE ID_PEDIDO = :id_pedido
        """, {
            "id_pedido": id_pedido
        })

        total = float(cursor.fetchone()[0])

        conexion.commit()

        mensaje = {
            "id_pedido": id_pedido,
            "estado": "PENDIENTE",
            "total": total,
            "productos": productos_mensaje
        }

        return mensaje

    except Exception as e:
        conexion.rollback()
        raise e

    finally:
        cursor.close()
        conexion.close()


if __name__ == "__main__":
    pedido = crear_pedido()
    enviar_a_rabbit(pedido)

    print("Pedido creado en Oracle y enviado a RabbitMQ:")
    print(json.dumps(pedido, indent=4, ensure_ascii=False))