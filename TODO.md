# TODO

## hdi CLI

- [ ] CONTRIBUTING.md / DEVELOPMENT.md support: Discover and parse additional doc files beyond README, possibly via `hdi contrib`
- [ ] Multi-select in picker: Mark multiple commands (eg. with space) then execute them in sequence with Enter
- [ ] Shell completions: `hdi completion zsh/bash/fish` outputting completion scripts for subcommands and flags
- [ ] `.hdi` override file: Let project maintainers drop an `.hdi` file with explicit commands, bypassing README parsing

## Adjacent tooling

- [ ] Real-world corpus testing: Script that fetches READMEs from popular GitHub repos and runs `hdi --ni all` against them to catch parsing edge cases
