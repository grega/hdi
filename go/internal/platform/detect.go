package platform

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/grega/hdi/internal/display"
)

// Platform represents a detected deployment platform.
type Platform struct {
	Name       string `json:"name"`
	Group      string `json:"group"`
	Confidence string `json:"confidence"` // "high" or "low"
}

// Detector accumulates platform detections and deduplicates by group.
type Detector struct {
	platforms []Platform
}

// Add adds or upgrades a platform detection. Deduplicates by group key:
// upgrades confidence to high if applicable, keeps the longer name.
func (d *Detector) Add(group, name, confidence string) {
	for i, p := range d.platforms {
		if p.Group == group {
			if confidence == "high" {
				d.platforms[i].Confidence = "high"
			}
			if len(name) > len(p.Name) {
				d.platforms[i].Name = name
			}
			return
		}
	}
	d.platforms = append(d.platforms, Platform{
		Name:       name,
		Group:      group,
		Confidence: confidence,
	})
}

// Platforms returns the detected platforms.
func (d *Detector) Platforms() []Platform {
	return d.platforms
}

// DetectFromFiles checks for config files in the directory (Layer 1, high confidence).
func (d *Detector) DetectFromFiles(dir string) {
	check := func(path string, group, name string) {
		if _, err := os.Stat(filepath.Join(dir, path)); err == nil {
			d.Add(group, name, "high")
		}
	}
	checkDir := func(path string, group, name string) {
		info, err := os.Stat(filepath.Join(dir, path))
		if err == nil && info.IsDir() {
			d.Add(group, name, "high")
		}
	}

	check("wrangler.toml", "cloudflare", "Cloudflare")
	check("wrangler.json", "cloudflare", "Cloudflare")
	check("vercel.json", "vercel", "Vercel")
	check("netlify.toml", "netlify", "Netlify")
	check("fly.toml", "fly", "Fly.io")
	check("Procfile", "heroku", "Heroku")
	check("render.yaml", "render", "Render")
	check("firebase.json", "firebase", "Firebase")
	check("amplify.yml", "amplify", "AWS Amplify")
	check("serverless.yml", "serverless", "Serverless")
	check("serverless.ts", "serverless", "Serverless")
	check("cdk.json", "awscdk", "AWS CDK")
	check("pulumi.yaml", "pulumi", "Pulumi")
	check("railway.json", "railway", "Railway")
	check("railway.toml", "railway", "Railway")
	check("Chart.yaml", "helm", "Helm")
	check("CNAME", "ghpages", "GitHub Pages")
	checkDir("k8s", "kubernetes", "Kubernetes")
	checkDir("kubernetes", "kubernetes", "Kubernetes")
	checkDir(".kamal", "kamal", "Kamal")
	check("config/deploy.yml", "kamal", "Kamal")

	// Terraform: glob for *.tf files
	matches, _ := filepath.Glob(filepath.Join(dir, "*.tf"))
	if len(matches) > 0 {
		d.Add("terraform", "Terraform", "high")
	}
}

// DetectFromCommands checks CLI tool names in commands (Layer 2, high confidence).
func (d *Detector) DetectFromCommands(dl *display.DisplayList) {
	for _, line := range dl.Lines {
		if line.Type != display.LineCommand {
			continue
		}
		tool := extractToolName(line.Command)
		if tool == "" {
			continue
		}
		switch tool {
		case "wrangler":
			d.Add("cloudflare", "Cloudflare", "high")
		case "vercel":
			d.Add("vercel", "Vercel", "high")
		case "netlify":
			d.Add("netlify", "Netlify", "high")
		case "flyctl", "fly":
			d.Add("fly", "Fly.io", "high")
		case "heroku":
			d.Add("heroku", "Heroku", "high")
		case "firebase":
			d.Add("firebase", "Firebase", "high")
		case "kubectl":
			d.Add("kubernetes", "Kubernetes", "high")
		case "helm":
			d.Add("helm", "Helm", "high")
		case "kamal":
			d.Add("kamal", "Kamal", "high")
		case "terraform":
			d.Add("terraform", "Terraform", "high")
		case "pulumi":
			d.Add("pulumi", "Pulumi", "high")
		case "railway":
			d.Add("railway", "Railway", "high")
		case "serverless", "sls":
			d.Add("serverless", "Serverless", "high")
		case "sam":
			d.Add("awssam", "AWS SAM", "high")
		case "cdk":
			d.Add("awscdk", "AWS CDK", "high")
		case "dokku":
			d.Add("dokku", "Dokku", "high")
		case "surge":
			d.Add("surge", "Surge", "high")
		case "docker", "docker-compose", "podman":
			d.Add("docker", "Docker", "high")
		}
	}
}

