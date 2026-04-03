package readme

import (
	"os"
	"path/filepath"
	"strings"
)

// readmeCandidates lists README filenames in priority order.
var readmeCandidates = []string{
	"README.md", "readme.md", "Readme.md",
	"README.MD", "README.rst", "readme.rst",
}

// contribCandidates lists contributor doc filenames to search for.
var contribCandidates = []string{
	"CONTRIBUTING.md", "contributing.md", "Contributing.md",
	"DEVELOPMENT.md", "development.md", "Development.md",
	"DEVELOPERS.md", "developers.md", "Developers.md",
	"HACKING.md", "hacking.md",
}

// FindREADME searches for a README file in the given directory.
// Returns the path to the first found README, or empty string if none found.
func FindREADME(dir string) string {
	for _, name := range readmeCandidates {
		path := filepath.Join(dir, name)
		if info, err := os.Stat(path); err == nil && !info.IsDir() {
			return path
		}
	}
	return ""
}

// FindContribDocs searches for contributor/development documentation files
// in the given directory. Returns deduplicated list of paths (handles
// case-insensitive filesystems where multiple candidates may resolve to
// the same file).
func FindContribDocs(dir string) []string {
	var files []string
	seen := make(map[string]bool)

	for _, name := range contribCandidates {
		path := filepath.Join(dir, name)
		if _, err := os.Stat(path); err != nil {
			continue
		}
		// Deduplicate via realpath (case-insensitive filesystems)
		real, err := filepath.EvalSymlinks(path)
		if err != nil {
			real = path
		}
		// Normalize to absolute path for dedup
		abs, err := filepath.Abs(real)
		if err != nil {
			abs = real
		}
		// On case-insensitive filesystems (macOS), EvalSymlinks may not
		// normalize case. Use lowercase comparison as fallback.
		key := strings.ToLower(abs)
		if seen[key] {
			continue
		}
		seen[key] = true
		files = append(files, abs)
	}
	return files
}
