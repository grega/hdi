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
  [[ "$output" == *"unknown argument"* ]]
}

@test "no README exits with error" {
  run "$HDI" --ni "$FIXTURES/no-readme"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no README found"* ]]
}

@test "directory path argument works" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

@test "direct .md file path argument works" {
  run "$HDI" --raw "$FIXTURES/node-express/README.md"
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

@test "'deploy' mode shows only deploy sections" {
  run "$HDI" deploy --raw "$FIXTURES/deploy-pipeline"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kubectl apply"* ]]
  [[ "$output" == *"helm upgrade"* ]]
  [[ "$output" == *"release.sh"* ]]
  [[ "$output" != *"npm install"* ]]
  [[ "$output" != *"npm start"* ]]
  [[ "$output" != *"npm test"* ]]
}

@test "'d' is an alias for deploy mode" {
  run "$HDI" d --raw "$FIXTURES/deploy-pipeline"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kubectl apply"* ]]
}

@test "'deploy' matches CI/CD heading" {
  run "$HDI" deploy --raw "$FIXTURES/deploy-pipeline"
  [ "$status" -eq 0 ]
  [[ "$output" == *"act -j deploy"* ]]
}

@test "'deploy' matches Publishing heading" {
  run "$HDI" deploy --raw "$FIXTURES/deploy-pipeline"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm publish"* ]]
}

@test "'deploy' matches Rollout heading" {
  run "$HDI" deploy --raw "$FIXTURES/deploy-pipeline"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kubectl rollout"* ]]
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

@test "default mode shows install + run + test + deploy" {
  run "$HDI" --raw "$FIXTURES/deploy-pipeline"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm start"* ]]
  [[ "$output" == *"npm test"* ]]
  [[ "$output" == *"kubectl apply"* ]]
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
  [[ "$output" == *"npm run dev"* ]]
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

@test "react/nextjs: default mode includes deploy" {
  run "$HDI" --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npx vercel --prod"* ]]
}

@test "react/nextjs: all mode includes deploy" {
  run "$HDI" all --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npx vercel --prod"* ]]
}

@test "react/nextjs: deploy mode shows deploy section" {
  run "$HDI" deploy --raw "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npx vercel --prod"* ]]
}

@test "terraform: deploy mode shows deploy section" {
  run "$HDI" deploy --raw "$FIXTURES/terraform"
  [ "$status" -eq 0 ]
  [[ "$output" == *"terraform apply"* ]]
  [[ "$output" != *"terraform init"* ]]
}

@test "elixir/phoenix: extracts mix commands" {
  run "$HDI" --raw "$FIXTURES/elixir-phoenix"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mix deps.get"* ]]
  [[ "$output" == *"mix ecto.setup"* ]]
  [[ "$output" == *"mix phx.server"* ]]
}

@test "elixir/phoenix: elixir blocks are extracted (not skipped)" {
  # elixir is a command language, not a data format - hdi should extract it
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

# ── Table commands ───────────────────────────────────────────────────────────

@test "table: extracts backtick commands from table rows" {
  run "$HDI" --raw "$FIXTURES/table-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm i"* ]]
  [[ "$output" == *"npm run dev"* ]]
  [[ "$output" == *"npm run build"* ]]
}

@test "table: 'Commands' heading matches run mode" {
  run "$HDI" run --raw "$FIXTURES/table-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm run dev"* ]]
}

@test "table: does not extract non-command text from table cells" {
  run "$HDI" --raw "$FIXTURES/table-commands"
  [ "$status" -eq 0 ]
  [[ "$output" != *"localhost"* ]]
  [[ "$output" != *"Installs dependencies"* ]]
}

# ── Interactive: copy to clipboard ───────────────────────────────────────────

@test "interactive: 'c' copies highlighted command to clipboard" {
  command -v python3 >/dev/null 2>&1 || skip "python3 required for PTY tests"

  local fake_bin clip_file
  fake_bin="$(mktemp -d)"
  clip_file="$fake_bin/clipboard.txt"

  # Fake pbcopy that writes to a file instead of the system clipboard
  printf '#!/bin/bash\ncat > "%s"\n' "$clip_file" > "$fake_bin/pbcopy"
  chmod +x "$fake_bin/pbcopy"

  # Keys: ↓ c q  (navigate down one, copy, quit)
  local keys=$'\x1b[Bcq'

  # Run interactively in a pseudo-TTY.
  # We use pty.fork() rather than pty.spawn() because spawn's _copy loop
  # crashes on Linux (EIO when slave closes) in older Python versions.
  python3 -c "
import pty, os, sys, time, select, errno

os.environ['PATH'] = sys.argv[1] + ':' + os.environ['PATH']
keys = sys.argv[2].encode()

pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[3], sys.argv[3:])
else:
    # Wait for hdi to draw picker and enter raw mode
    time.sleep(0.5)
    os.write(fd, keys)
    # Wait for hdi to process keystrokes and exit
    time.sleep(0.5)
    # Drain any remaining output
    try:
        while select.select([fd], [], [], 0.5)[0]:
            if not os.read(fd, 4096):
                break
    except OSError:
        pass
    os.waitpid(pid, 0)
