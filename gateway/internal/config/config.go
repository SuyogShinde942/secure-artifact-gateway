package config

import (
	"errors"
	"flag"
)

type Config struct {
	FilePath   string
	SHA256     string
	ConfigPath string
	RulesPath  string
}

func Parse() *Config {
	c := &Config{}
	flag.StringVar(&c.FilePath,   "file",   "",           "Path to the artifact file")
	flag.StringVar(&c.SHA256,     "sha256", "",           "Expected SHA-256 hash")
	flag.StringVar(&c.ConfigPath, "config", "",           "Path to the config file to scan")
	flag.StringVar(&c.RulesPath,  "rules",  "rules.json", "Path to the rules file")
	flag.Parse()
	return c
}

func (c *Config) Validate() error {
	if c.FilePath == "" && c.SHA256 == "" && c.ConfigPath == "" {
		return errors.New("provide --file/--sha256 for integrity check, --config for secret scan, or both")
	}
	if c.FilePath != "" && c.SHA256 == "" {
		return errors.New("--sha256 is required when --file is set")
	}
	if c.SHA256 != "" && c.FilePath == "" {
		return errors.New("--file is required when --sha256 is set")
	}
	return nil
}
