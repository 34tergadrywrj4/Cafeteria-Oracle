import json
import pika
from .config import RABBIT_HOST, RABBIT_PORT, RABBIT_USER, RABBIT_PASSWORD, RABBIT_VHOST, QUEUE_NAME

def get_connection():
    credentials = pika.PlainCredentials(RABBIT_USER, RABBIT_PASSWORD)
    params = pika.ConnectionParameters(host=RABBIT_HOST, port=RABBIT_PORT, virtual_host=RABBIT_VHOST, credentials=credentials)
    return pika.BlockingConnection(params)

def publish_pedido(mensaje: dict):
    connection = get_connection()
    channel = connection.channel()
    try:
        channel.queue_declare(queue=QUEUE_NAME, durable=True)
        channel.basic_publish(
            exchange="",
            routing_key=QUEUE_NAME,
            body=json.dumps(mensaje, ensure_ascii=False),
            properties=pika.BasicProperties(delivery_mode=2, content_type="application/json")
        )
    finally:
        connection.close()
