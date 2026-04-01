# Contributing to express-api

## Development Setup

Fork the repo and install dependencies:

```bash
npm install
cp .env.example .env.test
```

## Running Tests

Run the full test suite with coverage:

```bash
npm run test:coverage
```

Run integration tests only:

```bash
npm run test:integration
```

## Code Style

We use ESLint and Prettier. Run the linter before submitting a PR:

```bash
npm run lint
npm run format
```

## Release Process

```bash
npm version patch
npm publish
```
