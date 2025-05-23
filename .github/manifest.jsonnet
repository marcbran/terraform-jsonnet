local providers = [
  'registry.terraform.io/kreuzwerker/docker',
  'registry.terraform.io/hashicorp/archive',
  'registry.terraform.io/hashicorp/google',
  'registry.terraform.io/hashicorp/assert',
  'registry.terraform.io/hashicorp/tfmigrate',
  'registry.terraform.io/hashicorp/time',
  'registry.terraform.io/hashicorp/local',
  'registry.terraform.io/hashicorp/tfe',
  'registry.terraform.io/hashicorp/tls',
  'registry.terraform.io/hashicorp/null',
  'registry.terraform.io/hashicorp/azurerm',
  'registry.terraform.io/hashicorp/http',
  'registry.terraform.io/hashicorp/aws',
  'registry.terraform.io/hashicorp/external',
  'registry.terraform.io/hashicorp/random',
  'registry.terraform.io/hashicorp/kubernetes',
  'registry.terraform.io/hashicorp/dns',
  'registry.terraform.io/hashicorp/cloudinit',
  'registry.terraform.io/PagerDuty/pagerduty',
  'registry.terraform.io/logzio/logzio',
  'registry.terraform.io/grafana/grafana',
  'registry.terraform.io/integrations/github',
  'registry.terraform.io/DataDog/datadog',
  'registry.terraform.io/newrelic/newrelic',
  'registry.terraform.io/goauthentik/authentik',
  'registry.terraform.io/marcbran/jsonnet',
  'registry.terraform.io/marcbran/dolt',
];

local versions = {
  [std.split(step.uses, '@')[0]]: std.split(step.uses, '@')[1]
  for step in std.parseYaml(importstr './workflows/version.yml').jobs.version.steps
};

local uses(action) = {
  uses: '%s@%s' % [action, versions[action]],
};

local directory = {
  'dependabot.yml': {
    version: 2,
    updates: [
      {
        'package-ecosystem': 'gomod',
        directory: '/terraform-provider/cmd/pull-provider',
        schedule: { interval: 'daily' },
      },
      {
        'package-ecosystem': 'github-actions',
        directory: '/',
        schedule: { interval: 'daily' },
      },
    ] + [
      {
        'package-ecosystem': 'terraform',
        directory: '/terraform-provider/providers/%s' % provider,
        schedule: { interval: 'daily' },
      }
      for provider in providers
    ],
  },
  workflows: {
    local workflows = self,
    'test-terraform.yml': {
      name: 'Test terraform',
      on: {
        pull_request: {
          paths: ['terraform/**'],
        },
        workflow_dispatch: {},
      },
      permissions: {
        contents: 'read',
      },
      jobs: {
        test: {
          name: 'Test',
          'runs-on': 'ubuntu-latest',
          'timeout-minutes': 5,
          steps: [
            uses('actions/checkout'),
            uses('hashicorp/setup-terraform'),
            uses('extractions/setup-just'),
            uses('jaxxstorm/action-install-gh-release') {
              with: {
                repo: 'marcbran/jsonnet-kit',
              },
            },
            {
              name: 'Run tests',
              run: |||
                cd terraform
                just test
              |||,
            },
            {
              name: 'Run integration tests',
              run: |||
                cd terraform
                just it
              |||,
            },
          ],
        },
      },
    },
    'release-terraform.yml': {
      name: 'Release terraform',
      on: {
        push: {
          branches: ['main'],
          paths: ['terraform/**'],
        },
      },
      permissions: {
        contents: 'read',
      },
      jobs: {
        test: {
          name: 'Release',
          'runs-on': 'ubuntu-latest',
          'timeout-minutes': 5,
          steps: [
            uses('actions/checkout'),
            uses('hashicorp/setup-terraform'),
            uses('extractions/setup-just'),
            uses('jaxxstorm/action-install-gh-release') {
              with: {
                repo: 'marcbran/jsonnet-kit',
              },
            },
            {
              name: 'Set Git config',
              run: |||
                git config --global user.name "${{ github.actor }}"
                git config --global user.email "${{ github.actor_id }}+${{ github.actor }}@users.noreply.github.com"
              |||,
            },
            {
              name: 'Run release',
              run: |||
                cd terraform
                just release
              |||,
              env: {
                GIT_PRIVATE_KEY: '${{ secrets.GIT_PRIVATE_KEY }}',
              },
            },
          ],
        },
      },
    },
  } {
    ['test-%s.yml' % std.strReplace(std.strReplace(provider, '/', '-'), '.', '-')]: {
      name: 'Test %s' % provider,
      on: {
        pull_request: {
          paths: ['terraform-provider/providers/%s/**' % provider],
        },
        workflow_dispatch: {},
      },
      permissions: {
        contents: 'read',
      },
      jobs: {
        test: {
          name: 'Test',
          'runs-on': 'ubuntu-latest',
          'timeout-minutes': 5,
          steps: [
            uses('actions/checkout'),
            uses('hashicorp/setup-terraform'),
            uses('extractions/setup-just'),
            uses('actions/setup-go') {
              with: {
                'go-version-file': 'terraform-provider/cmd/pull-provider/go.mod',
                cache: true,
              },
            },
            uses('jaxxstorm/action-install-gh-release') {
              with: {
                repo: 'marcbran/jsonnet-kit',
              },
            },
            {
              name: 'Run tests',
              run: |||
                cd terraform-provider
                just gen-provider ./providers/%(provider)s
              ||| % { provider: provider },
            },
          ],
        },
      },
    }
    for provider in providers
  } {
    ['release-%s.yml' % std.strReplace(std.strReplace(provider, '/', '-'), '.', '-')]: {
      name: 'Release %s' % provider,
      on: {
        push: {
          branches: ['main'],
          paths: ['terraform-provider/providers/%s/**' % provider],
        },
      },
      permissions: {
        contents: 'read',
      },
      jobs: {
        release: {
          name: 'Release',
          'runs-on': 'ubuntu-latest',
          'timeout-minutes': 5,
          steps: [
            uses('actions/checkout'),
            uses('hashicorp/setup-terraform'),
            uses('extractions/setup-just'),
            uses('actions/setup-go') {
              with: {
                'go-version-file': 'terraform-provider/cmd/pull-provider/go.mod',
                cache: true,
              },
            },
            uses('jaxxstorm/action-install-gh-release') {
              with: {
                repo: 'marcbran/jsonnet-kit',
              },
            },
            uses('jaxxstorm/action-install-gh-release') {
              with: {
                repo: 'google/go-jsonnet',
              },
            },
            {
              name: 'Set Git config',
              run: |||
                git config --global user.name "${{ github.actor }}"
                git config --global user.email "${{ github.actor_id }}+${{ github.actor }}@users.noreply.github.com"
              |||,
            },
            {
              name: 'Release',
              run: |||
                cd terraform-provider
                just release-provider ./providers/%(provider)s
              ||| % { provider: provider },
              env: {
                GIT_PRIVATE_KEY: '${{ secrets.GIT_PRIVATE_KEY }}',
              },
            },
          ],
        },
      },
    }
    for provider in providers
  },
};

local manifestations = {
  '.yml'(data): std.manifestYamlDoc(data, indent_array_in_object=true, quote_keys=false),
};

{
  directory: directory,
  manifestations: manifestations,
}
