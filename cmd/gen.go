package cmd

import (
	"github.com/spf13/cobra"
)

var genCmd = &cobra.Command{
	Use:   "gen",
	Short: "Generates Terraform JSON files from Jsonnet",
	Long:  ``,

	DisableAutoGenTag: true,
	RunE: func(cmd *cobra.Command, args []string) error {
		cmd.SilenceUsage = true
		cmd.SilenceErrors = true
		_, err := newTerraform(cmd)
		if err != nil {
			return err
		}
		return nil
	},
}
