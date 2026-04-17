# long-command

## Setup

```bash
npm install
```

## Deploy

```bash
dokku config:set myapp  API_KEY=sk_live_abcdef1234567890  DATABASE_URL=postgres://user:password@host.example.com:5432/database  REDIS_URL=redis://cache.internal.example.com:6379/0  LOG_LEVEL=info  FEATURE_FLAG_ONE=true
```
