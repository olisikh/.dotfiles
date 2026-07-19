#!/usr/bin/env python3
"""Render Plane's Compose environment from SOPS-materialized runtime secrets."""
from __future__ import annotations

import os
from pathlib import Path

def required_path(name: str) -> Path:
    value = os.environ.get(name)
    if not value:
        raise SystemExit(f"required runtime environment variable is unavailable: {name}")
    return Path(value)


RUNTIME_DIR = required_path("PLANE_STATE_DIR")
OUTPUT = RUNTIME_DIR / "plane.env"
SECRETS = required_path("PLANE_SECRETS_DIR")
# Plane emits root-relative browser assets and only accepts scheme+host CORS
# origins, so it must own the Tailnet host root rather than a path prefix.
PUBLIC_BASE = os.environ.get("PLANE_PUBLIC_BASE", "https://olisikh-mini.bandicoot-scala.ts.net")
TAILNET_HOST = os.environ.get("PLANE_TAILNET_HOST", "olisikh-mini.bandicoot-scala.ts.net")


def secret(name: str) -> str:
    path = SECRETS / name
    try:
        value = path.read_text(encoding="utf-8").strip()
    except FileNotFoundError as exc:
        raise SystemExit(f"required SOPS runtime secret is unavailable: {path}") from exc
    if not value or "\n" in value:
        raise SystemExit(f"invalid SOPS runtime secret: {path}")
    return value


def main() -> None:
    RUNTIME_DIR.mkdir(mode=0o700, exist_ok=True)
    postgres_password = secret("postgres-password")
    rabbitmq_password = secret("rabbitmq-password")
    values = {
        "APP_DOMAIN": TAILNET_HOST,
        "APP_RELEASE": "v1.3.1",
        "DOCKERHUB_USER": "makeplane",
        "PULL_POLICY": "if_not_present",
        "CUSTOM_BUILD": "false",
        "LISTEN_HTTP_PORT": "28080",
        "LISTEN_HTTPS_PORT": "28443",
        "WEB_URL": PUBLIC_BASE,
        "CORS_ALLOWED_ORIGINS": PUBLIC_BASE,
        "API_BASE_URL": "http://api:8000",
        "PGHOST": "plane-db",
        "PGDATABASE": "plane",
        "POSTGRES_USER": "plane",
        "POSTGRES_PASSWORD": postgres_password,
        "POSTGRES_DB": "plane",
        "POSTGRES_PORT": "5432",
        "PGDATA": "/var/lib/postgresql/data",
        "DATABASE_URL": f"postgresql://plane:{postgres_password}@plane-db/plane",
        "REDIS_HOST": "plane-redis",
        "REDIS_PORT": "6379",
        "REDIS_URL": "redis://plane-redis:6379/",
        "RABBITMQ_HOST": "plane-mq",
        "RABBITMQ_PORT": "5672",
        "RABBITMQ_USER": "plane",
        "RABBITMQ_PASSWORD": rabbitmq_password,
        "RABBITMQ_VHOST": "plane",
        "AMQP_URL": f"amqp://plane:{rabbitmq_password}@plane-mq:5672/plane",
        "SITE_ADDRESS": ":80",
        "CERT_EMAIL": "",
        "CERT_ACME_CA": "https://acme-v02.api.letsencrypt.org/directory",
        "CERT_ACME_DNS": "",
        "SECRET_KEY": secret("secret-key"),
        "USE_MINIO": "1",
        "AWS_REGION": "",
        "AWS_ACCESS_KEY_ID": secret("minio-access-key"),
        "AWS_SECRET_ACCESS_KEY": secret("minio-secret-key"),
        "AWS_S3_ENDPOINT_URL": "http://plane-minio:9000",
        "AWS_S3_BUCKET_NAME": "uploads",
        "FILE_SIZE_LIMIT": "5242880",
        "MINIO_ENDPOINT_SSL": "0",
        "GUNICORN_WORKERS": "1",
        "API_KEY_RATE_LIMIT": "60/minute",
        "LIVE_SERVER_SECRET_KEY": secret("live-server-secret-key"),
        # Plane rejects private webhook destinations unless this explicit
        # tailnet hostname is allowlisted. The dispatcher independently
        # validates Plane's HMAC before forwarding work to Hermes.
        "WEBHOOK_ALLOWED_HOSTS": TAILNET_HOST,
        "WEBHOOK_ALLOWED_IPS": "",
        "PLANE_WEB_INDEX": str(RUNTIME_DIR / "plane-web-index.html"),
    }
    content = "".join(f"{key}={value}\n" for key, value in values.items())
    temporary = OUTPUT.with_suffix(".tmp")
    temporary.write_text(content, encoding="utf-8")
    os.chmod(temporary, 0o600)
    temporary.replace(OUTPUT)


if __name__ == "__main__":
    main()
