package main

import (
	"github.com/terraform-linters/tflint-plugin-sdk/plugin"
	"github.com/terraform-linters/tflint-plugin-sdk/tflint"
	"github.com/IamEnTm/tflint-ruleset-backend/rules"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		RuleSet: &tflint.BuiltinRuleSet{
			Name:    "backend",
			Version: "0.1.0",
			Rules: []tflint.Rule{
				rules.NewS3BackendLockfileRule(),
			},
		},
	})
}
