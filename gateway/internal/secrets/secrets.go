package secrets

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"regexp"
	"sync"
)

const ruleWorkers = 5

type Finding struct {
	Line int
	Rule string
}

type compiledRule struct {
	name    string
	pattern *regexp.Regexp
}

func Scan(configPath, rulesPath string) ([]Finding, error) {
	rules, err := parseRules(rulesPath)
	if err != nil {
		return nil, err
	}
	return matchLines(configPath, rules)
}

func parseRules(path string) ([]compiledRule, error) {
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

	type job struct {
		idx     int
		name    string
		pattern string
	}

	rules := make([]compiledRule, len(parsed.Rules))
	errs := make([]error, len(parsed.Rules))
	jobs := make(chan job, len(parsed.Rules))

	var wg sync.WaitGroup
	for range ruleWorkers {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := range jobs {
				re, err := regexp.Compile(j.pattern)
				if err != nil {
					errs[j.idx] = fmt.Errorf("invalid pattern for rule %q: %w", j.name, err)
					continue
				}
				rules[j.idx] = compiledRule{name: j.name, pattern: re}
			}
		}()
	}

	for i, r := range parsed.Rules {
		jobs <- job{idx: i, name: r.Name, pattern: r.Pattern}
	}
	close(jobs)
	wg.Wait()

	for _, err := range errs {
		if err != nil {
			return nil, err
		}
	}
	return rules, nil
}

func matchLines(configPath string, rules []compiledRule) ([]Finding, error) {
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

func Enforce(configPath, rulesPath string) error {
	findings, err := Scan(configPath, rulesPath)
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
