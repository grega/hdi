package integration_test

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

var (
	binary   string
	fixtures string
)

func TestMain(m *testing.M) {
	// Build the binary once before all tests
	tmpDir, err := os.MkdirTemp("", "hdi-test")
	if err != nil {
		panic(err)
	}
	binary = filepath.Join(tmpDir, "hdi")

	// Find the go/ root directory (this test file is in go/internal/)
	goRoot := filepath.Join(mustGetwd(), "..")
	cmd := exec.Command("go", "build", "-o", binary, "./cmd/hdi/")
	cmd.Dir = goRoot
	if out, err := cmd.CombinedOutput(); err != nil {
		panic("failed to build: " + string(out))
	}

	// Fixtures are at the repo root test/fixtures/
	fixtures = filepath.Join(goRoot, "..", "test", "fixtures")

	code := m.Run()
	os.RemoveAll(tmpDir)
	os.Exit(code)
}

func mustGetwd() string {
	wd, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	return wd
}

func run(t *testing.T, args ...string) (string, int) {
	t.Helper()
	cmd := exec.Command(binary, args...)
	out, err := cmd.CombinedOutput()
	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			t.Fatalf("failed to run hdi: %v", err)
		}
	}
	return string(out), exitCode
}

func assertContains(t *testing.T, output, substr string) {
	t.Helper()
	if !strings.Contains(output, substr) {
		t.Errorf("expected output to contain %q, got:\n%s", substr, truncate(output, 500))
	}
}

func assertNotContains(t *testing.T, output, substr string) {
	t.Helper()
	if strings.Contains(output, substr) {
		t.Errorf("expected output NOT to contain %q, got:\n%s", substr, truncate(output, 500))
	}
}

func assertExitCode(t *testing.T, code, expected int) {
	t.Helper()
	if code != expected {
		t.Errorf("expected exit code %d, got %d", expected, code)
	}
}

func truncate(s string, n int) string {
	if len(s) > n {
		return s[:n] + "..."
	}
	return s
}

// ── CLI basics ──────────────────────────────────────────────────────────────

func TestHelpPrintsUsage(t *testing.T) {
	out, code := run(t, "--help")
	assertExitCode(t, code, 0)
	assertContains(t, out, "Usage:")
	assertContains(t, out, "hdi install")
}

func TestShortHelp(t *testing.T) {
	out, code := run(t, "-h")
	assertExitCode(t, code, 0)
	assertContains(t, out, "Usage:")
}

func TestUnknownArgument(t *testing.T) {
	out, code := run(t, "--nonsense")
	assertExitCode(t, code, 1)
	assertContains(t, out, "unknown argument")
}

func TestNoREADME(t *testing.T) {
	out, code := run(t, "--ni", filepath.Join(fixtures, "no-readme"))
	assertExitCode(t, code, 1)
	assertContains(t, out, "no README found")
}