" "$fake_bin" "$keys" "$HDI" "$FIXTURES/node-express" >/dev/null 2>&1 || true

  # Second command in node-express default mode is "nvm use 20"
  [ -f "$clip_file" ]
  [[ "$(cat "$clip_file")" == "nvm use 20" ]]

  rm -rf "$fake_bin"
}

@test "interactive: Tab jumps to next section's first command" {
  command -v python3 >/dev/null 2>&1 || skip "python3 required for PTY tests"

  local fake_bin clip_file
  fake_bin="$(mktemp -d)"
  clip_file="$fake_bin/clipboard.txt"

  printf '#!/bin/bash\ncat > "%s"\n' "$clip_file" > "$fake_bin/pbcopy"
  chmod +x "$fake_bin/pbcopy"

  # Keys: Tab Tab c q  (jump 2 sections forward, copy, quit)
  # Sections: Prerequisites → Installation → Development
  # First cmds: nvm install 20 → npm install → npm run dev
  local keys=$'\t\tcq'

  python3 -c "
import pty, os, sys, time, select

os.environ['PATH'] = sys.argv[1] + ':' + os.environ['PATH']
keys = sys.argv[2].encode()

pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[3], sys.argv[3:])
else:
    time.sleep(0.5)
    os.write(fd, keys)
    time.sleep(0.5)
    try:
        while select.select([fd], [], [], 0.5)[0]:
            if not os.read(fd, 4096):
                break
    except OSError:
        pass
    os.waitpid(pid, 0)
" "$fake_bin" "$keys" "$HDI" "$FIXTURES/node-express" >/dev/null 2>&1 || true

  [ -f "$clip_file" ]
  [[ "$(cat "$clip_file")" == "npm run dev" ]]

  rm -rf "$fake_bin"
}

@test "interactive: Shift+Tab jumps to previous section's first command" {
  command -v python3 >/dev/null 2>&1 || skip "python3 required for PTY tests"

  local fake_bin clip_file
  fake_bin="$(mktemp -d)"
  clip_file="$fake_bin/clipboard.txt"

  printf '#!/bin/bash\ncat > "%s"\n' "$clip_file" > "$fake_bin/pbcopy"
  chmod +x "$fake_bin/pbcopy"

  # Keys: Tab Tab Tab Shift-Tab c q
  # Jump: Prerequisites → Installation → Development → Testing → back to Development
  local keys=$'\t\t\t\x1b[Zcq'

  python3 -c "
import pty, os, sys, time, select

os.environ['PATH'] = sys.argv[1] + ':' + os.environ['PATH']
keys = sys.argv[2].encode()

pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[3], sys.argv[3:])
else:
    time.sleep(0.5)
    os.write(fd, keys)
    time.sleep(0.5)
    try:
        while select.select([fd], [], [], 0.5)[0]:
            if not os.read(fd, 4096):
                break
    except OSError:
        pass
    os.waitpid(pid, 0)
" "$fake_bin" "$keys" "$HDI" "$FIXTURES/node-express" >/dev/null 2>&1 || true

  [ -f "$clip_file" ]
  [[ "$(cat "$clip_file")" == "npm run dev" ]]

  rm -rf "$fake_bin"
}

@test "interactive: Ctrl-C quits the picker cleanly" {
  command -v python3 >/dev/null 2>&1 || skip "python3 required for PTY tests"

  # Keys: Ctrl-C (\x03)
  local keys=$'\x03'

  python3 -c "
import pty, os, sys, time, select, threading

keys = sys.argv[1].encode()

pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[2], sys.argv[2:])
else:
    # Drain PTY output continuously in a background thread to prevent
    # the child from blocking on a full PTY buffer (especially on macOS)
    def drain():
        try:
            while True:
                if not select.select([fd], [], [], 5.0)[0]:
                    break
                if not os.read(fd, 4096):
                    break
        except OSError:
            pass
    t = threading.Thread(target=drain, daemon=True)
    t.start()

    time.sleep(0.5)
    os.write(fd, keys)

    _, status = os.waitpid(pid, 0)
    sys.exit(os.waitstatus_to_exitcode(status))
" "$keys" "$HDI" "$FIXTURES/node-express"
}

