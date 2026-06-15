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


def actualizar_estado_pedido(id_pedido, nuevo_estado):
    conexion = oracledb.connect(
        user=ORACLE_USER,
        password=ORACLE_PASSWORD,
        dsn=ORACLE_DSN
    )

    cursor = conexion.cursor()

    try:
        cursor.execute("""
            UPDATE PEDIDO
            SET ESTADO = :estado
            WHERE ID_PEDIDO = :id_pedido
        """, {
            "estado": nuevo_estado,
            "id_pedido": id_pedido
        })

        conexion.commit()

    except Exception as e:
        conexion.rollback()
        raise e

    finally:
        cursor.close()
        conexion.close()


def recibir_pedido(ch, method, properties, body):
    try:
        mensaje = json.loads(body.decode("utf-8"))
        id_pedido = mensaje["id_pedido"]

        print("\nNuevo pedido recibido en cocina")
        print("--------------------------------")
        print(f"Pedido: {id_pedido}")
        print(f"Estado anterior: {mensaje['estado']}")
        print(f"Total: ${mensaje['total']}")

        print("\nProductos:")
        for producto in mensaje["productos"]:
            print(f"- {producto['cantidad']} x {producto['producto']}")

        actualizar_estado_pedido(id_pedido, "EN_PREPARACION")

        print("\nEstado actualizado en Oracle: EN_PREPARACION")
        print("--------------------------------")

        ch.basic_ack(delivery_tag=method.delivery_tag)

    except Exception as e:
        print("Error procesando pedido:")
        print(e)
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)


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

canal.basic_qos(prefetch_count=1)

canal.basic_consume(
    queue=QUEUE_NAME,
    on_message_callback=recibir_pedido
)

print("Cocina esperando pedidos...")
canal.start_consuming()