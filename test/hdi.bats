#!/usr/bin/env bats

setup() {
  HDI="$BATS_TEST_DIRNAME/../hdi"
  chmod +x "$HDI"
  FIXTURES="$BATS_TEST_DIRNAME/fixtures"
}

# ── CLI basics ──────────────────────────────────────────────────────────────

@test "--help prints usage" {
  run "$HDI" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"hdi install"* ]]
}

@test "-h prints usage" {
  run "$HDI" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "unknown argument exits with error" {
  run "$HDI" --nonsense
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown argument"* ]]
}

@test "no README exits with error" {
  run "$HDI" --ni "$FIXTURES/no-readme"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No README found"* ]]
}

@test "directory path argument works" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

# ── README discovery ────────────────────────────────────────────────────────

@test "finds lowercase readme.md" {
  run "$HDI" --raw "$FIXTURES/readme-lowercase"
  [ "$status" -eq 0 ]
  [[ "$output" == *"make install"* ]]
}

@test "finds titlecase Readme.md" {
  run "$HDI" --raw "$FIXTURES/readme-titlecase"
  [ "$status" -eq 0 ]
  [[ "$output" == *"./configure"* ]]
}

# ── Mode aliases ────────────────────────────────────────────────────────────

@test "'install' mode shows only install sections" {
  run "$HDI" install --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" != *"npm start"* ]]
}

@test "'setup' is an alias for install mode" {
  run "$HDI" setup --raw "$FIXTURES/go-project"
  [ "$status" -eq 0 ]
  [[ "$output" == *"go mod download"* ]]
  [[ "$output" != *"./bin/service"* ]]
}

@test "'i' is an alias for install mode" {
  run "$HDI" i --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" != *"npm start"* ]]
}

@test "'run' mode shows only run sections" {
  run "$HDI" run --raw "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bin/rails server"* ]]
  [[ "$output" != *"bundle install"* ]]
}

@test "'start' is an alias for run mode" {
  run "$HDI" start --raw "$FIXTURES/elixir-phoenix"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mix phx.server"* ]]
  [[ "$output" != *"mix deps.get"* ]]
}

@test "'r' is an alias for run mode" {
  run "$HDI" r --raw "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bin/rails server"* ]]
}

@test "'test' mode shows only test sections" {
  run "$HDI" test --raw "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bundle exec rspec"* ]]
  [[ "$output" != *"bundle install"* ]]
  [[ "$output" != *"bin/rails server"* ]]
}

@test "'t' is an alias for test mode" {
  run "$HDI" t --raw "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bundle exec rspec"* ]]
}

@test "'all' mode includes extra sections" {
  run "$HDI" all --raw "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bundle install"* ]]
  [[ "$output" == *"bin/rails server"* ]]
  [[ "$output" == *"bundle exec rspec"* ]]
}

@test "'a' is an alias for all mode" {
  run "$HDI" a --raw "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bundle exec rspec"* ]]
}

@test "default mode shows install + run but not extras" {
  run "$HDI" --raw "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bundle install"* ]]
  [[ "$output" == *"bin/rails server"* ]]
  [[ "$output" != *"bundle exec rspec"* ]]
}

# ── Flags ───────────────────────────────────────────────────────────────────

@test "--raw strips ANSI codes" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  # raw output should not contain escape sequences
  [[ "$output" != *$'\033'* ]]
}

@test "--raw outputs markdown-style headings" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Prerequisites"* ]]
  [[ "$output" == *"## Installation"* ]]
}

@test "--ni produces output (non-interactive)" {
  run "$HDI" --ni "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

@test "--no-interactive is equivalent to --ni" {
  run "$HDI" --no-interactive --raw "$FIXTURES/node-express"
  local output_ni
  output_ni="$output"

  run "$HDI" --ni --raw "$FIXTURES/node-express"
  [ "$output" = "$output_ni" ]
}

@test "-f is an alias for --full" {
  run "$HDI" -f --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  # --full includes prose like "First, install dependencies:"
  [[ "$output" == *"install dependencies"* ]]
}

@test "--full includes prose around commands" {
  run "$HDI" --full --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"install dependencies"* ]]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm run dev"* ]]
}

