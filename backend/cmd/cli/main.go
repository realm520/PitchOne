package main

import (
	"os"

	"github.com/pitchone/sportsbook/pkg/cli"
)

func main() {
	if err := cli.Execute(); err != nil {
		os.Exit(1)
	}
}