@test "interactive: 'f' jumps to next file's first command" {
  command -v python3 >/dev/null 2>&1 || skip "python3 required for PTY tests"

  local fake_bin clip_file
  fake_bin="$(mktemp -d)"
  clip_file="$fake_bin/clipboard.txt"

  printf '#!/bin/bash\ncat > "%s"\n' "$clip_file" > "$fake_bin/pbcopy"
  chmod +x "$fake_bin/pbcopy"

  # Keys: f (jump to CONTRIBUTING.md first cmd) ↓ (next cmd) c (copy) q (quit)
  # First cmd in CONTRIBUTING.md is "npm install", second is "cp .env.example .env.test"
  local keys='f'$'\x1b[B''cq'

  python3 -c "
import pty, os, sys, time, select

os.environ['PATH'] = sys.argv[1] + ':' + os.environ['PATH']
keys = sys.argv[2].encode()

pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[3], sys.argv[3:])
else:
    time.sleep(0.5)
    os.write(fd, keys)
    time.sleep(0.5)
    try:
        while select.select([fd], [], [], 0.5)[0]:
            if not os.read(fd, 4096):
                break
    except OSError:
        pass
    os.waitpid(pid, 0)
" "$fake_bin" "$keys" "$HDI" "$FIXTURES/node-express" >/dev/null 2>&1 || true

  [ -f "$clip_file" ]
  # "cp .env.example .env.test" is unique to CONTRIBUTING.md
  [[ "$(cat "$clip_file")" == "cp .env.example .env.test" ]]

  rm -rf "$fake_bin"
}

@test "interactive: 'f' wraps back to top after last file" {
  command -v python3 >/dev/null 2>&1 || skip "python3 required for PTY tests"

  local fake_bin clip_file
  fake_bin="$(mktemp -d)"
  clip_file="$fake_bin/clipboard.txt"

  printf '#!/bin/bash\ncat > "%s"\n' "$clip_file" > "$fake_bin/pbcopy"
  chmod +x "$fake_bin/pbcopy"

  # Keys: f (jump to CONTRIBUTING.md) f (wrap to top) c (copy) q (quit)
  # After wrapping, cursor should be on the first command: "nvm install 20"
  local keys='ffcq'

  python3 -c "
import pty, os, sys, time, select

os.environ['PATH'] = sys.argv[1] + ':' + os.environ['PATH']
keys = sys.argv[2].encode()

pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[3], sys.argv[3:])
else:
    time.sleep(0.5)
    os.write(fd, keys)
    time.sleep(0.5)
    try:
        while select.select([fd], [], [], 0.5)[0]:
            if not os.read(fd, 4096):
                break
    except OSError:
        pass
    os.waitpid(pid, 0)
" "$fake_bin" "$keys" "$HDI" "$FIXTURES/node-express" >/dev/null 2>&1 || true

  [ -f "$clip_file" ]
  [[ "$(cat "$clip_file")" == "nvm install 20" ]]

  rm -rf "$fake_bin"
}

@test "interactive: footer shows 'f files' only with multiple files" {
  # With contrib file — footer should include "f files"
  _HDI_BENCH_PICKER=1 run "$HDI" "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"f files"* ]]

  # Without contrib file — footer should not include "f files"
  _HDI_BENCH_PICKER=1 run "$HDI" "$FIXTURES/python-flask"
  [ "$status" -eq 0 ]
  [[ "$output" != *"f files"* ]]
}

# ── Tilde fences ────────────────────────────────────────────────────────────

@test "tilde fences: extracts commands from ~~~ blocks" {
  run "$HDI" install --raw --ni "$FIXTURES/tilde-fences"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pip install tilde-app"* ]]
}

@test "tilde fences: extracts unlabelled ~~~ blocks" {
  run "$HDI" run --raw --ni "$FIXTURES/tilde-fences"
  [ "$status" -eq 0 ]
  [[ "$output" == *"tilde-app run --port 8080"* ]]
}

@test "tilde fences: backtick blocks still work alongside tilde" {
  run "$HDI" all --raw --ni "$FIXTURES/tilde-fences"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pip install tilde-app"* ]]
  [[ "$output" == *"tilde-app run --port 8080"* ]]
  [[ "$output" == *"tilde-app build"* ]]
}

@test "tilde fences: skips tilde blocks with data languages" {
  run "$HDI" all --raw --ni "$FIXTURES/tilde-fences"
  [ "$status" -eq 0 ]
  [[ "$output" != *'"key"'* ]]
}

# ── Trailing hashes ────────────────────────────────────────────────────────

@test "trailing hashes: matches headings with trailing #" {
  run "$HDI" install --raw --ni "$FIXTURES/trailing-hashes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"make install"* ]]
}

@test "trailing hashes: section title does not include trailing #" {
  run "$HDI" install --raw --ni "$FIXTURES/trailing-hashes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installation"* ]]
  [[ "$output" != *"Installation ##"* ]]
}

# ── Keyword dot escaping ───────────────────────────────────────────────────

@test "keyword dots: does not match arbitrary characters in keyword gaps" {
  run "$HDI" install --raw --ni "$FIXTURES/keyword-dots"
  [ "$status" -eq 0 ]
  [[ "$output" != *"bad-match-command"* ]]
}