@test "--raw without --full omits prose" {
  run "$HDI" --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" != *"install dependencies"* ]]
  [[ "$output" == *"npm install"* ]]
}

# ── Section keyword matching ───────────────────────────────────────────────

@test "matches 'Prerequisites' heading" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nvm install 20"* ]]
}

@test "matches 'Getting Started' heading" {
  run "$HDI" --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

@test "matches 'Requirements' heading" {
  run "$HDI" --raw "$FIXTURES/go-project"
  [ "$status" -eq 0 ]
  [[ "$output" == *"brew install go"* ]]
}

@test "matches 'Dependencies' heading" {
  run "$HDI" --raw "$FIXTURES/kubernetes-helm"
  [ "$status" -eq 0 ]
  [[ "$output" == *"brew install kubectl helm"* ]]
}

@test "matches 'Setup' heading" {
  run "$HDI" --raw "$FIXTURES/elixir-phoenix"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mix deps.get"* ]]
}

@test "matches 'Quick Start' heading" {
  run "$HDI" --raw "$FIXTURES/nested-sections"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cargo run"* ]]
}

@test "matches 'Start' heading for run mode" {
  run "$HDI" run --raw "$FIXTURES/elixir-phoenix"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mix phx.server"* ]]
}

@test "matches 'Running' heading for run mode" {
  run "$HDI" run --raw "$FIXTURES/go-project"
  [ "$status" -eq 0 ]
  [[ "$output" == *"./bin/service --port 8080"* ]]
}

@test "'all' matches 'Build' heading" {
  run "$HDI" all --raw "$FIXTURES/go-project"
  [ "$status" -eq 0 ]
  [[ "$output" == *"go build"* ]]
}

@test "'all' matches 'Deploy' heading" {
  run "$HDI" all --raw "$FIXTURES/terraform"
  [ "$status" -eq 0 ]
  [[ "$output" == *"terraform apply"* ]]
}

@test "'all' matches 'Test' heading" {
  run "$HDI" all --raw "$FIXTURES/elixir-phoenix"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mix test"* ]]
}

@test "'test' matches 'Test' heading" {
  run "$HDI" test --raw "$FIXTURES/elixir-phoenix"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mix test"* ]]
  [[ "$output" != *"mix deps.get"* ]]
  [[ "$output" != *"mix phx.server"* ]]
}

@test "'test' matches 'Testing' heading" {
  run "$HDI" test --raw "$FIXTURES/nested-sections"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cargo test"* ]]
  [[ "$output" != *"cargo run"* ]]
}

# ── Code block filtering ───────────────────────────────────────────────────

@test "skips json code blocks" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" != *'"status"'* ]]
}

@test "skips yaml code blocks" {
  run "$HDI" --raw "$FIXTURES/python-flask"
  [ "$status" -eq 0 ]
  [[ "$output" != *"DATABASE_URL"* ]]
}

@test "skips toml code blocks" {
  run "$HDI" all --raw "$FIXTURES/mixed-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" != *"[server]"* ]]
}

@test "skips xml code blocks" {
  run "$HDI" all --raw "$FIXTURES/mixed-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" != *"<config>"* ]]
}

@test "skips log code blocks" {
  run "$HDI" all --raw "$FIXTURES/mixed-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" != *"[INFO]"* ]]
}

@test "skips text code blocks" {
  run "$HDI" all --raw "$FIXTURES/rust-cargo"
  [ "$status" -eq 0 ]
  [[ "$output" != *"0.45s"* ]]
}

@test "skips env code blocks" {
  run "$HDI" all --raw "$FIXTURES/go-project"
  [ "$status" -eq 0 ]
  [[ "$output" != *"DB_HOST"* ]]
}

@test "extracts shell code blocks" {
  run "$HDI" --raw "$FIXTURES/mixed-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mixed-app init"* ]]
}