func TestDirectoryPath(t *testing.T) {
	out, code := run(t, "--raw", filepath.Join(fixtures, "node-express"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "npm install")
}

func TestDirectFilePath(t *testing.T) {
	out, code := run(t, "--raw", filepath.Join(fixtures, "node-express", "README.md"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "npm install")
}

// ── README discovery ────────────────────────────────────────────────────────

func TestFindsLowercaseReadme(t *testing.T) {
	out, code := run(t, "--raw", filepath.Join(fixtures, "readme-lowercase"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "make install")
}

func TestFindsTitlecaseReadme(t *testing.T) {
	out, code := run(t, "--raw", filepath.Join(fixtures, "readme-titlecase"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "./configure")
}

// ── Mode aliases ────────────────────────────────────────────────────────────

func TestInstallMode(t *testing.T) {
	out, code := run(t, "install", "--raw", filepath.Join(fixtures, "node-express"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "npm install")
	assertNotContains(t, out, "npm start")
}

func TestSetupAlias(t *testing.T) {
	out, code := run(t, "setup", "--raw", filepath.Join(fixtures, "go-project"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "go mod download")
	assertNotContains(t, out, "./bin/service")
}

func TestIAlias(t *testing.T) {
	out, code := run(t, "i", "--raw", filepath.Join(fixtures, "node-express"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "npm install")
	assertNotContains(t, out, "npm start")
}

func TestRunMode(t *testing.T) {
	out, code := run(t, "run", "--raw", filepath.Join(fixtures, "ruby-rails"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "bin/rails server")
	assertNotContains(t, out, "bundle install")
}

func TestStartAlias(t *testing.T) {
	out, code := run(t, "start", "--raw", filepath.Join(fixtures, "elixir-phoenix"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "mix phx.server")
	assertNotContains(t, out, "mix deps.get")
}

func TestTestMode(t *testing.T) {
	out, code := run(t, "test", "--raw", filepath.Join(fixtures, "ruby-rails"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "bundle exec rspec")
	assertNotContains(t, out, "bundle install")
	assertNotContains(t, out, "bin/rails server")
}

func TestDeployMode(t *testing.T) {
	out, code := run(t, "deploy", "--raw", filepath.Join(fixtures, "deploy-pipeline"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "kubectl apply")
	assertContains(t, out, "helm upgrade")
	assertNotContains(t, out, "npm install")
}

func TestDeployMatchesCICD(t *testing.T) {
	out, code := run(t, "deploy", "--raw", filepath.Join(fixtures, "deploy-pipeline"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "act -j deploy")
}

func TestDeployMatchesPublishing(t *testing.T) {
	out, code := run(t, "deploy", "--raw", filepath.Join(fixtures, "deploy-pipeline"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "npm publish")
}

func TestDeployMatchesRollout(t *testing.T) {
	out, code := run(t, "deploy", "--raw", filepath.Join(fixtures, "deploy-pipeline"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "kubectl rollout")
}

func TestAllMode(t *testing.T) {
	out, code := run(t, "all", "--raw", filepath.Join(fixtures, "ruby-rails"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "bundle install")
	assertContains(t, out, "bin/rails server")
	assertContains(t, out, "bundle exec rspec")
}

func TestDefaultMode(t *testing.T) {
	out, code := run(t, "--raw", filepath.Join(fixtures, "deploy-pipeline"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "npm install")
	assertContains(t, out, "npm start")
	assertContains(t, out, "npm test")
	assertContains(t, out, "kubectl apply")
}

// ── Flags ───────────────────────────────────────────────────────────────────

func TestRawStripsANSI(t *testing.T) {
	out, code := run(t, "--raw", filepath.Join(fixtures, "node-express"))
	assertExitCode(t, code, 0)
	assertNotContains(t, out, "\033")
}

func TestRawMarkdownHeadings(t *testing.T) {
	out, code := run(t, "--raw", filepath.Join(fixtures, "node-express"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "## Prerequisites")
	assertContains(t, out, "## Installation")
}

func TestNonInteractive(t *testing.T) {
	out, code := run(t, "--ni", filepath.Join(fixtures, "node-express"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "npm install")
}

func TestFullIncludesProse(t *testing.T) {
	out, code := run(t, "--full", "--raw", filepath.Join(fixtures, "react-nextjs"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "install dependencies")
	assertContains(t, out, "npm install")
}

func TestRawWithoutFullOmitsProse(t *testing.T) {
	out, code := run(t, "--raw", filepath.Join(fixtures, "react-nextjs"))
	assertExitCode(t, code, 0)
	assertNotContains(t, out, "install dependencies")
	assertContains(t, out, "npm install")
}

// ── Section keyword matching ───────────────────────────────────────────────

func TestMatchesPrerequisites(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "node-express"))
	assertContains(t, out, "nvm install 20")
}

func TestMatchesGettingStarted(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "react-nextjs"))
	assertContains(t, out, "npm install")
}

func TestMatchesRequirements(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "go-project"))
	assertContains(t, out, "brew install go")
}

func TestMatchesDependencies(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "kubernetes-helm"))
	assertContains(t, out, "brew install kubectl helm")
}

func TestMatchesSetup(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "elixir-phoenix"))
	assertContains(t, out, "mix deps.get")
}

func TestMatchesQuickStart(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "nested-sections"))
	assertContains(t, out, "cargo run")
}

// ── Code block filtering ───────────────────────────────────────────────────

func TestSkipsJSON(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "node-express"))
	assertNotContains(t, out, `"status"`)
}

func TestSkipsYAML(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "python-flask"))
	assertNotContains(t, out, "DATABASE_URL")
}

func TestSkipsTOML(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "mixed-blocks"))
	assertNotContains(t, out, "[server]")
}

func TestSkipsXML(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "mixed-blocks"))
	assertNotContains(t, out, "<config>")
}

func TestSkipsLog(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "mixed-blocks"))
	assertNotContains(t, out, "[INFO]")
}

func TestSkipsText(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "rust-cargo"))
	assertNotContains(t, out, "0.45s")
}

func TestSkipsEnv(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "go-project"))
	assertNotContains(t, out, "DB_HOST")
}

func TestExtractsShell(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "mixed-blocks"))
	assertContains(t, out, "mixed-app init")
}

func TestExtractsUnlabelled(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "mixed-blocks"))
	assertContains(t, out, "npm install -g mixed-app")
}

// ── Real-world README patterns ─────────────────────────────────────────────

func TestNodeExpress(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "node-express"))
	assertContains(t, out, "nvm install 20")
	assertContains(t, out, "npm install")
	assertContains(t, out, "cp .env.example .env")
	assertContains(t, out, "npm run dev")
}

