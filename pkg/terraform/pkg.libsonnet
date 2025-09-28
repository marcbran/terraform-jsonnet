local p = import 'pkg/main.libsonnet';

p.pkg({
  source: 'https://github.com/marcbran/terraform/pkg/terraform',
  repo: 'https://github.com/marcbran/jsonnet.git',
  branch: 'terraform',
  path: 'terraform',
  target: 'tf',
}, |||
  DSL for creating Terraform modules.
|||, {
  Format: p.desc('Format'),
  Variable: p.desc('Variable'),
  Output: p.desc('Output'),
  Local: p.desc('Local'),
  Module: p.desc('Module'),
  If: p.desc('If'),
  For: p.desc('For'),
})
