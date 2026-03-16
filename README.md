# hdi - "How do I..."

"...run this thing".

Scan a project's README and extract the commands you (probably) need to get it running. No more opening up the whole project in your editor and scrolling through docs to find the `install`, `run` and `test` steps.

```
$ cd some-project
$ hdi
[hdi] some-project

 ▸ Installation
  ▶ npm install
    cp .env.example .env

 ▸ Run
    npm run dev

  ↑↓ navigate  ⏎ execute  c copy  a run all  q quit
```

Arrow keys to navigate, Enter to execute, `q` to quit.

## Example

![Animated demo showing the tool in action](./demo/demo.gif)

## Install

### Homebrew (macOS/Linux)

```bash
brew install grega/tap/hdi
```

### Manual

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/grega/hdi/main/hdi -o ~/.local/bin/hdi
chmod +x ~/.local/bin/hdi
```

Make sure `~/.local/bin` is on your `$PATH`.

## Usage

```
hdi                    Interactive picker (default)
hdi install            Just install/setup commands (aliases: setup, i)
hdi run                Just run/start commands (aliases: start, r)
hdi test               Just test commands (alias: t)
hdi all                All sections (aliases: a)
hdi /path/to/project   Scan a different directory
```

Short forms:

```
hdi i                  Install/setup commands
hdi r                  Run/start commands
hdi t                  Test commands
hdi a                  All sections
```

### Flags

```
-h, --help               Show help
-f, --full               Show surrounding prose, not just commands
    --raw                Plain markdown output (no colour, for piping)
    --ni, --no-interactive   Non-interactive (just print, no picker)
```

Example: `hdi --raw | pbcopy` to copy commands to clipboard.

### Interactive controls

| Key | Action |
|-----|--------|
| `↑` `↓` / `k` `j` | Navigate commands |
| `Enter` | Execute highlighted command |
| `c` | Copy highlighted command to clipboard |
| `a` | Run all commands sequentially |
| `q` / `Esc` | Quit |

## How it works

`hdi` parses a given README's Markdown headings looking for keywords like *install*, *setup*, *prerequisites*, *run*, *usage*, *getting started*, etc. It extracts the fenced code blocks from matching sections (skipping JSON/YAML response examples) and presents them as an interactive, executable list.

Also looks for `README.rst` / `readme.rst`, though Markdown READMEs work best.

No dependencies, just Bash. Should work on macOS and Linux.

## Testing

Tests use [bats-core](https://github.com/bats-core/bats-core).

```bash
brew install bats-core  # or: apt-get install bats
bats test/hdi.bats
```

## Demo

The demo GIF is generated with [VHS](https://github.com/charmbracelet/vhs). To regenerate it:

```bash
brew install vhs
vhs ./demo/demo.tape
```

This outputs `demo.gif` from the tape file.

## Publishing a new release

1. Tag the release and push:

```bash
git tag v0.x.0
git push origin v0.x.0
```

The `release` workflow will automatically build and publish a new release to GitHub when the tag is pushed.

2. Get the sha256 of the release tarball:

```bash
curl -sL https://github.com/grega/hdi/archive/refs/tags/v0.x.0.tar.gz | shasum -a 256
```

3. Update the formula in the [homebrew-tap](https://github.com/grega/homebrew-tap) repo (`Formula/hdi.rb`):
   - Set `url` to the new tag's tarball URL
   - Set `sha256` to the value from step 2

4. Push the tap repo. Users can now get the update via `brew upgrade hdi`.

## License

[MIT](LICENSE)
