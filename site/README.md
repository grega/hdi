# hdi demo site

Interactive demo of the `hdi` CLI.

## Local development

Serve the `site/` directory with any static HTTP server, eg:

```bash
npx http-server
```

Then open http://localhost:8080

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
