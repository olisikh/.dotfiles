# Vikunja service operations

## Health and backups

```bash
curl -fsS https://olisikh-mini.bandicoot-scala.ts.net/api/v1/info
vikunja-backup
```

The database is a project-scoped Docker volume (`vikunja_vikunja-postgres`); attachment files and timestamped backups are in `~/Library/Application Support/Vikunja/`. The backup command refuses to dump until PostgreSQL reports ready.

## Tailnet root verification

Verify local and Tailnet access after a rebuild:

```bash
curl -fsS http://127.0.0.1:3456/api/v1/info
curl -fsS https://olisikh-mini.bandicoot-scala.ts.net/api/v1/info
vikunja-backup
```

Do not delete Vikunja data or backups unless separately approved.
