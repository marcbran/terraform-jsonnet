package cmd

import (
	"github.com/spf13/cobra"
)

var applyCmd = &cobra.Command{
	Use:   "apply",
	Short: "Creates or updates infrastructure",
	Long:  ``,

	DisableAutoGenTag: true,
	RunE: func(cmd *cobra.Command, args []string) error {
		cmd.SilenceUsage = true
		cmd.SilenceErrors = true
		tf, err := newTerraform(cmd)
		if err != nil {
			return err
		}
		err = tf.Apply(cmd.Context())
		if err != nil {
			return err
		}
		return nil
	},
}
