# Local containers

Run Docker Compose from the repository root using `docker-compose.yml`, which includes `compose.yml` in this directory. Docker Compose 2.20+ is required for include support.

`docker compose up -d` starts Redis and MinIO. `docker compose --profile database up -d` additionally starts the optional development PostgreSQL instance. The optional instance needs port 5432 to be free and uses its own named data volume; it does not replace or configure an existing local PostgreSQL installation.

Local PostgreSQL credentials belong in the ignored root `.env`. The Compose database uses separate sample credentials. Production images, credentials, networking, and backup configuration belong to a future deployment milestone.
