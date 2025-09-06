package cmd

import (
	"github.com/spf13/cobra"
)

var planCmd = &cobra.Command{
	Use:   "plan",
	Short: "Generates a speculative execution plan",
	Long:  ``,

	DisableAutoGenTag: true,
	RunE: func(cmd *cobra.Command, args []string) error {
		cmd.SilenceUsage = true
		cmd.SilenceErrors = true
		tf, err := newTerraform(cmd)
		if err != nil {
			return err
		}
		_, err = tf.Plan(cmd.Context())
		if err != nil {
			return err
		}
		return nil
	},
}
