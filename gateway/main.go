package main

import (
	"flag"
	"log/slog"
	"os"

	"gateway/internal/config"
	"gateway/internal/integrity"
	"gateway/internal/secrets"
)

func main() {
	cfg := config.Parse()
	if err := cfg.Validate(); err != nil {
		slog.Error(err.Error())
		flag.Usage()
		os.Exit(1)
	}

	if cfg.FilePath != "" {
		if err := integrity.Run(cfg.FilePath, cfg.SHA256); err != nil {
			slog.Error("integrity check failed", "error", err)
			os.Exit(1)
		}
	}
	if cfg.ConfigPath != "" {
		if err := secrets.Run(cfg.ConfigPath, cfg.RulesPath); err != nil {
			slog.Error("secrets scan failed", "error", err)
			os.Exit(1)
		}
	}
}
