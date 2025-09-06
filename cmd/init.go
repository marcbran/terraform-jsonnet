package cmd

import (
	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize a new or existing Terraform working directory",
	Long:  ``,

	DisableAutoGenTag: true,
	RunE: func(cmd *cobra.Command, args []string) error {
		cmd.SilenceUsage = true
		cmd.SilenceErrors = true
		tf, err := newTerraform(cmd)
		if err != nil {
			return err
		}
		err = tf.Init(cmd.Context())
		if err != nil {
			return err
		}
		return nil
	},
}
