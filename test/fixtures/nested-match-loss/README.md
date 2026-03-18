# Project

## Set up

```bash
docker compose build
```

```bash
docker compose up -d
```

### Prepare schema

```bash
rails db:migrate
```

#### Prerequisites

- Install PostgreSQL
- Install Redis

#### Syncing from staging

```bash
./bin/sync-staging.sh
```

## Testing

```bash
bundle exec rspec
```
