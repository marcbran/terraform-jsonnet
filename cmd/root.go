package cmd

import (
	"fmt"
	"os"

	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/marcbran/terraform-jsonnet/internal"
	"github.com/spf13/cobra"
)

var Cmd = &cobra.Command{
	Use:   "terraform-jsonnet",
	Short: "",
	Long:  ``,

	DisableAutoGenTag: true,
}

func init() {
	Cmd.AddCommand(genCmd)
	Cmd.AddCommand(initCmd)
	Cmd.AddCommand(planCmd)
	Cmd.AddCommand(applyCmd)

	Cmd.PersistentFlags().String("tfj-dir", ".", "Module directory")
	Cmd.PersistentFlags().StringToString("tfj-var", nil, "Module variable in key=value format (can be used multiple times)")
}

func newTerraform(cmd *cobra.Command) (*tfexec.Terraform, error) {
	dir, err := cmd.Flags().GetString("tfj-dir")
	if err != nil {
		return nil, fmt.Errorf("failed to get dir flag: %w", err)
	}
	variables, err := cmd.Flags().GetStringToString("tfj-var")
	if err != nil {
		return nil, fmt.Errorf("failed to get variable flags: %w", err)
	}
	tf, err := internal.NewTerraform(cmd.Context(), dir, variables)
	if err != nil {
		return nil, err
	}
	tf.SetStdout(os.Stdout)
	tf.SetStderr(os.Stderr)
	return tf, nil
}

func Execute() {
	if err := Cmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
}
