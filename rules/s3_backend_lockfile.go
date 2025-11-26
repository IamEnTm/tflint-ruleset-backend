package rules

import (
    "github.com/hashicorp/hcl/v2/hclsyntax"
    "github.com/terraform-linters/tflint-plugin-sdk/hclext"
    "github.com/terraform-linters/tflint-plugin-sdk/tflint"
)

type S3BackendLockfileRule struct {
    tflint.DefaultRule
}

func NewS3BackendLockfileRule() *S3BackendLockfileRule {
    return &S3BackendLockfileRule{}
}

func (r *S3BackendLockfileRule) Name() string {
    return "s3_backend_lockfile"
}

func (r *S3BackendLockfileRule) Enabled() bool {
    return true
}

func (r *S3BackendLockfileRule) Severity() tflint.Severity {
    return tflint.ERROR
}

func (r *S3BackendLockfileRule) Check(runner tflint.Runner) error {
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
                    `S3 backend must set "use_lockfile = true" (native S3 locking)`,
                    backendBlock.DefRange,
                )
            } else {
                expr := useLockAttr.Expr
                if lit, ok := expr.(*hclsyntax.LiteralValueExpr); ok {
                    if !lit.Val.True() {
                        runner.EmitIssue(
                            r,
                            `"use_lockfile" must be true for S3 backend`,
                            useLockAttr.Range,
                        )
                    }
                } else {
                    // Non-literal (var/locals) – disallow for backend anyway
                    runner.EmitIssue(
                        r,
                        `"use_lockfile" in S3 backend must be a literal true`,
                        useLockAttr.Range,
                    )
                }
            }

            // 2) must NOT use DynamoDB locking
            if dynamoAttr != nil {
                runner.EmitIssue(
                    r,
                    `"dynamodb_table" locking is deprecated, use S3 native locking (use_lockfile) instead`,
                    dynamoAttr.Range,
                )
            }
        }
    }

    return nil
}