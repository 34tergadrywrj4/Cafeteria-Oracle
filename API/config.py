import os

ORACLE_USER = os.getenv("ORACLE_USER", "C##CAFETERIA")
ORACLE_PASSWORD = os.getenv("ORACLE_PASSWORD", "cafeteria123")
ORACLE_DSN = os.getenv("ORACLE_DSN", "127.0.0.1:1521/XE")

RABBIT_HOST = os.getenv("RABBIT_HOST", "localhost")
RABBIT_PORT = int(os.getenv("RABBIT_PORT", "5672"))
RABBIT_USER = os.getenv("RABBIT_USER", "guest")
RABBIT_PASSWORD = os.getenv("RABBIT_PASSWORD", "guest")
RABBIT_VHOST = os.getenv("RABBIT_VHOST", "/")
QUEUE_NAME = os.getenv("QUEUE_NAME", "pedidos")
