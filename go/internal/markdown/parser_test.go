package markdown

import (
	"regexp"
	"testing"
)

func pattern(raw string) *regexp.Regexp {
	return regexp.MustCompile(`(?i)` + raw)
}

func TestATXHeadings(t *testing.T) {
	content := `# Project

## Installation

` + "```bash" + `
npm install
` + "```" + `

## Usage

` + "```bash" + `
npm start
` + "```" + `
`
	sections := ParseSections(content, pattern(`install`), "test.md")
	if len(sections) != 1 {
		t.Fatalf("expected 1 section, got %d", len(sections))
	}
	if sections[0].Title != "Installation" {
		t.Errorf("expected title 'Installation', got %q", sections[0].Title)
	}
	if sections[0].Source != "test.md" {
		t.Errorf("expected source 'test.md', got %q", sections[0].Source)
	}
}

func TestSetextHeadings(t *testing.T) {
	content := `Project
=======

Installation
------------

` + "```bash" + `
make install
` + "```" + `

Usage
-----

` + "```bash" + `
make run
` + "```" + `
`
	sections := ParseSections(content, pattern(`install`), "test.md")
	if len(sections) != 1 {
		t.Fatalf("expected 1 section, got %d", len(sections))
	}
	if sections[0].Title != "Installation" {
		t.Errorf("expected title 'Installation', got %q", sections[0].Title)
	}
}

func TestBoldPseudoHeadings(t *testing.T) {
	content := `**Installation**

` + "```bash" + `
pip install -r requirements.txt
` + "```" + `

**Running**

` + "```bash" + `
python main.py
` + "```" + `
`
	sections := ParseSections(content, pattern(`install`), "test.md")
	if len(sections) != 1 {
		t.Fatalf("expected 1 section, got %d", len(sections))
	}
	if sections[0].Title != "Installation" {
		t.Errorf("expected title 'Installation', got %q", sections[0].Title)
	}
}

func TestCodeFenceTracking(t *testing.T) {
	content := `## Installation

` + "```bash" + `
# This is a comment, not a heading
npm install
` + "```" + `
`
	sections := ParseSections(content, pattern(`install`), "test.md")
	if len(sections) != 1 {
		t.Fatalf("expected 1 section, got %d", len(sections))
	}
	// The comment inside the fence should be in the body, not treated as a heading
	if !contains(sections[0].Body, "# This is a comment") {
		t.Error("expected code fence comment to be in body")
	}
}

func TestStripFormatting(t *testing.T) {
	content := `## **Getting** *Started*

` + "```bash" + `
npm install
` + "```" + `
`
	sections := ParseSections(content, pattern(`getting.started`), "test.md")
	if len(sections) != 1 {
		t.Fatalf("expected 1 section, got %d", len(sections))
	}
	if sections[0].Title != "Getting Started" {
		t.Errorf("expected title 'Getting Started', got %q", sections[0].Title)
	}
}

func TestTrailingHashes(t *testing.T) {
	content := `## Installation ##

` + "```bash" + `
npm install
` + "```" + `
`
	sections := ParseSections(content, pattern(`install`), "test.md")
	if len(sections) != 1 {
		t.Fatalf("expected 1 section, got %d", len(sections))
	}
	if sections[0].Title != "Installation" {
		t.Errorf("expected title 'Installation', got %q", sections[0].Title)
	}
}

func TestMultipleSections(t *testing.T) {
	content := `## Installation

` + "```bash" + `
npm install
` + "```" + `

## Setup

` + "```bash" + `
npm run setup
` + "```" + `
`
	sections := ParseSections(content, pattern(`install(ation)?|setup`), "test.md")
	if len(sections) != 2 {
		t.Fatalf("expected 2 sections, got %d", len(sections))
	}
}

func TestNestedSectionSameMatch(t *testing.T) {
	content := `## Getting Started

Some intro text.

### Installation

` + "```bash" + `
npm install
` + "```" + `
`
	// Both "Getting Started" and "Installation" match the install pattern
	sections := ParseSections(content, pattern(`getting.started|install`), "test.md")
	if len(sections) != 2 {
		t.Fatalf("expected 2 sections (parent saved before child), got %d", len(sections))
	}
	if sections[0].Title != "Getting Started" {
		t.Errorf("expected first title 'Getting Started', got %q", sections[0].Title)
	}
	if sections[1].Title != "Installation" {
		t.Errorf("expected second title 'Installation', got %q", sections[1].Title)
	}
}

func TestNonMatchingSubheadingKeptInBody(t *testing.T) {
	content := `## Installation

### Prerequisites

` + "```bash" + `
brew install node
` + "```" + `

### Steps

` + "```bash" + `
npm install
` + "```" + `

## Usage

` + "```bash" + `
npm start
` + "```" + `
`
	// "Prerequisites" matches install pattern too, but "Steps" doesn't
	sections := ParseSections(content, pattern(`install|prerequisite`), "test.md")
	// Should get Installation (saved when Prerequisites arrives) and Prerequisites
	if len(sections) < 1 {
		t.Fatalf("expected at least 1 section, got %d", len(sections))
	}
}

func TestTildeFences(t *testing.T) {
	content := `## Installation

~~~bash
npm install
~~~
`
	sections := ParseSections(content, pattern(`install`), "test.md")
	if len(sections) != 1 {
		t.Fatalf("expected 1 section, got %d", len(sections))
	}
	if !contains(sections[0].Body, "npm install") {
		t.Error("expected body to contain 'npm install'")
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && containsStr(s, substr)
}

func containsStr(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
