# hdi website

Information page and interactive demo of the `hdi` CLI, built with [Astro](https://astro.build).

## Prerequisites

The website depends on demo data generated from the `hdi` CLI. Before running the dev server or building, make sure `hdi` is built from the project root:

```bash
./build
```

Data generation and asset copying happens automatically via `predev` and `prebuild` npm scripts, so you don't need to run `prepare-website.sh` manually.

## Local development

Install Node via [asdf](https://asdf-vm.com/) (see `.tool-versions`):

```bash
asdf install
```

Install dependencies:

```bash
npm install
```

Start the dev server:

```bash
npm run dev
```

Dev server will open at http://localhost:4321

## Formatting

This project uses Prettier for formatting.

Run manually:

```bash
npm run format
```

Run without writing:

```bash
npm run format:check
```

## E2E tests

This project uses Playwright for E2E tests. Tests run on Chromium, Firefox and Webkit.

Initial set up (installs browsers):

```bash
npx playwright install
```

Run in headless mode:

```bash
npm run test
```

Run with browser UI:

```bash
npm run test:ui
```

Run in debug mode:

```bash
npm run test:debug
```

## Preview and build

Preview your build locally, before deploying:

```bash
npm run preview
```

Build website:

```bash
npm run build
```

## Astro commands

Get help using the Astro CLI:

```bash
npm run astro -- --help
```

## Regenerating data

`src/data/data.js` and the demo GIFs in `src/assets/` are auto-generated and not committed to git. They are regenerated automatically when running `npm run dev` or `npm run build`. To regenerate manually, run from the `website/` directory:

```bash
./prepare-website.sh
```

## Deployment

Deployment to GitHub Pages is automatic on every release via the `pages.yml` GitHub Actions workflow. It can also be triggered manually by running the workflow from the [Actions tab in GitHub](https://github.com/grega/hdi/actions).