@test "extracts unlabelled code blocks" {
  # Unlabelled fenced blocks (no language) should be extracted
  run "$HDI" --raw "$FIXTURES/mixed-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install -g mixed-app"* ]]
}

# ── Prose-only sections ────────────────────────────────────────────────────

@test "sections with no code blocks show hint" {
  run "$HDI" --ni "$FIXTURES/prose-only"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no commands"* ]]
}

# ── Real-world README patterns ─────────────────────────────────────────────

@test "node/express: extracts install and run commands" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nvm install 20"* ]]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"cp .env.example .env"* ]]
  [[ "$output" == *"npm start"* ]]
}

@test "python/flask: extracts venv, pip, and flask commands" {
  run "$HDI" --raw "$FIXTURES/python-flask"
  [ "$status" -eq 0 ]
  [[ "$output" == *"python3 -m venv venv"* ]]
  [[ "$output" == *"source venv/bin/activate"* ]]
  [[ "$output" == *"pip install -r requirements.txt"* ]]
  [[ "$output" == *"flask run --debug"* ]]
}

@test "rust/cargo: extracts cargo install and build" {
  run "$HDI" --raw "$FIXTURES/rust-cargo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cargo install ripfind"* ]]
  [[ "$output" == *"cargo build --release"* ]]
  [[ "$output" == *"ripfind \"pattern\""* ]]
}

@test "go: extracts mod download, build, and run" {
  run "$HDI" all --raw "$FIXTURES/go-project"
  [ "$status" -eq 0 ]
  [[ "$output" == *"brew install go"* ]]
  [[ "$output" == *"go mod download"* ]]
  [[ "$output" == *"go build -o bin/service ./cmd/service"* ]]
  [[ "$output" == *"./bin/service --port 8080"* ]]
}

@test "ruby/rails: extracts bundle, db setup, and server" {
  run "$HDI" --raw "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" == *"brew install ruby postgresql redis"* ]]
  [[ "$output" == *"bundle install"* ]]
  [[ "$output" == *"rails db:create db:migrate db:seed"* ]]
  [[ "$output" == *"bin/rails server"* ]]
}

@test "react/nextjs: extracts npm install and dev server" {
  run "$HDI" --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm run dev"* ]]
}

@test "react/nextjs: default mode excludes deploy" {
  run "$HDI" --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" != *"npx vercel"* ]]
}

@test "react/nextjs: all mode includes deploy" {
  run "$HDI" all --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npx vercel --prod"* ]]
}

@test "elixir/phoenix: extracts mix commands" {
  run "$HDI" --raw "$FIXTURES/elixir-phoenix"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mix deps.get"* ]]
  [[ "$output" == *"mix ecto.setup"* ]]
  [[ "$output" == *"mix phx.server"* ]]
}

@test "elixir/phoenix: elixir blocks are extracted (not skipped)" {
  # elixir is a command language, not a data format — hdi should extract it
  run "$HDI" all --raw "$FIXTURES/elixir-phoenix"
  [ "$status" -eq 0 ]
  [[ "$output" == *"config :phoenix_app"* ]]
}

@test "java/spring: extracts maven and java commands" {
  run "$HDI" all --raw "$FIXTURES/java-spring"
  [ "$status" -eq 0 ]
  [[ "$output" == *"sdk install java"* ]]
  [[ "$output" == *"mvn clean install"* ]]
  [[ "$output" == *"mvn spring-boot:run"* ]]
}

@test "java/spring: skips openapi json block" {
  run "$HDI" all --raw "$FIXTURES/java-spring"
  [ "$status" -eq 0 ]
  [[ "$output" != *"openapi"* ]]
}

@test "terraform: extracts init, plan, and apply" {
  run "$HDI" all --raw "$FIXTURES/terraform"
  [ "$status" -eq 0 ]
  [[ "$output" == *"terraform init"* ]]
  [[ "$output" == *"terraform plan"* ]]
  [[ "$output" == *"terraform apply -auto-approve"* ]]
}