func TestPythonFlask(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "python-flask"))
	assertContains(t, out, "python3 -m venv venv")
	assertContains(t, out, "source venv/bin/activate")
	assertContains(t, out, "pip install -r requirements.txt")
	assertContains(t, out, "flask run --debug")
}

func TestRustCargo(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "rust-cargo"))
	assertContains(t, out, "cargo install ripfind")
	assertContains(t, out, "cargo build --release")
	assertContains(t, out, `ripfind "pattern"`)
}

func TestGoProject(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "go-project"))
	assertContains(t, out, "brew install go")
	assertContains(t, out, "go mod download")
	assertContains(t, out, "go build -o bin/service ./cmd/service")
	assertContains(t, out, "./bin/service --port 8080")
}

func TestRubyRails(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "ruby-rails"))
	assertContains(t, out, "brew install ruby postgresql redis")
	assertContains(t, out, "bundle install")
	assertContains(t, out, "rails db:create db:migrate db:seed")
	assertContains(t, out, "bin/rails server")
}

func TestReactNextjs(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "react-nextjs"))
	assertContains(t, out, "npm install")
	assertContains(t, out, "npm run dev")
}

func TestReactNextjsDeploy(t *testing.T) {
	out, _ := run(t, "deploy", "--raw", filepath.Join(fixtures, "react-nextjs"))
	assertContains(t, out, "npx vercel --prod")
}

func TestTerraform(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "terraform"))
	assertContains(t, out, "terraform init")
	assertContains(t, out, "terraform plan")
	assertContains(t, out, "terraform apply -auto-approve")
}

func TestTerraformSkipsDataBlocks(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "terraform"))
	assertNotContains(t, out, "us-east-1")
	assertNotContains(t, out, "vpc-abc123")
}

func TestElixirPhoenix(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "elixir-phoenix"))
	assertContains(t, out, "mix deps.get")
	assertContains(t, out, "mix ecto.setup")
	assertContains(t, out, "mix phx.server")
}

func TestJavaSpring(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "java-spring"))
	assertContains(t, out, "sdk install java")
	assertContains(t, out, "mvn clean install")
	assertContains(t, out, "mvn spring-boot:run")
}

func TestKubernetesHelm(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "kubernetes-helm"))
	assertContains(t, out, "brew install kubectl helm")
	assertContains(t, out, "helm repo add")
	assertContains(t, out, "helm install my-release")
	assertContains(t, out, "kubectl get pods")
}

func TestKubernetesSkipsYAML(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "kubernetes-helm"))
	assertNotContains(t, out, "replicaCount")
}

func TestMixedBlocks(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "mixed-blocks"))
	assertContains(t, out, "npm install -g mixed-app")
	assertContains(t, out, "mixed-app init")
	assertContains(t, out, "mixed-app serve")
	assertNotContains(t, out, `"port"`)
	assertNotContains(t, out, "DATABASE_URL")
}

// ── Nested sections ────────────────────────────────────────────────────────

func TestNestedSections(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "nested-sections"))
	assertContains(t, out, "rustup")
	assertContains(t, out, "cargo run")
}

func TestNestedAllMode(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "nested-sections"))
	assertContains(t, out, "cargo build --release")
	assertContains(t, out, "cargo test")
}

// ── Inline backtick commands ─────────────────────────────────────────────

func TestInlineHeadingCommands(t *testing.T) {
	out, _ := run(t, "run", "--raw", filepath.Join(fixtures, "inline-commands"))
	assertContains(t, out, "yarn start")
}

func TestInlineProseCommands(t *testing.T) {
	out, _ := run(t, "test", "--raw", filepath.Join(fixtures, "inline-commands"))
	assertContains(t, out, "yarn exec cypress run")
	assertContains(t, out, "yarn exec cypress open")
}

func TestInlineNonCommandNotExtracted(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "inline-commands"))
	assertNotContains(t, out, "Jest")
	assertNotContains(t, out, "jest-axe")
	assertNotContains(t, out, "haveNoViolations")
}

// ── Shell prompt stripping ───────────────────────────────────────────────

func TestPromptStripping(t *testing.T) {
	out, _ := run(t, "install", "--raw", filepath.Join(fixtures, "prompt-prefixes"))
	assertContains(t, out, "npm install")
	assertContains(t, out, "npm run build")
	assertNotContains(t, out, "$ npm")
}

func TestPercentPromptStripping(t *testing.T) {
	out, _ := run(t, "run", "--raw", filepath.Join(fixtures, "prompt-prefixes"))
	assertContains(t, out, "yarn start")
	assertNotContains(t, out, "% yarn")
}

func TestDollarVarPreserved(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "prompt-prefixes"))
	assertContains(t, out, "$HOME/bin/setup")
}

