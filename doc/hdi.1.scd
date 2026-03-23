hdi(1)

# NAME

hdi - extract setup, run, and test commands from a project README

# SYNOPSIS

*hdi* [_mode_] [_flags_] [_path_]

# DESCRIPTION

hdi ("How do I...") scans a project's README and extracts the commands you
need to install, run, test, or deploy it. It presents them as an interactive,
executable list in the terminal.

By default hdi looks for a README in the current directory. It recognises
README.md, readme.md, Readme.md, README.MD, README.rst, and readme.rst.

No dependencies, just Bash. Works on macOS and Linux.

# MODES

*install*, *setup*, *i*
	Show install and setup commands.

*run*, *start*, *r*
	Show run and start commands.

*test*, *t*
	Show test commands.

*deploy*, *d*
	Show deploy and release commands.

*all*, *a*
	Show all matched sections.

*check*, *c*
	Check if required tools referenced in commands are installed.

When no mode is given, hdi shows install, run, test, and deploy sections
together.

# FLAGS

*-h*, *--help*
	Show help and exit.

*-v*, *--version*
	Show version and exit.

*-f*, *--full*
	Include surrounding prose, not just commands.

*--raw*
	Plain markdown output with no colour. Good for piping.

*--json*
	Structured JSON output including all sections.

*--ni*, *--no-interactive*
	Print commands without the interactive picker.

# INTERACTIVE CONTROLS

When running in interactive mode (the default in a terminal):

*Up*/*Down* or *k*/*j*
	Navigate commands.

*Tab*/*Shift+Tab*
	Jump between sections.

*Enter*
	Execute the highlighted command.

*c*
	Copy highlighted command to clipboard.

*q* or *Esc*
	Quit.

# ENVIRONMENT

*NO_COLOR*
	When set to any value, disables colour output. See https://no-color.org.

*TERM*
	When set to _dumb_, disables colour output.

# EXIT STATUS

*0*
	Success.

*1*
	Error (no README found, no matching sections, unknown argument).

# EXAMPLES

Scan the current directory interactively:

	hdi

Show only install commands:

	hdi install

Show all commands for a specific project:

	hdi all /path/to/project

Copy commands to clipboard:

	hdi --raw | pbcopy

Check required tools are installed:

	hdi check

Parse a specific markdown file:

	hdi /path/to/file.md

# AUTHORS

Greg Annandale <https://github.com/grega>

# SEE ALSO

Project: https://github.com/grega/hdi

Website: https://hdi.gregdev.com
