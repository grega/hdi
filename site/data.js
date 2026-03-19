// Pre-computed hdi output data for 5 example projects
// Generated from test/fixtures/ from hdi

const PROJECTS = [
  {
    slug: "node-express",
    name: "express-api",
    description: "A REST API built with Express",
    lang: "JS",
    langFull: "JavaScript",
    readme: `# express-api

A REST API built with Express.

## Prerequisites

\`\`\`bash
nvm install 20
nvm use 20
\`\`\`

## Installation

\`\`\`bash
npm install
cp .env.example .env
\`\`\`

## Usage

\`\`\`bash
npm start
\`\`\`

## API Response

\`\`\`json
{
  "status": "ok",
  "data": []
}
\`\`\``,
    modes: {
      default: [
        { type: "header", text: "Prerequisites" },
        { type: "command", text: "nvm install 20" },
        { type: "command", text: "nvm use 20" },
        { type: "header", text: "Installation" },
        { type: "command", text: "npm install" },
        { type: "command", text: "cp .env.example .env" },
        { type: "header", text: "Usage" },
        { type: "command", text: "npm start" },
      ],
      install: [
        { type: "header", text: "Prerequisites" },
        { type: "command", text: "nvm install 20" },
        { type: "command", text: "nvm use 20" },
        { type: "header", text: "Installation" },
        { type: "command", text: "npm install" },
        { type: "command", text: "cp .env.example .env" },
      ],
      run: [
        { type: "header", text: "Usage" },
        { type: "command", text: "npm start" },
      ],
      test: [],
      all: [
        { type: "header", text: "Prerequisites" },
        { type: "command", text: "nvm install 20" },
        { type: "command", text: "nvm use 20" },
        { type: "header", text: "Installation" },
        { type: "command", text: "npm install" },
        { type: "command", text: "cp .env.example .env" },
        { type: "header", text: "Usage" },
        { type: "command", text: "npm start" },
      ],
    },
    check: [
      { tool: "nvm", installed: false },
      { tool: "npm", installed: true, version: "10.2.0" },
    ],
    fullProse: {
      default: [
        { type: "header", text: "Prerequisites" },
        { type: "empty", text: "" },
        { type: "command", text: "nvm install 20" },
        { type: "command", text: "nvm use 20" },
        { type: "empty", text: "" },
        { type: "header", text: "Installation" },
        { type: "empty", text: "" },
        { type: "command", text: "npm install" },
        { type: "command", text: "cp .env.example .env" },
        { type: "empty", text: "" },
        { type: "header", text: "Usage" },
        { type: "empty", text: "" },
        { type: "command", text: "npm start" },
      ],
      install: [
        { type: "header", text: "Prerequisites" },
        { type: "empty", text: "" },
        { type: "command", text: "nvm install 20" },
        { type: "command", text: "nvm use 20" },
        { type: "empty", text: "" },
        { type: "header", text: "Installation" },
        { type: "empty", text: "" },
        { type: "command", text: "npm install" },
        { type: "command", text: "cp .env.example .env" },
      ],
      run: [
        { type: "header", text: "Usage" },
        { type: "empty", text: "" },
        { type: "command", text: "npm start" },
      ],
      test: [],
      all: [
        { type: "header", text: "Prerequisites" },
        { type: "empty", text: "" },
        { type: "command", text: "nvm install 20" },
        { type: "command", text: "nvm use 20" },
        { type: "empty", text: "" },
        { type: "header", text: "Installation" },
        { type: "empty", text: "" },
        { type: "command", text: "npm install" },
        { type: "command", text: "cp .env.example .env" },
        { type: "empty", text: "" },
        { type: "header", text: "Usage" },
        { type: "empty", text: "" },
        { type: "command", text: "npm start" },
      ],
    },
  },
  {
    slug: "python-flask",
    name: "flask-app",
    description: "A simple Flask application",
    lang: "PY",
    langFull: "Python",
    readme: `# flask-app

A simple Flask application.

## Getting Started

### Set up a virtual environment

\`\`\`bash
python3 -m venv venv
source venv/bin/activate
\`\`\`

### Install dependencies

\`\`\`bash
pip install -r requirements.txt
\`\`\`

### Run the development server

\`\`\`bash
flask run --debug
\`\`\`

## Configuration

\`\`\`yaml
DATABASE_URL: postgres://localhost/flask_app
SECRET_KEY: change-me
\`\`\`

## License

MIT`,
    modes: {
      default: [
        { type: "header", text: "Getting Started" },
        { type: "empty", text: "(no commands \u2014 use --full to see prose)" },
        { type: "subheader", text: "Set up a virtual environment" },
        { type: "command", text: "python3 -m venv venv" },
        { type: "command", text: "source venv/bin/activate" },
        { type: "subheader", text: "Install dependencies" },
        { type: "command", text: "pip install -r requirements.txt" },
        { type: "subheader", text: "Run the development server" },
        { type: "command", text: "flask run --debug" },
      ],
      install: [
        { type: "header", text: "Getting Started" },
        { type: "empty", text: "(no commands \u2014 use --full to see prose)" },
        { type: "subheader", text: "Set up a virtual environment" },
        { type: "command", text: "python3 -m venv venv" },
        { type: "command", text: "source venv/bin/activate" },
        { type: "subheader", text: "Install dependencies" },
        { type: "command", text: "pip install -r requirements.txt" },
      ],
      run: [
        { type: "header", text: "Getting Started" },
        { type: "subheader", text: "Set up a virtual environment" },
        { type: "command", text: "python3 -m venv venv" },
        { type: "command", text: "source venv/bin/activate" },
        { type: "subheader", text: "Install dependencies" },
        { type: "command", text: "pip install -r requirements.txt" },
        { type: "subheader", text: "Run the development server" },
        { type: "command", text: "flask run --debug" },
      ],
      test: [],
      all: [
        { type: "header", text: "Getting Started" },
        { type: "empty", text: "(no commands \u2014 use --full to see prose)" },
        { type: "subheader", text: "Set up a virtual environment" },
        { type: "command", text: "python3 -m venv venv" },
        { type: "command", text: "source venv/bin/activate" },
        { type: "subheader", text: "Install dependencies" },
        { type: "command", text: "pip install -r requirements.txt" },
        { type: "subheader", text: "Run the development server" },
        { type: "command", text: "flask run --debug" },
        { type: "header", text: "Configuration" },
        { type: "empty", text: "(no commands \u2014 use --full to see prose)" },
      ],
    },
    check: [
      { tool: "python3", installed: true, version: "3.11.4" },
      { tool: "pip", installed: true, version: "23.2.1" },
      { tool: "flask", installed: true, version: "3.0.0" },
    ],
    fullProse: {
      default: [
        { type: "header", text: "Set up a virtual environment" },
        { type: "empty", text: "" },
        { type: "command", text: "python3 -m venv venv" },
        { type: "command", text: "source venv/bin/activate" },
        { type: "empty", text: "" },
        { type: "header", text: "Install dependencies" },
        { type: "empty", text: "" },
        { type: "command", text: "pip install -r requirements.txt" },
        { type: "empty", text: "" },
        { type: "header", text: "Run the development server" },
        { type: "empty", text: "" },
        { type: "command", text: "flask run --debug" },
      ],
      install: [
        { type: "header", text: "Set up a virtual environment" },
        { type: "empty", text: "" },
        { type: "command", text: "python3 -m venv venv" },
        { type: "command", text: "source venv/bin/activate" },
        { type: "empty", text: "" },
        { type: "header", text: "Install dependencies" },
        { type: "empty", text: "" },
        { type: "command", text: "pip install -r requirements.txt" },
      ],
      run: [
        { type: "header", text: "Getting Started" },
        { type: "empty", text: "" },
        { type: "subheader", text: "Set up a virtual environment" },
        { type: "empty", text: "" },
        { type: "command", text: "python3 -m venv venv" },
        { type: "command", text: "source venv/bin/activate" },
        { type: "empty", text: "" },
        { type: "subheader", text: "Install dependencies" },
        { type: "empty", text: "" },
        { type: "command", text: "pip install -r requirements.txt" },
        { type: "empty", text: "" },
        { type: "header", text: "Run the development server" },
        { type: "empty", text: "" },
        { type: "command", text: "flask run --debug" },
      ],
      test: [],
      all: [
        { type: "header", text: "Set up a virtual environment" },
        { type: "empty", text: "" },
        { type: "command", text: "python3 -m venv venv" },
        { type: "command", text: "source venv/bin/activate" },
        { type: "empty", text: "" },
        { type: "header", text: "Install dependencies" },
        { type: "empty", text: "" },
        { type: "command", text: "pip install -r requirements.txt" },
        { type: "empty", text: "" },
        { type: "header", text: "Run the development server" },
        { type: "empty", text: "" },
        { type: "command", text: "flask run --debug" },
        { type: "empty", text: "" },
        { type: "header", text: "Configuration" },
        { type: "empty", text: "" },
        { type: "prose", text: "DATABASE_URL: postgres://localhost/flask_app" },
        { type: "prose", text: "SECRET_KEY: change-me" },
      ],
    },
  },
  {
    slug: "ruby-rails",
    name: "rails-app",
    description: "A Ruby on Rails application",
    lang: "RB",
    langFull: "Ruby",
    readme: `# rails-app

A Ruby on Rails application.

## Prerequisites

- Ruby 3.3+
- PostgreSQL 16+
- Redis

\`\`\`bash
brew install ruby postgresql redis
\`\`\`

## Installation

\`\`\`bash
bundle install
rails db:create db:migrate db:seed
\`\`\`

## Running

\`\`\`bash
bin/rails server
\`\`\`

Or with Foreman:

\`\`\`bash
bin/dev
\`\`\`

## Testing

\`\`\`bash
bundle exec rspec
\`\`\``,
    modes: {
      default: [
        { type: "header", text: "Prerequisites" },
        { type: "command", text: "brew install ruby postgresql redis" },
        { type: "header", text: "Installation" },
        { type: "command", text: "bundle install" },
        { type: "command", text: "rails db:create db:migrate db:seed" },
        { type: "header", text: "Running" },
        { type: "command", text: "bin/rails server" },
        { type: "command", text: "bin/dev" },
      ],
      install: [
        { type: "header", text: "Prerequisites" },
        { type: "command", text: "brew install ruby postgresql redis" },
        { type: "header", text: "Installation" },
        { type: "command", text: "bundle install" },
        { type: "command", text: "rails db:create db:migrate db:seed" },
      ],
      run: [
        { type: "header", text: "Running" },
        { type: "command", text: "bin/rails server" },
        { type: "command", text: "bin/dev" },
      ],
      test: [
        { type: "header", text: "Testing" },
        { type: "command", text: "bundle exec rspec" },
      ],
      all: [
        { type: "header", text: "Prerequisites" },
        { type: "command", text: "brew install ruby postgresql redis" },
        { type: "header", text: "Installation" },
        { type: "command", text: "bundle install" },
        { type: "command", text: "rails db:create db:migrate db:seed" },
        { type: "header", text: "Running" },
        { type: "command", text: "bin/rails server" },
        { type: "command", text: "bin/dev" },
        { type: "header", text: "Testing" },
        { type: "command", text: "bundle exec rspec" },
      ],
    },
    check: [
      { tool: "brew", installed: true, version: "4.2.0" },
      { tool: "bundle", installed: true, version: "2.5.3" },
      { tool: "rails", installed: true, version: "7.1.2" },
      { tool: "rspec", installed: false },
    ],
    fullProse: {
      default: [
        { type: "header", text: "Prerequisites" },
        { type: "empty", text: "" },
        { type: "prose", text: "- Ruby 3.3+" },
        { type: "prose", text: "- PostgreSQL 16+" },
        { type: "prose", text: "- Redis" },
        { type: "empty", text: "" },
        { type: "command", text: "brew install ruby postgresql redis" },
        { type: "empty", text: "" },
        { type: "header", text: "Installation" },
        { type: "empty", text: "" },
        { type: "command", text: "bundle install" },
        { type: "command", text: "rails db:create db:migrate db:seed" },
        { type: "empty", text: "" },
        { type: "header", text: "Running" },
        { type: "empty", text: "" },
        { type: "command", text: "bin/rails server" },
        { type: "empty", text: "" },
        { type: "prose", text: "Or with Foreman:" },
        { type: "empty", text: "" },
        { type: "command", text: "bin/dev" },
      ],
      install: [
        { type: "header", text: "Prerequisites" },
        { type: "empty", text: "" },
        { type: "prose", text: "- Ruby 3.3+" },
        { type: "prose", text: "- PostgreSQL 16+" },
        { type: "prose", text: "- Redis" },
        { type: "empty", text: "" },
        { type: "command", text: "brew install ruby postgresql redis" },
        { type: "empty", text: "" },
        { type: "header", text: "Installation" },
        { type: "empty", text: "" },
        { type: "command", text: "bundle install" },
        { type: "command", text: "rails db:create db:migrate db:seed" },
      ],
      run: [
        { type: "header", text: "Running" },
        { type: "empty", text: "" },
        { type: "command", text: "bin/rails server" },
        { type: "empty", text: "" },
        { type: "prose", text: "Or with Foreman:" },
        { type: "empty", text: "" },
        { type: "command", text: "bin/dev" },
      ],
      test: [
        { type: "header", text: "Testing" },
        { type: "empty", text: "" },
        { type: "command", text: "bundle exec rspec" },
      ],
      all: [
        { type: "header", text: "Prerequisites" },
        { type: "empty", text: "" },
        { type: "prose", text: "- Ruby 3.3+" },
        { type: "prose", text: "- PostgreSQL 16+" },
        { type: "prose", text: "- Redis" },
        { type: "empty", text: "" },
        { type: "command", text: "brew install ruby postgresql redis" },
        { type: "empty", text: "" },
        { type: "header", text: "Installation" },
        { type: "empty", text: "" },
        { type: "command", text: "bundle install" },
        { type: "command", text: "rails db:create db:migrate db:seed" },
        { type: "empty", text: "" },
        { type: "header", text: "Running" },
        { type: "empty", text: "" },
        { type: "command", text: "bin/rails server" },
        { type: "empty", text: "" },
        { type: "prose", text: "Or with Foreman:" },
        { type: "empty", text: "" },
        { type: "command", text: "bin/dev" },
        { type: "empty", text: "" },
        { type: "header", text: "Testing" },
        { type: "empty", text: "" },
        { type: "command", text: "bundle exec rspec" },
      ],
    },
  },
  {
    slug: "react-nextjs",
    name: "my-next-app",
    description: "A Next.js application with App Router",
    lang: "TS",
    langFull: "TypeScript",
    readme: `# my-next-app

A Next.js application with App Router.

## Getting Started

First, install dependencies:

\`\`\`bash
npm install
\`\`\`

Then, run the development server:

\`\`\`bash
npm run dev
\`\`\`

Open [http://localhost:3000](http://localhost:3000) with your browser.

## Deploy

\`\`\`bash
npm run build
npx vercel --prod
\`\`\`

## Learn More

See the [Next.js docs](https://nextjs.org/docs).`,
    modes: {
      default: [
        { type: "header", text: "Getting Started" },
        { type: "command", text: "npm install" },
        { type: "command", text: "npm run dev" },
      ],
      install: [
        { type: "header", text: "Getting Started" },
        { type: "command", text: "npm install" },
        { type: "command", text: "npm run dev" },
      ],
      run: [
        { type: "header", text: "Getting Started" },
        { type: "command", text: "npm install" },
        { type: "command", text: "npm run dev" },
      ],
      test: [],
      all: [
        { type: "header", text: "Getting Started" },
        { type: "command", text: "npm install" },
        { type: "command", text: "npm run dev" },
        { type: "header", text: "Deploy" },
        { type: "command", text: "npm run build" },
        { type: "command", text: "npx vercel --prod" },
      ],
    },
    check: [
      { tool: "npm", installed: true, version: "10.2.0" },
      { tool: "npx", installed: true, version: "10.2.0" },
      { tool: "vercel", installed: false },
    ],
    fullProse: {
      default: [
        { type: "header", text: "Getting Started" },
        { type: "empty", text: "" },
        { type: "prose", text: "First, install dependencies:" },
        { type: "empty", text: "" },
        { type: "command", text: "npm install" },
        { type: "empty", text: "" },
        { type: "prose", text: "Then, run the development server:" },
        { type: "empty", text: "" },
        { type: "command", text: "npm run dev" },
        { type: "empty", text: "" },
        { type: "prose", text: "Open [http://localhost:3000](http://localhost:3000) with your browser." },
      ],
      install: [
        { type: "header", text: "Getting Started" },
        { type: "empty", text: "" },
        { type: "prose", text: "First, install dependencies:" },
        { type: "empty", text: "" },
        { type: "command", text: "npm install" },
        { type: "empty", text: "" },
        { type: "prose", text: "Then, run the development server:" },
        { type: "empty", text: "" },
        { type: "command", text: "npm run dev" },
        { type: "empty", text: "" },
        { type: "prose", text: "Open [http://localhost:3000](http://localhost:3000) with your browser." },
      ],
      run: [
        { type: "header", text: "Getting Started" },
        { type: "empty", text: "" },
        { type: "prose", text: "First, install dependencies:" },
        { type: "empty", text: "" },
        { type: "command", text: "npm install" },
        { type: "empty", text: "" },
        { type: "prose", text: "Then, run the development server:" },
        { type: "empty", text: "" },
        { type: "command", text: "npm run dev" },
        { type: "empty", text: "" },
        { type: "prose", text: "Open [http://localhost:3000](http://localhost:3000) with your browser." },
      ],
      test: [],
      all: [
        { type: "header", text: "Getting Started" },
        { type: "empty", text: "" },
        { type: "prose", text: "First, install dependencies:" },
        { type: "empty", text: "" },
        { type: "command", text: "npm install" },
        { type: "empty", text: "" },
        { type: "prose", text: "Then, run the development server:" },
        { type: "empty", text: "" },
        { type: "command", text: "npm run dev" },
        { type: "empty", text: "" },
        { type: "prose", text: "Open [http://localhost:3000](http://localhost:3000) with your browser." },
        { type: "empty", text: "" },
        { type: "header", text: "Deploy" },
        { type: "empty", text: "" },
        { type: "command", text: "npm run build" },
        { type: "command", text: "npx vercel --prod" },
      ],
    },
  },
  {
    slug: "go-project",
    name: "go-service",
    description: "A microservice written in Go",
    lang: "GO",
    langFull: "Go",
    readme: `# go-service

A microservice written in Go.

## Requirements

\`\`\`bash
brew install go
\`\`\`

## Setup

\`\`\`bash
go mod download
cp config.example.yaml config.yaml
\`\`\`

## Build

\`\`\`bash
go build -o bin/service ./cmd/service
\`\`\`

## Running

\`\`\`bash
./bin/service --port 8080
\`\`\`

## Environment Variables

\`\`\`env
PORT=8080
DB_HOST=localhost
\`\`\``,
    modes: {
      default: [
        { type: "header", text: "Requirements" },
        { type: "command", text: "brew install go" },
        { type: "header", text: "Setup" },
        { type: "command", text: "go mod download" },
        { type: "command", text: "cp config.example.yaml config.yaml" },
        { type: "header", text: "Running" },
        { type: "command", text: "./bin/service --port 8080" },
      ],
      install: [
        { type: "header", text: "Requirements" },
        { type: "command", text: "brew install go" },
        { type: "header", text: "Setup" },
        { type: "command", text: "go mod download" },
        { type: "command", text: "cp config.example.yaml config.yaml" },
      ],
      run: [
        { type: "header", text: "Running" },
        { type: "command", text: "./bin/service --port 8080" },
      ],
      test: [],
      all: [
        { type: "header", text: "Requirements" },
        { type: "command", text: "brew install go" },
        { type: "header", text: "Setup" },
        { type: "command", text: "go mod download" },
        { type: "command", text: "cp config.example.yaml config.yaml" },
        { type: "header", text: "Build" },
        { type: "command", text: "go build -o bin/service ./cmd/service" },
        { type: "header", text: "Running" },
        { type: "command", text: "./bin/service --port 8080" },
        { type: "header", text: "Environment Variables" },
        { type: "empty", text: "(no commands \u2014 use --full to see prose)" },
      ],
    },
    check: [
      { tool: "brew", installed: true, version: "4.2.0" },
      { tool: "go", installed: true, version: "1.22.0" },
    ],
    fullProse: {
      default: [
        { type: "header", text: "Requirements" },
        { type: "empty", text: "" },
        { type: "command", text: "brew install go" },
        { type: "empty", text: "" },
        { type: "header", text: "Setup" },
        { type: "empty", text: "" },
        { type: "command", text: "go mod download" },
        { type: "command", text: "cp config.example.yaml config.yaml" },
        { type: "empty", text: "" },
        { type: "header", text: "Running" },
        { type: "empty", text: "" },
        { type: "command", text: "./bin/service --port 8080" },
      ],
      install: [
        { type: "header", text: "Requirements" },
        { type: "empty", text: "" },
        { type: "command", text: "brew install go" },
        { type: "empty", text: "" },
        { type: "header", text: "Setup" },
        { type: "empty", text: "" },
        { type: "command", text: "go mod download" },
        { type: "command", text: "cp config.example.yaml config.yaml" },
      ],
      run: [
        { type: "header", text: "Running" },
        { type: "empty", text: "" },
        { type: "command", text: "./bin/service --port 8080" },
      ],
      test: [],
      all: [
        { type: "header", text: "Requirements" },
        { type: "empty", text: "" },
        { type: "command", text: "brew install go" },
        { type: "empty", text: "" },
        { type: "header", text: "Setup" },
        { type: "empty", text: "" },
        { type: "command", text: "go mod download" },
        { type: "command", text: "cp config.example.yaml config.yaml" },
        { type: "empty", text: "" },
        { type: "header", text: "Build" },
        { type: "empty", text: "" },
        { type: "command", text: "go build -o bin/service ./cmd/service" },
        { type: "empty", text: "" },
        { type: "header", text: "Running" },
        { type: "empty", text: "" },
        { type: "command", text: "./bin/service --port 8080" },
        { type: "empty", text: "" },
        { type: "header", text: "Environment Variables" },
        { type: "empty", text: "" },
        { type: "prose", text: "PORT=8080" },
        { type: "prose", text: "DB_HOST=localhost" },
      ],
    },
  },
];

const HELP_TEXT = `hdi - "How do I..." \u2014 Extracts setup/run/test commands from a README.

Usage:
  hdi                           Interactive command picker (default in a terminal)
  hdi install                   Just install/setup commands
  hdi run                       Just run/start commands
  hdi test                      Just test commands
  hdi all                       Show all matched sections
  hdi check                     Check which tools are installed
  hdi [mode] --full             Include prose around commands
  hdi [mode] --raw              Plain markdown output (no colour, good for piping)

Interactive controls:
  \u2191/\u2193  k/j     Navigate commands
  Enter        Execute the highlighted command
  c            Copy highlighted command to clipboard
  q / Esc      Quit

Aliases: "install" = "setup" = "i", "run" = "start" = "r", "test" = "t", "check" = "c"`;

const VERSION = "0.14.0";