@test "keyword dots: matches 'Set Up' with space separator" {
  run "$HDI" install --raw --ni "$FIXTURES/keyword-dots"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

@test "keyword dots: matches 'Set-Up' with hyphen separator" {
  run "$HDI" install --raw --ni "$FIXTURES/keyword-dots"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yarn install"* ]]
}

# ── Formatted headings ─────────────────────────────────────────────────────

@test "formatted headings: matches bold-wrapped heading" {
  run "$HDI" install --raw --ni "$FIXTURES/formatted-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

@test "formatted headings: matches italic-wrapped heading" {
  run "$HDI" run --raw --ni "$FIXTURES/formatted-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm start"* ]]
}

@test "formatted headings: section title is clean" {
  run "$HDI" install --raw --ni "$FIXTURES/formatted-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installation"* ]]
  [[ "$output" != *"**Installation**"* ]]
}

# ── Multi-line commands ────────────────────────────────────────────────────

@test "multiline: joins backslash-continued docker build" {
  run "$HDI" install --raw --ni "$FIXTURES/multiline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docker build"* ]]
  [[ "$output" == *"-t myapp:latest"* ]]
  # Should be a single joined line, not separate fragments
  [[ "$output" != *$'\n'"  -t myapp"* ]]
}

@test "multiline: joins backslash-continued docker run" {
  run "$HDI" run --raw --ni "$FIXTURES/multiline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docker run"*"--name myapp"*"-p 8080:80"*"myapp:latest"* ]]
}

@test "multiline: single-line commands unaffected" {
  run "$HDI" run --raw --ni "$FIXTURES/multiline-commands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docker ps"* ]]
}

# ── Console blocks ─────────────────────────────────────────────────────────

@test "console blocks: extracts prompted commands" {
  run "$HDI" install --raw --ni "$FIXTURES/console-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install -g cli-tool"* ]]
  [[ "$output" == *"cli-tool init"* ]]
}

@test "console blocks: skips output lines" {
  run "$HDI" install --raw --ni "$FIXTURES/console-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" != *"npm added 42"* ]]
  [[ "$output" != *"Initialized new project"* ]]
}

@test "console blocks: coexists with regular bash blocks" {
  run "$HDI" run --raw --ni "$FIXTURES/console-blocks"
  [ "$status" -eq 0 ]
  [[ "$output" == *"cli-tool build"* ]]
  [[ "$output" == *"cli-tool serve"* ]]
  [[ "$output" != *"Building..."* ]]
}

# ── Expanded CMD_PREFIXES ──────────────────────────────────────────────────

@test "expanded prefixes: extracts mix commands from backticks" {
  run "$HDI" install --raw --ni "$FIXTURES/expanded-prefixes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mix deps.get"* ]]
}

@test "expanded prefixes: extracts composer commands from backticks" {
  run "$HDI" install --raw --ni "$FIXTURES/expanded-prefixes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"composer install"* ]]
}

@test "expanded prefixes: extracts flutter commands from backticks" {
  run "$HDI" install --raw --ni "$FIXTURES/expanded-prefixes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"flutter pub get"* ]]
}

@test "expanded prefixes: extracts just and conda from backticks" {
  run "$HDI" run --raw --ni "$FIXTURES/expanded-prefixes"
  [ "$status" -eq 0 ]
  [[ "$output" == *"just serve"* ]]
  [[ "$output" == *"conda activate myenv"* ]]
}

# ── Expanded SKIP_LANGS ───────────────────────────────────────────────────

@test "expanded skips: skips graphql blocks" {
  run "$HDI" install --raw --ni "$FIXTURES/expanded-skips"
  [ "$status" -eq 0 ]
  [[ "$output" != *"type Query"* ]]
}

@test "expanded skips: skips diff blocks" {
  run "$HDI" install --raw --ni "$FIXTURES/expanded-skips"
  [ "$status" -eq 0 ]
  [[ "$output" != *"old line"* ]]
}

@test "expanded skips: skips mermaid and hcl blocks" {
  run "$HDI" install --raw --ni "$FIXTURES/expanded-skips"
  [ "$status" -eq 0 ]
  [[ "$output" != *"graph TD"* ]]
  [[ "$output" != *"variable"* ]]
}

@test "expanded skips: still extracts bash blocks alongside skipped ones" {
  run "$HDI" install --raw --ni "$FIXTURES/expanded-skips"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm run setup"* ]]
}

# ── Setext headings ───────────────────────────────────────────────────────

@test "setext headings: matches underlined headings" {
  run "$HDI" install --raw --ni "$FIXTURES/setext-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm start"* ]]
}

@test "setext headings: test mode works with setext" {
  run "$HDI" test --raw --ni "$FIXTURES/setext-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm test"* ]]
}

