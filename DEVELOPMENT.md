# Development

## Usage

Make changes to `src/` files, then run `./build` to regenerate `hdi`.

Run the `hdi` script directly to test changes before committing:

```bash
./hdi
```

Both changes in `src/`, and the resulting / built `hdi`, need to be committed. CI will fail if `hdi` is out of date with `src/`.

### Git hooks

A pre-commit hook is included that automatically rebuilds `hdi` when `src/` files are staged. To install it:

```bash
git config core.hooksPath .githooks
```

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core). Linting uses [ShellCheck](https://www.shellcheck.net/).

```bash
brew install bats-core shellcheck  # or: apt-get install bats shellcheck
shellcheck hdi
bats test/hdi.bats
```

### Running Linux tests locally with Act

This assumes that the host system is macOS.

CI runs tests on both macOS and Ubuntu. To run the Ubuntu job locally using [Act](https://github.com/nektos/act) (requires Docker / Docker Desktop):

```bash
brew install act
act -j test --matrix os:ubuntu-latest --container-architecture linux/amd64
```

## Demo

The demo GIFs are generated with [VHS](https://github.com/charmbracelet/vhs). To regenerate them:

```bash
brew install vhs
vhs ./demo/demo-latte.tape
vhs ./demo/demo-mocha.tape
```

Or:

```bash
vhs demo/demo-latte.tape & vhs demo/demo-mocha.tape & wait
```

These output GIFs in `./demo/`.

## Website

See `website/README.md` for instructions on running the demo website locally.

It is deployed to https://hdi.md via GitHub Pages on every release.

## Benchmarking

Static benchmark READMEs in `bench/` (small, medium, large, stress) exercise parsing path at different scales. Run benchmarks with:

```bash
./bench/run              # run benchmarks, print results
./bench/run --compare    # compare current results against last release
./bench/run --log        # also save to bench/results.csv (should only be used by release script / only run when creating a new release)
```

Benchmarks run automatically during `./release` and are recorded in `bench/results.csv`. A chart (`bench/results.svg`) is also generated to visualise performance across releases (via `bench/chart`).

## Publishing a new release

The `release` script bumps the version in `src/header.sh`, rebuilds `hdi`, commits, tags and pushes. The `release` Actions workflow will automatically build and publish a GitHub release when the tag is pushed, and the demo site is built and deployed via the `pages` workflow. The script then prints the `url` and `sha256` values to update in the [homebrew-tap](https://github.com/grega/homebrew-tap) repo (`Formula/hdi.rb`).

```bash
./release patch          # 0.1.0 → 0.1.1
./release minor          # 0.1.0 → 0.2.0
./release major          # 0.1.0 → 1.0.0
./release 1.2.3          # explicit version
```
