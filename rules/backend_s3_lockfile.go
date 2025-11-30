package rules

import (
    "github.com/hashicorp/hcl/v2/hclsyntax"
    "github.com/terraform-linters/tflint-plugin-sdk/hclext"
    "github.com/terraform-linters/tflint-plugin-sdk/tflint"
)

type BackendS3LockfileRule struct {
    tflint.DefaultRule
}

func NewBackendS3LockfileRule() *BackendS3LockfileRule {
    return &BackendS3LockfileRule{}
}

func (r *BackendS3LockfileRule) Name() string {
    return "backend_s3_lockfile"
}

func (r *BackendS3LockfileRule) Enabled() bool {
    return true
}

func (r *BackendS3LockfileRule) Severity() tflint.Severity {
    return tflint.ERROR
}

func (r *BackendS3LockfileRule) Check(runner tflint.Runner) error {
    // Describe the structure we care about:
    schema := &hclext.BodySchema{
        Blocks: []hclext.BlockSchema{
            {
                Type: "terraform",
                Body: &hclext.BodySchema{
                    Blocks: []hclext.BlockSchema{
                        {
                            Type:       "backend",
                            LabelNames: []string{"type"},
                            Body: &hclext.BodySchema{
                                Attributes: []hclext.AttributeSchema{
                                    {Name: "use_lockfile"},
                                    {Name: "dynamodb_table"},
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    content, err := runner.GetModuleContent(schema, &tflint.GetModuleContentOption{
        ModuleCtx: tflint.RootModuleCtxType,
    })
    if err != nil {
        return err
    }

    for _, terraformBlock := range content.Blocks {
        for _, backendBlock := range terraformBlock.Body.Blocks {
            // Filter for S3 backend only
            if len(backendBlock.Labels) == 0 || backendBlock.Labels[0] != "s3" {
                continue
            }

            useLockAttr := backendBlock.Body.Attributes["use_lockfile"]
            dynamoAttr := backendBlock.Body.Attributes["dynamodb_table"]

            // 1) must have use_lockfile = true
            if useLockAttr == nil {
                runner.EmitIssue(
                    r,
                    `S3 backend must set "use_lockfile = true" (native S3 locking, requires Terraform >= v1.11.0)`,
                    backendBlock.DefRange,
                )
            } else {
                expr := useLockAttr.Expr
                if lit, ok := expr.(*hclsyntax.LiteralValueExpr); ok {
                    if !lit.Val.True() {
                        runner.EmitIssue(
                            r,
                            `"use_lockfile" must be true for S3 backend (requires Terraform >= v1.11.0)`,
                            useLockAttr.Range,
                        )
                    }
                } else {
                    // Non-literal (var/locals) – disallow for backend anyway
                    runner.EmitIssue(
                        r,
                        `"use_lockfile" in S3 backend must be a literal true (requires Terraform >= v1.11.0)`,
                        useLockAttr.Range,
                    )
                }
            }

            // 2) must NOT use DynamoDB locking
            if dynamoAttr != nil {
                runner.EmitIssue(
                    r,
                    `"dynamodb_table" locking is deprecated, use S3 native locking ("use_lockfile = true", requires Terraform >= v1.11.0) instead`,
                    dynamoAttr.Range,
                )
            }
        }
    }

    return nil
}