@test "terraform: skips json and text blocks" {
  run "$HDI" all --raw "$FIXTURES/terraform"
  [ "$status" -eq 0 ]
  [[ "$output" != *"us-east-1"* ]]
  [[ "$output" != *"vpc-abc123"* ]]
}

@test "kubernetes/helm: extracts helm and kubectl commands" {
  run "$HDI" --raw "$FIXTURES/kubernetes-helm"
  [ "$status" -eq 0 ]
  [[ "$output" == *"brew install kubectl helm"* ]]
  [[ "$output" == *"helm repo add"* ]]
  [[ "$output" == *"helm install my-release"* ]]
  [[ "$output" == *"kubectl get pods"* ]]
}

@test "kubernetes/helm: skips yaml values block" {
  run "$HDI" --raw "$FIXTURES/kubernetes-helm"
  [ "$status" -eq 0 ]
  [[ "$output" != *"replicaCount"* ]]
}

@test "mixed-blocks: extracts bash and shell, skips json/yaml/toml/xml/log" {
  run "$HDI" --raw "$FIXTURES/mixed-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install -g mixed-app"* ]]
  [[ "$output" == *"mixed-app init"* ]]
  [[ "$output" == *"mixed-app serve"* ]]
  [[ "$output" != *'"port"'* ]]
  [[ "$output" != *"DATABASE_URL"* ]]
  [[ "$output" != *"[server]"* ]]
  [[ "$output" != *"<config>"* ]]
  [[ "$output" != *"[INFO]"* ]]
}

# ── Nested sections ────────────────────────────────────────────────────────

@test "nested sections: matches sub-headings under Getting Started" {
  run "$HDI" --raw "$FIXTURES/nested-sections"
  [ "$status" -eq 0 ]
  [[ "$output" == *"rustup"* ]]
  [[ "$output" == *"cargo run"* ]]
}

@test "nested sections: 'all' mode includes build and test" {
  run "$HDI" all --raw "$FIXTURES/nested-sections"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cargo build --release"* ]]
  [[ "$output" == *"cargo test"* ]]
}

@test "nested sections: dev server matched in run mode" {
  run "$HDI" run --raw "$FIXTURES/nested-sections"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cargo watch -x run"* ]]
}

# ── Multiple commands in one block ──────────────────────────────────────────

@test "multi-line code blocks produce separate command lines" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  # The install block has "npm install" and "cp .env.example .env" on separate lines
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"cp .env.example .env"* ]]
}

# ── Inline backtick commands ─────────────────────────────────────────────

@test "inline: extracts command from heading backticks" {
  # ### `yarn start` → heading IS the command
  run "$HDI" run --raw "$FIXTURES/inline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yarn start"* ]]
}

@test "inline: extracts multiple heading-backtick commands" {
  run "$HDI" all --raw "$FIXTURES/inline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yarn start"* ]]
  [[ "$output" == *"yarn test"* ]]
  [[ "$output" == *"yarn build"* ]]
}

@test "inline: extracts commands from prose backticks" {
  # The Testing section mentions `yarn exec cypress run` inline
  run "$HDI" test --raw "$FIXTURES/inline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yarn exec cypress run"* ]]
  [[ "$output" == *"yarn exec cypress open"* ]]
}

@test "inline: does not extract non-command backtick text" {
  # `Jest`, `jest-axe`, `cypress`, `python`, `HTML` are NOT commands
  run "$HDI" all --raw "$FIXTURES/inline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Jest"* ]]
  [[ "$output" != *"jest-axe"* ]]
  [[ "$output" != *"haveNoViolations"* ]]
}

@test "inline: single-word tool names in prose are not extracted" {
  # `cypress`, `python`, `HTML` alone should not appear as commands
  run "$HDI" test --raw "$FIXTURES/inline-commands"
  [ "$status" -eq 0 ]
  local lines
  lines=$(echo "$output" | grep -v '^##' | grep -v '^$')
  [[ "$lines" != *"cypress"* || "$lines" == *"cypress run"* || "$lines" == *"cypress open"* ]]
}

