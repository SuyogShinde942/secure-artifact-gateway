package secrets

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"regexp"
)

type Finding struct {
	Line int
	Rule string
}

type compiledRule struct {
	name    string
	pattern *regexp.Regexp
}

func Check(configPath, rulesPath string) ([]Finding, error) {
	rules, err := loadRules(rulesPath)
	if err != nil {
		return nil, err
	}
	return scan(configPath, rules)
}

func loadRules(path string) ([]compiledRule, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("cannot read rules file: %w", err)
	}

	var parsed struct {
		Rules []struct {
			Name    string `json:"name"`
			Pattern string `json:"pattern"`
		} `json:"rules"`
	}
	if err := json.Unmarshal(data, &parsed); err != nil {
		return nil, fmt.Errorf("invalid JSON in rules file: %w", err)
	}

	var rules []compiledRule
	for _, r := range parsed.Rules {
		re, err := regexp.Compile(r.Pattern)
		if err != nil {
			return nil, fmt.Errorf("invalid pattern for rule %q: %w", r.Name, err)
		}
		rules = append(rules, compiledRule{name: r.Name, pattern: re})
	}
	return rules, nil
}

func scan(configPath string, rules []compiledRule) ([]Finding, error) {
	file, err := os.Open(configPath)
	if err != nil {
		return nil, fmt.Errorf("cannot open config: %w", err)
	}
	defer file.Close()

	var findings []Finding
	sc := bufio.NewScanner(file)
	lineNum := 0

	for sc.Scan() {
		lineNum++
		line := sc.Text()

		for _, r := range rules {
			if r.pattern.MatchString(line) {
				findings = append(findings, Finding{Line: lineNum, Rule: r.name})
				break
			}
		}
	}
	return findings, sc.Err()
}

func Run(configPath, rulesPath string) error {
	findings, err := Check(configPath, rulesPath)
	if err != nil {
		return err
	}
	if len(findings) > 0 {
		for _, f := range findings {
			slog.Warn("secret detected", "rule", f.Rule, "line", f.Line)
		}
		return fmt.Errorf("secrets detected in %s", configPath)
	}
	slog.Info("no secrets found", "config", configPath)
	return nil
}
