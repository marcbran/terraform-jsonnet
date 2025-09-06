package tfjsonnet

import (
	"context"

	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/marcbran/terraform-jsonnet/internal"
)

func NewTerraform(ctx context.Context, dir string, variables map[string]string) (*tfexec.Terraform, error) {
	return internal.NewTerraform(ctx, dir, variables)
}
