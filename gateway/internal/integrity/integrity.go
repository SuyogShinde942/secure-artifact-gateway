package integrity

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"log/slog"
	"os"
	"strings"
)

func Check(filePath, expectedHex string) error {
	if len(expectedHex) != 64 {
		return fmt.Errorf("expected 64 hex characters, got %d", len(expectedHex))
	}

	file, err := os.Open(filePath)
	if err != nil {
		return fmt.Errorf("cannot open file: %w", err)
	}
	defer file.Close()

	hasher := sha256.New()
	if _, err := io.Copy(hasher, file); err != nil {
		return fmt.Errorf("error reading file: %w", err)
	}

	actual := hex.EncodeToString(hasher.Sum(nil))
	if !strings.EqualFold(actual, expectedHex) {
		return fmt.Errorf("hash mismatch — expected %s, got %s", strings.ToLower(expectedHex), actual)
	}
	return nil
}

func Run(filePath, hash string) error {
	if err := Check(filePath, hash); err != nil {
		return err
	}
	slog.Info("integrity check passed", "file", filePath)
	return nil
}