@test "setext headings: all mode includes build section" {
  run "$HDI" all --raw --ni "$FIXTURES/setext-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm run build"* ]]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm test"* ]]
}

@test "setext headings: section title appears in output" {
  run "$HDI" install --raw --ni "$FIXTURES/setext-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Getting Started"* ]]
}

# ── Indented code blocks ──────────────────────────────────────────────────

@test "indented code: extracts 4-space indented commands" {
  run "$HDI" install --raw --ni "$FIXTURES/indented-code"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pip install old-project"* ]]
  [[ "$output" == *"pip install -r requirements.txt"* ]]
}

@test "indented code: does not extract indented prose" {
  run "$HDI" run --raw --ni "$FIXTURES/indented-code"
  [ "$status" -eq 0 ]
  [[ "$output" == *"python manage.py runserver"* ]]
  [[ "$output" != *"just a note"* ]]
}

# ── Keyword refinements ──────────────────────────────────────────────────

@test "keywords: 'Usage' at start of heading matches run mode" {
  run "$HDI" run --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"myapp serve"* ]]
}

@test "keywords: 'Memory Usage' does not match run mode" {
  run "$HDI" all --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" != *"512MB"* ]]
}

@test "keywords: 'Development' matches run mode" {
  run "$HDI" run --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm run dev"* ]]
}

@test "keywords: 'Dev' heading matches run mode" {
  run "$HDI" run --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm start"* ]]
}

@test "keywords: 'spec' dropped - API Specification does not match test mode" {
  run "$HDI" test --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" != *"OpenAPI"* ]]
}

@test "keywords: 'Docker' matches install mode" {
  run "$HDI" install --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docker compose up -d"* ]]
}

@test "keywords: 'Available Scripts' matches run mode" {
  run "$HDI" run --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm run lint"* ]]
}

@test "keywords: 'How to Install' matches install mode" {
  run "$HDI" install --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pip install keyword-app"* ]]
}

@test "keywords: 'Compilation' matches all mode" {
  run "$HDI" all --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"make all"* ]]
}

@test "keywords: 'Deployment' matches all mode" {
  run "$HDI" all --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kubectl apply"* ]]
}

@test "keywords: 'Deployment' matches deploy mode" {
  run "$HDI" deploy --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"kubectl apply"* ]]
}

@test "keywords: 'Dependencies' matches install mode (depend group fix)" {
  run "$HDI" install --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

@test "keywords: 'Make Targets' matches run mode" {
  run "$HDI" run --raw --ni "$FIXTURES/keyword-refinements"
  [ "$status" -eq 0 ]
  [[ "$output" == *"make clean"* ]]
  [[ "$output" == *"make build"* ]]
}

# ── Code fence tracking in section parser ────────────────────────────────────

@test "code-fence: comments inside code blocks are not parsed as headings" {
  run "$HDI" --raw --ni "$FIXTURES/code-fence-in-section"
  [ "$status" -eq 0 ]
  # "# This is a comment" should NOT appear as a section heading
  [[ "$output" != *"## This is a comment"* ]]
  [[ "$output" != *"## Required for production"* ]]
  [[ "$output" != *"## Note:"* ]]
}

@test "code-fence: commands after in-block comments are extracted correctly" {
  run "$HDI" --raw --ni "$FIXTURES/code-fence-in-section"
  [ "$status" -eq 0 ]
  [[ "$output" == *"myapp serve --port 8080"* ]]
  [[ "$output" == *"myapp configure --env production"* ]]
}

@test "code-fence: section structure is preserved around fenced blocks" {
  run "$HDI" --raw --ni "$FIXTURES/code-fence-in-section"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Installation"* ]]
  [[ "$output" == *"pip install myapp"* ]]
  [[ "$output" == *"## Usage"* ]]
}

@test "code-fence: --full mode does not crash on code block comments" {
  run "$HDI" --raw --full "$FIXTURES/code-fence-in-section"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pip install myapp"* ]]
  [[ "$output" == *"myapp serve"* ]]
}

@test "code-fence: bash comment lines inside blocks are extracted as commands" {
  # Bash comments (# ...) inside code blocks ARE part of the command block
  run "$HDI" --raw --ni "$FIXTURES/code-fence-in-section"
  [ "$status" -eq 0 ]
  [[ "$output" == *"# This is a comment, not a heading"* ]]
}

@test "code-fence: --full survives prose line directly before opening fence" {
  # Regression: prose immediately before ``` (no blank line) caused
  # _rf_render_line to clobber BASH_REMATCH → "unbound variable" error
  run "$HDI" --raw --full "$FIXTURES/prose-before-fence"
  [ "$status" -eq 0 ]
  [[ "$output" == *"pip install -r requirements.txt"* ]]
  [[ "$output" == *"python server.py"* ]]
  [[ "$output" == *"curl http://localhost:8080/health"* ]]
}

# ── Nested section body preservation ─────────────────────────────────────────

@test "nested-match: parent section body is preserved when child heading matches" {
  run "$HDI" --raw --ni "$FIXTURES/nested-match-loss"
  [ "$status" -eq 0 ]
  # "Set up" body (docker commands) must NOT be lost when "Prerequisites" matches
  [[ "$output" == *"docker compose build"* ]]
  [[ "$output" == *"docker compose up -d"* ]]
}

@test "nested-match: parent section appears as its own section" {
  run "$HDI" --raw --ni "$FIXTURES/nested-match-loss"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Set up"* ]]
}

@test "nested-match: child matching section also appears" {
  run "$HDI" --raw --ni "$FIXTURES/nested-match-loss"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Prerequisites"* ]]
}

@test "nested-match: non-matching sub-heading within parent shows as sub-group" {
  run "$HDI" --raw --ni "$FIXTURES/nested-match-loss"
  [ "$status" -eq 0 ]
  # "Database setup" is a ### inside "Set up" that doesn't match keywords
  # but should be preserved as a sub-heading group
  [[ "$output" == *"### Prepare schema"* ]]
  [[ "$output" == *"rails db:migrate"* ]]
}

@test "nested-match: deeper matching heading also shown in all mode" {
  run "$HDI" all --raw --ni "$FIXTURES/nested-match-loss"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Set up"* ]]
  [[ "$output" == *"## Prerequisites"* ]]
  [[ "$output" == *"## Testing"* ]]
}

# ── Bold-text pseudo-headings ────────────────────────────────────────────────

@test "bold-pseudo: standalone bold text creates sub-groups" {
  run "$HDI" --raw --ni "$FIXTURES/bold-pseudo-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### Install dependencies"* ]]
  [[ "$output" == *"### Configure environment"* ]]
  [[ "$output" == *"### Build the application"* ]]
  [[ "$output" == *"### Start the server"* ]]
}

