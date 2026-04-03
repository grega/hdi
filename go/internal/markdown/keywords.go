package markdown

import (
	"regexp"

	"github.com/grega/hdi/internal/config"
)

var (
	kwInstall = `prerequisite(s)?|require(ments)?|depend(encies)?|install(ing|ation)?|setup|set[. _-]up|getting[. _-]started|quick[. _-]start|quickstart|how[. _-]to|docker|migration|database[. _-]setup`
	kwRun     = `^usage|run(ning)?|start(ing)?|dev|develop(ment|ing)?|dev[. _-]server|launch(ing)?|command|scripts|makefile|make[. _-]targets`
	kwTest    = `test(s|ing)?`
	kwDeploy  = `deploy(ment|ing)?|ship(ping)?|release|publish(ing)?|provision(ing)?|rollout|ci[/-]?cd|pipeline`
	kwExtra   = `build(ing)?|compil(ation|ing)|config(uration|uring)?|environment|deploy(ment|ing)?`
)

// PatternForMode returns the compiled case-insensitive regex used to match
// section headings for the given mode.
func PatternForMode(mode config.Mode) *regexp.Regexp {
	var raw string
	switch mode {
	case config.ModeInstall:
		raw = `(` + kwInstall + `)`
	case config.ModeRun:
		raw = `(` + kwRun + `)`
	case config.ModeTest:
		raw = `(` + kwTest + `)`
	case config.ModeDeploy:
		raw = `(` + kwDeploy + `)`
	default:
		// all, needs, contrib, default → match everything
		raw = `(` + kwInstall + `|` + kwRun + `|` + kwTest + `|` + kwDeploy + `|` + kwExtra + `)`
	}
	return regexp.MustCompile(`(?i)` + raw)
}
