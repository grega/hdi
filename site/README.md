# hdi demo site

Information page and demo of the `hdi` CLI.

## Local development

Serve the `site/` directory with any static HTTP server, eg:

```bash
npx http-server
```

Then open http://localhost:8080

## Prettier

This is set up to run on any `site/` staged files in a pre-commit hook, but can be run manually with:

```bash
npx prettier . --write
```

## Regenerating data

`data.js` is auto-generated from the fixture READMEs using `hdi --json`. To regenerate after changing fixtures or the parser locally, run:

```bash
generate-data.sh
```

## E2E tests

Install Node, eg. via [asdf](https://asdf-vm.com/) (see `.tool-versions`):

```bash
asdf install
```

Setup:

```bash
npm install
npx playwright install chromium
```

Run tests:

```bash
npm test
```

Run tests with browser visible:

```bash
npm run test:headed
```

Render test reports:

```bash
npx playwright show-report
```

## Deployment

Deploys to GitHub Pages automatically on release (tag push) via `.github/workflows/pages.yml`. The `release` script regenerates `data.js` before committing.