@test "bold-pseudo: commands appear under their bold sub-group" {
  run "$HDI" --raw --ni "$FIXTURES/bold-pseudo-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"cp .env.example .env"* ]]
  [[ "$output" == *"npm run build"* ]]
  [[ "$output" == *"npm start"* ]]
}

@test "bold-pseudo: test mode also shows bold sub-groups" {
  run "$HDI" test --raw --ni "$FIXTURES/bold-pseudo-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### Unit tests"* ]]
  [[ "$output" == *"npm test"* ]]
  [[ "$output" == *"### Integration tests"* ]]
  [[ "$output" == *"npm run test:integration"* ]]
}

@test "bold-pseudo: section header is the markdown heading, not bold text" {
  run "$HDI" --raw --ni "$FIXTURES/bold-pseudo-headings"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Set up"* ]]
}

# ── Bold pseudo-heading keyword matching ──────────────────────────────────────

@test "bold-pseudo-kw: bold 'Run application' matches run mode" {
  run "$HDI" run --raw --ni "$FIXTURES/bold-pseudo-keywords"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docker compose up -d"* ]]
}

@test "bold-pseudo-kw: bold 'Set up' matches install mode" {
  run "$HDI" install --raw --ni "$FIXTURES/bold-pseudo-keywords"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

@test "bold-pseudo-kw: bold 'Run tests' matches test mode" {
  run "$HDI" test --raw --ni "$FIXTURES/bold-pseudo-keywords"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm test"* ]]
}

@test "bold-pseudo-kw: run mode does not include install-only sections" {
  run "$HDI" run --raw --ni "$FIXTURES/bold-pseudo-keywords"
  [ "$status" -eq 0 ]
  [[ "$output" != *"npm install"* ]]
}

# ── Sub-heading display groups ───────────────────────────────────────────────

@test "sub-groups: non-matching sub-headings create display groups" {
  run "$HDI" --raw --ni "$FIXTURES/sub-heading-groups"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### macOS"* ]]
  [[ "$output" == *"brew install node"* ]]
  [[ "$output" == *"### Linux"* ]]
  [[ "$output" == *"apt-get install nodejs"* ]]
}

@test "sub-groups: sub-headings without commands are not shown" {
  run "$HDI" --raw --ni "$FIXTURES/sub-heading-groups"
  [ "$status" -eq 0 ]
  # "Windows" has no code blocks, so it should not appear as a sub-header
  [[ "$output" != *"### Windows"* ]]
  # "Monitoring" has no code blocks either
  [[ "$output" != *"### Monitoring"* ]]
}

@test "sub-groups: multiple commands under one sub-heading" {
  run "$HDI" --raw --ni "$FIXTURES/sub-heading-groups"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### After cloning"* ]]
  [[ "$output" == *"npm install"* ]]
  [[ "$output" == *"npm run dev"* ]]
}

@test "sub-groups: run mode shows sub-headings within matched section" {
  run "$HDI" run --raw --ni "$FIXTURES/sub-heading-groups"
  [ "$status" -eq 0 ]
  [[ "$output" == *"### In production mode"* ]]
  [[ "$output" == *"npm run serve"* ]]
  [[ "$output" == *"### In staging mode"* ]]
  [[ "$output" == *"npm run serve --env staging"* ]]
}

# ── Needs mode ──────────────────────────────────────────────────────────────

@test "needs: reports installed tools" {
  run "$HDI" needs "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm"* ]]
}