// DetectFromProse scans section bodies for platform mentions (Layer 3, low confidence).
func (d *Detector) DetectFromProse(bodies []string) {
	for _, body := range bodies {
		if body == "" {
			continue
		}
		lower := strings.ToLower(body)
		if strings.Contains(lower, "cloudflare pages") {
			d.Add("cloudflare", "Cloudflare Pages", "low")
		}
		if strings.Contains(lower, "cloudflare workers") {
			d.Add("cloudflare", "Cloudflare Workers", "low")
		}
		if strings.Contains(lower, "vercel") {
			d.Add("vercel", "Vercel", "low")
		}
		if strings.Contains(lower, "netlify") {
			d.Add("netlify", "Netlify", "low")
		}
		if strings.Contains(lower, "heroku") {
			d.Add("heroku", "Heroku", "low")
		}
		if strings.Contains(lower, "fly.io") {
			d.Add("fly", "Fly.io", "low")
		}
		if strings.Contains(lower, "github pages") {
			d.Add("ghpages", "GitHub Pages", "low")
		}
		if strings.Contains(lower, "dokku") {
			d.Add("dokku", "Dokku", "low")
		}
		if strings.Contains(lower, "railway") {
			d.Add("railway", "Railway", "low")
		}
		if strings.Contains(lower, "render") {
			d.Add("render", "Render", "low")
		}
		if strings.Contains(lower, "firebase") {
			d.Add("firebase", "Firebase", "low")
		}
		if strings.Contains(lower, "aws amplify") {
			d.Add("amplify", "AWS Amplify", "low")
		}
		if strings.Contains(lower, "digitalocean") {
			d.Add("digitalocean", "DigitalOcean", "low")
		}
		if strings.Contains(lower, "kamal") {
			d.Add("kamal", "Kamal", "low")
		}
		if strings.Contains(lower, "surge") {
			d.Add("surge", "Surge", "low")
		}
		if strings.Contains(lower, "docker") {
			d.Add("docker", "Docker", "low")
		}
	}
}

// FormatDisplay builds a display string from detected platforms.
// High-confidence names are plain; low-confidence get a "?" suffix.
func (d *Detector) FormatDisplay() string {
	if len(d.platforms) == 0 {
		return ""
	}
	var parts []string
	prevLow := false
	for i, p := range d.platforms {
		sep := ", "
		if i == 0 {
			sep = ""
		} else if prevLow {
			sep = " "
		}
		entry := p.Name
		if p.Confidence == "low" {
			entry += "?"
			prevLow = true
		} else {
			prevLow = false
		}
		parts = append(parts, sep+entry)
	}
	return strings.Join(parts, "")
}

// extractToolName extracts the CLI tool name from a command string.
// Strips leading env vars and sudo.
var reEnvVar = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*=[^\s]*\s*`)
var reCheckSkip = regexp.MustCompile(`^(cd|cp|mv|rm|mkdir|echo|export|source|cat|chmod|chown|ln|touch|ls|printf|trap|pwd|set|unset|eval|exec|exit|return|read|test|true|false|tee|head|tail|wc|sort|grep|xargs|find|tar|gzip|gunzip|sed|awk|tr|cut|diff|date|sleep|kill|whoami|env|which|man|less|more)$`)

func extractToolName(cmd string) string {
	// Strip leading env vars
	for reEnvVar.MatchString(cmd) {
		cmd = reEnvVar.ReplaceAllString(cmd, "")
	}
	cmd = strings.TrimLeft(cmd, " \t")

	// Strip sudo
	if strings.HasPrefix(cmd, "sudo ") {
		cmd = strings.TrimLeft(cmd[5:], " \t")
	}

	// First word
	tool := strings.Fields(cmd)
	if len(tool) == 0 {
		return ""
	}
	t := tool[0]

	// Skip paths, flags, empty, builtins, bracketed text, placeholders
	if t == "" || strings.HasPrefix(t, "-") || strings.Contains(t, "/") ||
		strings.HasPrefix(t, "[") || t == "..." || reCheckSkip.MatchString(t) {
		return ""
	}

	return t
}

// ExtractToolName is the exported version for use by other packages.
func ExtractToolName(cmd string) string {
	return extractToolName(cmd)
}