func TestPromptStripsBuiltins(t *testing.T) {
	out, _ := run(t, "all", "--raw", filepath.Join(fixtures, "prompt-prefixes"))
	assertContains(t, out, "export NODE_ENV=production")
	assertNotContains(t, out, "$ export")
}

// ── Table commands ───────────────────────────────────────────────────────────

func TestTableCommands(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "table-commands"))
	assertContains(t, out, "npm i")
	assertContains(t, out, "npm run dev")
	assertContains(t, out, "npm run build")
}

func TestTableDoesNotExtractProse(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "table-commands"))
	assertNotContains(t, out, "localhost")
	assertNotContains(t, out, "Installs dependencies")
}

// ── Prose-only sections ────────────────────────────────────────────────────

func TestProseOnlyShowsHint(t *testing.T) {
	out, _ := run(t, "--ni", filepath.Join(fixtures, "prose-only"))
	assertContains(t, out, "no commands")
}

// ── Advanced parsing ─────────────────────────────────────────────────────

func TestSetextHeadings(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "setext-headings"))
	assertContains(t, out, "npm install")
}

func TestTildeFences(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "tilde-fences"))
	assertContains(t, out, "pip install tilde-app")
}

func TestMultilineCommands(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "multiline-commands"))
	assertContains(t, out, "docker build")
}

func TestConsoleBlocks(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "console-blocks"))
	assertContains(t, out, "npm install")
}

func TestFormattedHeadings(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "formatted-headings"))
	// Should match headings with bold/italic formatting
	assertContains(t, out, "npm install")
}

func TestIndentedCode(t *testing.T) {
	out, _ := run(t, "--raw", filepath.Join(fixtures, "indented-code"))
	assertContains(t, out, "pip install old-project")
}

// ── Contrib mode ─────────────────────────────────────────────────────────

func TestContribMode(t *testing.T) {
	out, code := run(t, "contrib", "--raw", filepath.Join(fixtures, "node-express"))
	assertExitCode(t, code, 0)
	assertContains(t, out, "npm install")
}

func TestContribNotFound(t *testing.T) {
	_, code := run(t, "contrib", "--raw", filepath.Join(fixtures, "go-project"))
	assertExitCode(t, code, 1)
}

// ── JSON output ──────────────────────────────────────────────────────────

func TestJSONValid(t *testing.T) {
	out, code := run(t, "--json", filepath.Join(fixtures, "node-express"))
	assertExitCode(t, code, 0)
	var data map[string]interface{}
	if err := json.Unmarshal([]byte(out), &data); err != nil {
		t.Fatalf("invalid JSON: %v", err)
	}
}

func TestJSONContainsModes(t *testing.T) {
	out, _ := run(t, "--json", filepath.Join(fixtures, "node-express"))
	var data map[string]interface{}
	json.Unmarshal([]byte(out), &data)

	modes, ok := data["modes"].(map[string]interface{})
	if !ok {
		t.Fatal("missing 'modes' in JSON")
	}
	for _, m := range []string{"default", "install", "run", "test", "deploy", "all"} {
		if _, ok := modes[m]; !ok {
			t.Errorf("missing mode %q in JSON", m)
		}
	}
}

func TestJSONContainsNeeds(t *testing.T) {
	out, _ := run(t, "--json", filepath.Join(fixtures, "node-express"))
	var data map[string]interface{}
	json.Unmarshal([]byte(out), &data)

	if _, ok := data["needs"]; !ok {
		t.Error("missing 'needs' in JSON")
	}
}

func TestJSONContainsPlatforms(t *testing.T) {
	out, _ := run(t, "--json", filepath.Join(fixtures, "node-express"))
	var data map[string]interface{}
	json.Unmarshal([]byte(out), &data)

	if _, ok := data["platforms"]; !ok {
		t.Error("missing 'platforms' in JSON")
	}
}

// ── Platform detection ──────────────────────────────────────────────────────

func TestPlatformCloudflare(t *testing.T) {
	out, _ := run(t, "deploy", "--raw", filepath.Join(fixtures, "platform-cloudflare"))
	assertContains(t, out, "wrangler deploy")
}

func TestPlatformMulti(t *testing.T) {
	out, _ := run(t, "deploy", "--raw", filepath.Join(fixtures, "platform-multi"))
	// Should detect platforms from config files and commands
	assertContains(t, out, "deploy")
}

func TestPlatformDocker(t *testing.T) {
	out, _ := run(t, "deploy", "--raw", filepath.Join(fixtures, "platform-docker"))
	assertContains(t, out, "docker")
}

// ── Version ──────────────────────────────────────────────────────────────────

func TestVersion(t *testing.T) {
	out, code := run(t, "--version")
	assertExitCode(t, code, 0)
	assertContains(t, out, "hdi 0.24.0")
}