@test "needs: marks missing tools" {
  run "$HDI" needs "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nvm"* ]]
  [[ "$output" == *"not found"* ]]
}

@test "needs: skips shell builtins like cp" {
  run "$HDI" needs "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  # cp is in the install section but should not appear in needs output
  [[ "$output" != *" cp "* ]]
}

@test "needs: deduplicates tool names" {
  run "$HDI" needs "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  # npm appears in multiple commands but should only be listed once
  local count
  count=$(echo "$output" | grep -c "npm" || true)
  [ "$count" -eq 1 ]
}

@test "needs: scans all sections (install + run + test)" {
  run "$HDI" needs "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm"* ]]
}

@test "needs: skips path-like commands" {
  run "$HDI" needs "$FIXTURES/ruby-rails"
  [ "$status" -eq 0 ]
  [[ "$output" != *"bin/rails"* ]]
  [[ "$output" != *"bin/dev"* ]]
}

@test "needs: skips flags in code blocks" {
  # Flags like -h, --help, --raw should not appear as tools
  run "$HDI" needs "$BATS_TEST_DIRNAME/.."
  [ "$status" -eq 0 ]
  [[ "$output" != *" -h,"* ]]
  [[ "$output" != *" -v,"* ]]
  [[ "$output" != *" -f,"* ]]
  [[ "$output" != *" --raw"* ]]
  [[ "$output" != *" --ni,"* ]]
}

# ── Contrib mode ───────────────────────────────────────────────────────────

@test "contrib: shows commands from CONTRIBUTING.md" {
  run "$HDI" contrib "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm run test:coverage"* ]]
  [[ "$output" == *"npm version patch"* ]]
}

@test "contrib: 'c' is an alias for contrib mode" {
  run "$HDI" c "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm run test:coverage"* ]]
}

@test "contrib: does not include README commands" {
  run "$HDI" contrib "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" != *"npx prisma migrate dev"* ]]
}

@test "contrib: error when no contributor docs found" {
  run "$HDI" contrib "$FIXTURES/python-flask"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no contributor docs found"* ]]
}

@test "contrib: default mode includes contrib with separator" {
  run "$HDI" --ni "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CONTRIBUTING.md"* ]]
  [[ "$output" == *"npm run test:coverage"* ]]
  [[ "$output" == *"npm install"* ]]
}

@test "contrib: --raw separator uses plain text" {
  run "$HDI" --raw "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--- CONTRIBUTING.md ---"* ]]
}

@test "contrib: mode filter applies to contrib sections" {
  run "$HDI" test "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm test"* ]]
  [[ "$output" == *"npm run test:coverage"* ]]
  # lint/format are not test commands
  [[ "$output" != *"npm run lint"* ]]
}

@test "contrib: no separator when no contrib files" {
  run "$HDI" --ni "$FIXTURES/python-flask"
  [ "$status" -eq 0 ]
  [[ "$output" != *"CONTRIBUTING"* ]]
}

# ── JSON output ────────────────────────────────────────────────────────────

@test "json: produces valid JSON" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -m json.tool > /dev/null
}

@test "json: contains modes object with all six modes" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  for mode in default install run test deploy all; do
    echo "$output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert '$mode' in d['modes'], '$mode missing from modes'"
  done
}

@test "json: contains fullProse object with all six modes" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  for mode in default install run test deploy all; do
    echo "$output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert '$mode' in d['fullProse'], '$mode missing from fullProse'"
  done
}

@test "json: contains needs array" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert isinstance(d['needs'], list)"
}

@test "json: modes items have type and text fields" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for item in d['modes']['default']:
    assert 'type' in item and 'text' in item, f'missing fields in {item}'
"
}

@test "json: install mode only has install-related commands" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
texts = [i['text'] for i in d['modes']['install'] if i['type'] == 'command']
assert 'npm install' in texts
assert 'npm run dev' not in texts
"
}

@test "json: fullProse includes prose and empty lines" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
types = {i['type'] for i in d['fullProse']['default']}
assert 'prose' in types, 'no prose items'
assert 'empty' in types, 'no empty items'
assert 'command' in types, 'no command items'
assert 'header' in types, 'no header items'
"
}

@test "json: needs items have tool and installed fields" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for item in d['needs']:
    assert 'tool' in item and 'installed' in item, f'missing fields in {item}'
"
}

