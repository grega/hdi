# hdi - "How Do I..."

"...run this thing".

Scan a project's README and extract the commands you (probably) need to get it running. No more opening up the whole project in your editor and scrolling through docs to find the `install` and `run` steps.

```
$ cd some-project
$ hdi
[hdi] some-project

 ▸ Installation
  ▶ npm install
    cp .env.example .env

 ▸ Run
    npm run dev

  ↑↓ navigate  ⏎ execute  a run all  q quit
```

Arrow keys to navigate, Enter to execute, `q` to quit.

## Example

For the README in the repository [gregannandale.com](https://github.com/grega/gregannandale.com):

![Screenshot showing the tool in action](https://github.com/user-attachments/assets/437aaf52-4bb4-4689-b781-21c25b1b74e6)


## Install

### Homebrew (macOS/Linux)

```bash
brew install gregannandale/tap/hdi
```

### Manual

```bash
curl -fsSL https://raw.githubusercontent.com/gregannandale/hdi/main/hdi -o ~/.local/bin/hdi
chmod +x ~/.local/bin/hdi
```

Make sure `~/.local/bin` is on your `$PATH`.

## Usage

```
hdi                    Interactive picker (default)
hdi install            Just install/setup commands
hdi run                Just run/start commands
hdi all                All sections (install + run + config + deploy + test)
hdi /path/to/project   Scan a different directory
```

Help:

```
hdi --help
```

### Flags

```
--full       Show surrounding prose, not just commands
--raw        Plain markdown output (for piping)
--ni         Non-interactive (just print, no picker)
```

### Interactive controls

| Key | Action |
|-----|--------|
| `↑` `↓` / `k` `j` | Navigate commands |
| `Enter` | Execute highlighted command |
| `a` | Run all commands sequentially |
| `q` / `Esc` | Quit |

## How it works

`hdi` parses a given README's Markdown headings looking for keywords like *install*, *setup*, *prerequisites*, *run*, *usage*, *getting started*, etc. It extracts the fenced code blocks from matching sections (skipping JSON/YAML response examples) and presents them as an interactive, executable list.

No dependencies, just Bash. Should work on macOS and Linux.

## Publishing a new release

1. Tag the release and push:

```bash
git tag v0.x.0
git push origin v0.x.0
```

2. Get the sha256 of the release tarball:

```bash
curl -sL https://github.com/gregannandale/hdi/archive/refs/tags/v0.x.0.tar.gz | shasum -a 256
```

3. Update the formula in the [homebrew-tap](https://github.com/gregannandale/homebrew-tap) repo (`Formula/hdi.rb`):
   - Set `url` to the new tag's tarball URL
   - Set `sha256` to the value from step 2

4. Push the tap repo. Users can now get the update via `brew upgrade hdi`.

## License

[MIT](LICENSE)
