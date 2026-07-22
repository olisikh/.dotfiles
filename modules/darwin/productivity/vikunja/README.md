# Vikunja service operations

## Health and backups

```bash
curl -fsS https://olisikh-mini.bandicoot-scala.ts.net/api/v1/info
vikunja-backup
```

The database is a project-scoped Docker volume (`vikunja_vikunja-postgres`); attachment files and timestamped backups are in `~/Library/Application Support/Vikunja/`. The backup command refuses to dump until PostgreSQL reports ready.

## Initial root cutover

1. Apply the Nix configuration with Plane still running if Vikunja has not been tested yet.
2. Verify `http://127.0.0.1:3456/api/v1/info`, the Tailnet URL above, and a successful `vikunja-backup`.
3. Only after those checks pass, stop the Plane launchd labels and its scoped Compose project. Never use `-v`:

```bash
uid="$(id -u)"
for label in com.olisikh.plane-nix com.olisikh.plane-dispatcher-nix com.olisikh.plane-mcp-nix; do
  launchctl bootout "gui/$uid/$label" || true
done

docker compose --project-name plane \
  --env-file "$HOME/Library/Application Support/Plane/plane.env" \
  --file "$HOME/.dotfiles/modules/darwin/services/plane/compose/docker-compose.yaml" \
  --file "$HOME/.dotfiles/modules/darwin/services/plane/compose/compose.override.yaml" \
  down
```

## Restore Plane

1. In `systems/aarch64-darwin/olisikh-mini/default.nix`, set:

```nix
services.plane.productionActive = true;
network.tailscale.caddy.plane.enable = true;
network.tailscale.caddy.vikunja.enable = false;
```

2. Apply the exact whitelisted rebuild:

```bash
sudo -n /run/current-system/sw/bin/darwin-rebuild switch --flake ~/.dotfiles#olisikh-mini
```

3. Verify Plane health and its preserved volumes. Do not delete Vikunja data unless separately approved.