@test "json: works with direct file path" {
  run "$HDI" --json "$FIXTURES/node-express/README.md"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -m json.tool > /dev/null
}

@test "json: skips json/yaml code blocks in modes" {
  run "$HDI" --json "$FIXTURES/node-express"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
# The JSON response block should not appear as a command
texts = [i['text'] for i in d['modes']['all'] if i['type'] == 'command']
assert '\"status\": \"ok\",' not in texts
"
}

# ── Platform detection ─────────────────────────────────────────────────────

@test "platform: config file detected (cloudflare)" {
  run "$HDI" deploy --ni "$FIXTURES/platform-cloudflare"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deploy → Cloudflare Pages"* ]]
  # High confidence — no question mark
  [[ "$output" != *"Cloudflare Pages?"* ]]
}

@test "platform: multiple platforms detected" {
  run "$HDI" deploy --ni "$FIXTURES/platform-multi"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deploy → Vercel, Netlify"* ]]
}

@test "platform: CLI tool detection (kamal)" {
  run "$HDI" deploy --ni "$FIXTURES/platform-cmd"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deploy → Kamal"* ]]
  # High confidence from CLI tool — no question mark
  [[ "$output" != *"Kamal?"* ]]
}

@test "platform: prose-only detection is low confidence" {
  run "$HDI" deploy --ni "$FIXTURES/platform-prose"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deploy → GitHub Pages?"* ]]
}

@test "platform: no platform detected shows plain [deploy]" {
  run "$HDI" deploy --ni "$FIXTURES/platform-none"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[deploy]"* ]]
  [[ "$output" != *"deploy →"* ]]
}

@test "platform: dedup — config + prose same group shows high confidence" {
  run "$HDI" deploy --ni "$FIXTURES/platform-cloudflare"
  [ "$status" -eq 0 ]
  # wrangler.toml (file) + "Cloudflare Pages" (prose) = high confidence
  [[ "$output" == *"deploy → Cloudflare Pages"* ]]
  [[ "$output" != *"Cloudflare Pages?"* ]]
}

@test "platform: --raw skips header (no platform shown)" {
  run "$HDI" deploy --raw "$FIXTURES/platform-cloudflare"
  [ "$status" -eq 0 ]
  [[ "$output" != *"deploy →"* ]]
  [[ "$output" == *"wrangler deploy"* ]]
}

@test "platform: json output includes platforms array" {
  run "$HDI" --json "$FIXTURES/platform-cloudflare"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
platforms = d['platforms']
assert len(platforms) > 0, 'expected at least one platform'
names = [p['name'] for p in platforms]
assert 'Cloudflare Pages' in names, f'expected Cloudflare Pages in {names}'
cf = [p for p in platforms if p['name'] == 'Cloudflare Pages'][0]
assert cf['confidence'] == 'high', f'expected high confidence, got {cf[\"confidence\"]}'
assert cf['group'] == 'cloudflare'
"
}

@test "platform: json output with no platforms returns empty array" {
  run "$HDI" --json "$FIXTURES/platform-none"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d['platforms'] == [], f'expected empty platforms, got {d[\"platforms\"]}'
"
}

@test "platform: json output with multiple platforms" {
  run "$HDI" --json "$FIXTURES/platform-multi"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
platforms = d['platforms']
names = [p['name'] for p in platforms]
assert 'Vercel' in names, f'expected Vercel in {names}'
assert 'Netlify' in names, f'expected Netlify in {names}'
assert all(p['confidence'] == 'high' for p in platforms), 'expected all high confidence'
"
}

@test "platform: not shown in install mode" {
  run "$HDI" install --ni "$FIXTURES/platform-cloudflare"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Cloudflare"* ]]
}

@test "platform: not shown in run mode" {
  run "$HDI" run --ni "$FIXTURES/react-nextjs"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Vercel"* ]]
}

@test "platform: Docker detected from deploy section commands" {
  run "$HDI" deploy --ni "$FIXTURES/platform-docker"
  [ "$status" -eq 0 ]
  [[ "$output" == *"deploy → Docker"* ]]
  [[ "$output" != *"Docker?"* ]]
}

@test "platform: Docker CLI tool detection" {
  run "$HDI" deploy --ni "$FIXTURES/platform-docker"
  [ "$status" -eq 0 ]
  [[ "$output" == *"docker build"* ]]
  [[ "$output" == *"docker push"* ]]
}

@test "platform: Docker json output" {
  run "$HDI" --json "$FIXTURES/platform-docker"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import json,sys
d=json.load(sys.stdin)
platforms = d['platforms']
names = [p['name'] for p in platforms]
assert 'Docker' in names, f'expected Docker in {names}'
dk = [p for p in platforms if p['name'] == 'Docker'][0]
assert dk['confidence'] == 'high', f'expected high confidence, got {dk[\"confidence\"]}'
assert dk['group'] == 'docker'
"
}