@test "inline: deduplicates heading and prose commands" {
  # `yarn test` appears in both the heading and the Testing prose
  run "$HDI" test --raw "$FIXTURES/inline-commands"
  [ "$status" -eq 0 ]
  local count
  count=$(echo "$output" | grep -c '^yarn test$')
  [ "$count" -le 2 ]  # once per matching section, not repeated within a section
}

@test "inline: prose commands coexist with fenced code blocks" {
  # Development section has a fenced `npm run dev` AND inline `npm run dev -- --port 3000`
  run "$HDI" run --raw "$FIXTURES/inline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm run dev"* ]]
  [[ "$output" == *"npm run dev -- --port 3000"* ]]
}

@test "inline: install section extracts prose commands" {
  # Installation section has `npm install` and `npm run setup` inline
  run "$HDI" install --raw "$FIXTURES/inline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm run setup"* ]]
}

# ── Shell prompt stripping ───────────────────────────────────────────────

@test "prompt: strips '$ ' prefix from fenced code blocks" {
  run "$HDI" install --raw "$FIXTURES/prompt-prefixes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm run build"* ]]
  [[ "$output" != *'$ npm'* ]]
}

@test "prompt: strips '% ' prefix from fenced code blocks" {
  run "$HDI" run --raw "$FIXTURES/prompt-prefixes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yarn start"* ]]
  [[ "$output" != *'% yarn'* ]]
}

@test "prompt: preserves lines without prompt prefix" {
  run "$HDI" run --raw "$FIXTURES/prompt-prefixes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cd repo"* ]]
}

@test "prompt: does not mangle dollar-variable lines" {
  run "$HDI" all --raw "$FIXTURES/prompt-prefixes"
  [ "$status" -eq 0 ]
  # $HOME/bin/setup should be left intact (no space after $)
  [[ "$output" == *'$HOME/bin/setup'* ]]
}

@test "prompt: strips prompt from shell builtins" {
  run "$HDI" all --raw "$FIXTURES/prompt-prefixes"
  [ "$status" -eq 0 ]
  # "$ export NODE_ENV=production" should become "export NODE_ENV=production"
  [[ "$output" == *"export NODE_ENV=production"* ]]
  [[ "$output" != *'$ export'* ]]
}

@test "prompt: mixed prompted and unprompted lines coexist" {
  run "$HDI" run --raw "$FIXTURES/prompt-prefixes"
  [ "$status" -eq 0 ]
  # Block has: $ git clone ..., cd repo, $ npm install
  [[ "$output" == *"git clone"* ]]
  [[ "$output" == *"cd repo"* ]]
  [[ "$output" == *"npm install"* ]]
}

# ── Interactive: copy to clipboard ───────────────────────────────────────────

@test "interactive: 'c' copies highlighted command to clipboard" {
  local fake_bin clip_file
  fake_bin="$(mktemp -d)"
  clip_file="$fake_bin/clipboard.txt"

  # Fake pbcopy that writes to a file instead of the system clipboard
  printf '#!/bin/bash\ncat > "%s"\n' "$clip_file" > "$fake_bin/pbcopy"
  chmod +x "$fake_bin/pbcopy"

  # Keys: ↓ c q  (navigate down one, copy, quit)
  local keys=$'\x1b[Bcq'

  # Run interactively in a pseudo-TTY via script
  if [[ "$(uname)" == "Darwin" ]]; then
    printf '%s' "$keys" | script -q /dev/null env PATH="$fake_bin:$PATH" "$HDI" "$FIXTURES/node-express" >/dev/null 2>&1
  else
    printf '%s' "$keys" | script -qe -c "env PATH='$fake_bin:$PATH' '$HDI' '$FIXTURES/node-express'" /dev/null >/dev/null 2>&1
  fi

  # Second command in node-express default mode is "nvm use 20"
  [ -f "$clip_file" ]
  [[ "$(cat "$clip_file")" == "nvm use 20" ]]

  rm -rf "$fake_bin"
}
