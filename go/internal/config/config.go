package config

// Version is the current hdi version.
const Version = "0.24.0"

// Mode represents the operating mode of hdi.
type Mode string

const (
	ModeDefault Mode = "default"
	ModeInstall Mode = "install"
	ModeRun     Mode = "run"
	ModeTest    Mode = "test"
	ModeDeploy  Mode = "deploy"
	ModeAll     Mode = "all"
	ModeNeeds   Mode = "needs"
	ModeContrib Mode = "contrib"
)

// InteractiveMode controls whether the interactive picker is used.
type InteractiveMode string

const (
	InteractiveAuto InteractiveMode = "auto"
	InteractiveYes  InteractiveMode = "yes"
	InteractiveNo   InteractiveMode = "no"
)

// Config holds all resolved CLI options.
type Config struct {
	Mode        Mode
	Full        bool
	Raw         bool
	JSON        bool
	Interactive InteractiveMode
	Dir         string
	File        string
}
