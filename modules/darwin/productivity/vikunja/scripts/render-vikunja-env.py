from __future__ import annotations

import os
import tempfile
from collections.abc import Mapping
from pathlib import Path


class ConfigurationError(RuntimeError):
    pass


REQUIRED = (
    "VIKUNJA_STATE_DIR",
    "VIKUNJA_SECRETS_DIR",
    "VIKUNJA_PORT",
    "VIKUNJA_SERVICE_PUBLICURL",
    "VIKUNJA_IMAGE_TAG",
    "POSTGRES_IMAGE_TAG",
)


def require(environment: Mapping[str, str], name: str) -> str:
    value = environment.get(name, "").strip()
    if not value:
        raise ConfigurationError(f"{name} is required")
    return value


def read_secret(path: Path) -> str:
    try:
        value = path.read_text(encoding="utf-8").rstrip("\r\n")
    except OSError as exc:
        raise ConfigurationError(f"required secret is unavailable: {path}") from exc
    if not value or "\n" in value or "\r" in value:
        raise ConfigurationError(f"secret must be a nonempty single line: {path}")
    return value


def private_directory(path: Path) -> None:
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    path.chmod(0o700)


def render_env(environment: Mapping[str, str] | None = None) -> Path:
    environment = os.environ if environment is None else environment
    values = {name: require(environment, name) for name in REQUIRED}
    state_dir = Path(values["VIKUNJA_STATE_DIR"])
    secrets_dir = Path(values["VIKUNJA_SECRETS_DIR"])

    for directory in (state_dir, state_dir / "data" / "files", state_dir / "backups", state_dir / "logs"):
        private_directory(directory)

    values["VIKUNJA_DATABASE_PASSWORD"] = read_secret(secrets_dir / "database-password")
    values["VIKUNJA_SERVICE_SECRET"] = read_secret(secrets_dir / "service-secret")

    ordered = (
        "VIKUNJA_STATE_DIR",
        "VIKUNJA_PORT",
        "VIKUNJA_SERVICE_PUBLICURL",
        "VIKUNJA_IMAGE_TAG",
        "POSTGRES_IMAGE_TAG",
        "VIKUNJA_DATABASE_PASSWORD",
        "VIKUNJA_SERVICE_SECRET",
    )
    output = state_dir / "vikunja.env"
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=state_dir, prefix=".vikunja.env.", delete=False) as temporary:
        temporary.write("".join(f"{name}={values[name]}\n" for name in ordered))
        temporary.flush()
        os.fchmod(temporary.fileno(), 0o600)
        temporary_name = temporary.name
    os.replace(temporary_name, output)
    output.chmod(0o600)
    return output


if __name__ == "__main__":
    try:
        print(render_env())
    except ConfigurationError as exc:
        print(str(exc), file=os.sys.stderr)
        raise SystemExit(78) from exc
