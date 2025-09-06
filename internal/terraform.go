package internal

import (
	"context"
	"encoding/json"
	"fmt"
	"path/filepath"

	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/marcbran/jpoet/pkg/jpoet"
	"github.com/marcbran/terraform-jsonnet/internal/lib/imports"
)

func NewTerraform(ctx context.Context, dir string, variables map[string]string) (*tfexec.Terraform, error) {
	variablesJson, err := json.Marshal(variables)
	if err != nil {
		return nil, err
	}
	vendorDir := filepath.Join(dir, "vendor")
	mainFile := filepath.Join(dir, "main.tf.jsonnet")
	outputDir := filepath.Join(dir, ".terraform-jsonnet")
	err = jpoet.NewEval().
		FileImport([]string{vendorDir}).
		FSImport(lib).
		FSImport(imports.Fs).
		Serialize(false).
		TLACode("module", fmt.Sprintf("import '%s'", mainFile)).
		TLACode("var", string(variablesJson)).
		FileInput("./lib/gen.libsonnet").
		DirectoryOutput(outputDir).
		Eval()
	if err != nil {
		return nil, err
	}
	tf, err := tfexec.NewTerraform(outputDir, "terraform")
	if err != nil {
		return nil, err
	}
	return tf, nil
}
