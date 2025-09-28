local tf = import './main.libsonnet';
local jsonnet = import './tests/terraform-provider-jsonnet/main.libsonnet';
local Local = import './tests/terraform-provider-local/main.libsonnet';
local time = import './tests/vendor/terraform-provider-time/main.libsonnet';

local cfg(blocks) = std.manifestJson(blocks);

local localCfg(blocks) = std.manifestJson([
  {
    terraform: {
      required_providers: {
        'local': { source: 'registry.terraform.io/hashicorp/local', version: '2.5.2' },
      },
    },
  },
] + blocks);

local timeCfg(blocks) = std.manifestJson([
  {
    terraform: {
      required_providers: {
        time: { source: 'registry.terraform.io/hashicorp/time', version: '0.13.1' },
      },
    },
  },
] + blocks);

local localAliasCfg(blocks) = std.manifestJson([
  {
    terraform: {
      required_providers: {
        'local': { source: 'registry.terraform.io/hashicorp/local', version: '2.5.2' },
      },
    },
  },
  {
    provider: {
      'local': {
        alias: 'test',
      },
    },
  },
] + blocks);

local localJsonnetCfg(blocks) = std.manifestJson([
  {
    terraform: {
      required_providers: {
        jsonnet: { source: 'registry.terraform.io/marcbran/jsonnet', version: '0.4.0' },
        'local': { source: 'registry.terraform.io/hashicorp/local', version: '2.5.2' },
      },
    },
  },
] + blocks);

local formatTests = {
  name: 'format',
  tests: [
    {
      name: 'string',
      input:: [
        tf.Output('example', {
          value: tf.Format('Hello %s!', ['World']),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: 'Hello World!',
            },
          },
        },
      ]),
    },
    {
      name: 'function',
      input:: [
        tf.Output('example', {
          value: tf.Format('Hello %s!', [tf.jsonencode({ foo: 'bar' })]),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: 'Hello ${jsonencode({"foo":"bar"})}!',
            },
          },
        },
      ]),
    },
  ],
};

local variableTests = {
  name: 'variable',
  tests: [
    {
      name: 'default',
      input:: [
        tf.Variable('example', {
          default: 'hello',
        }),
      ],
      expected: cfg([
        {
          variable: {
            example: {
              default: 'hello',
            },
          },
        },
      ]),
    },
    {
      name: 'default',
      input:: [
        tf.Variable('example', {
          default: 'hello',
          type: 'string',
        }),
      ],
      expected: cfg([
        {
          variable: {
            example: {
              default: 'hello',
              type: 'string',
            },
          },
        },
      ]),
    },
  ],
};

local outputTests = {
  name: 'output',
  tests: [
    {
      name: 'string',
      input:: [
        tf.Output('example', {
          value: 'hello',
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: 'hello',
            },
          },
        },
      ]),
    },
    {
      name: 'reference',
      input::
        local example = tf.Variable('example', {
          default: 'hello',
        });
        [
          example,
          tf.Output('example2', {
            value: example,
          }),
        ],
      expected: cfg([
        {
          output: {
            example2: {
              value: '${var.example}',
            },
          },
        },
        {
          variable: {
            example: {
              default: 'hello',
            },
          },
        },
      ]),
    },
    {
      name: 'unlisted reference',
      input::
        local example = tf.Variable('example', {
          default: 'hello',
        });
        [
          tf.Output('example2', {
            value: example,
          }),
        ],
      expected: cfg([
        {
          output: {
            example2: {
              value: '${var.example}',
            },
          },
        },
        {
          variable: {
            example: {
              default: 'hello',
            },
          },
        },
      ]),
    },
  ],
};

local localTests = {
  name: 'local',
  tests: [
    {
      name: 'string',
      input:: [
        tf.Local('example', 'hello'),
      ],
      expected: cfg([
        {
          locals: {
            example: 'hello',
          },
        },
      ]),
    },
    {
      name: 'reference',
      input::
        local example = tf.Local('example', 'hello');
        [
          example,
          tf.Local('example2', example),
        ],
      expected: cfg([
        {
          locals: {
            example: 'hello',
          },
        },
        {
          locals: {
            example2: '${local.example}',
          },
        },
      ]),
    },
    {
      name: 'unlisted reference',
      input::
        local example = tf.Local('example', 'hello');
        [
          tf.Local('example2', example),
        ],
      expected: cfg([
        {
          locals: {
            example: 'hello',
          },
        },
        {
          locals: {
            example2: '${local.example}',
          },
        },
      ]),
    },
    {
      name: 'object reference',
      input::
        {
          example: tf.Local('example', 'hello'),
          example2: tf.Local('example2', self.example),
        },
      expected: cfg([
        {
          locals: {
            example: 'hello',
          },
        },
        {
          locals: {
            example2: '${local.example}',
          },
        },
      ]),
    },
    {
      name: 'resource',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          example,
          tf.Local('example2', example),
        ],
      expected: localCfg([
        {
          locals: {
            example2: '${local_file.example_txt}',
          },
        },
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
      ]),
    },
  ],
};

local moduleTests = {
  name: 'output',
  tests: [
    {
      name: 'string',
      it: false,
      input:: [
        tf.Module('example', {
          source: '../tests/example',
        }),
      ],
      expected: cfg([
        {
          module: {
            example: {
              source: '../tests/example',
            },
          },
        },
      ]),
    },
  ],
};

local importTests = {
  name: 'import',
  tests: [
    {
      name: 'string',
      it: false,
      input::
        local example = time.resource.static('example', {});
        [
          tf.Import('example', {
            to: example,
            id: '2006-01-02T15:04:05Z',
          }),
        ],
      expected: timeCfg([
        {
          'import': {
            id: '2006-01-02T15:04:05Z',
            to: 'time_static.example',
          },
        },
        {
          resource: {
            time_static: {
              example: {

              },
            },
          },
        },
      ]),
    },
  ],
};

local functionTests = {
  name: 'function',
  tests: [
    {
      name: 'string',
      input:: [
        tf.Output('example', {
          value: tf.trimprefix('helloworld', 'hello'),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${trimprefix("helloworld", "hello")}',
            },
          },
        },
      ]),
    },
    {
      name: 'array',
      input:: [
        tf.Output('example', {
          value: tf.jsonencode([{ foo: 'bar' }]),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${jsonencode([{"foo":"bar"}])}',
            },
          },
        },
      ]),
    },
    {
      name: 'object',
      input:: [
        tf.Output('example', {
          value: tf.jsonencode({ foo: 'bar' }),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${jsonencode({"foo":"bar"})}',
            },
          },
        },
      ]),
    },
    {
      name: 'nested',
      input:: [
        tf.Output('example', {
          value: tf.trimprefix(tf.trimsuffix('helloworld', 'world'), 'hello'),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${trimprefix(trimsuffix("helloworld", "world"), "hello")}',
            },
          },
        },
      ]),
    },
    {
      name: 'provider',
      input:: [
        tf.Output('example', {
          value: Local.func.direxists('/opt/terraform'),
        }),
      ],
      expected: localCfg([
        {
          output: {
            example: {
              value: '${provider::local::direxists("/opt/terraform")}',
            },
          },
        },
      ]),
    },
    {
      name: 'multiline',
      input:: [
        tf.Output('example', {
          value: tf.trimprefix('helloworld\ntest', 'hello'),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${trimprefix("helloworld\\ntest", "hello")}',
            },
          },
        },
      ]),
    },
    {
      name: 'rest parameters',
      input:: [
        tf.Output('example', {
          value: tf.concat([['a', 'b'], ['c', 'd']]),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${concat(["a","b"], ["c","d"])}',
            },
          },
        },
      ]),
    },
  ],
};

local ifTests = {
  name: 'if',
  tests: [
    {
      name: 'simple',
      input:: [
        tf.Output('example', {
          value: tf.If(tf.eq(true, false)).Then('a').Else('b'),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${true == false ? "a" : "b"}',
            },
          },
        },
      ]),
    },
    {
      name: 'variable',
      input::
        local var = tf.Local('var', false);
        [
          var,
          tf.Output('example', {
            value: tf.If(tf.eq(true, var)).Then('a').Else('b'),
          }),
        ],
      expected: cfg([
        {
          locals: {
            var: false,
          },
        },
        {
          output: {
            example: {
              value: '${true == local.var ? "a" : "b"}',
            },
          },
        },
      ]),
    },
    {
      name: 'inline variable',
      input::
        local var = tf.Local('var', false);
        [
          tf.Output('example', {
            value: tf.If(tf.eq(true, var)).Then('a').Else('b'),
          }),
        ],
      expected: cfg([
        {
          locals: {
            var: false,
          },
        },
        {
          output: {
            example: {
              value: '${true == local.var ? "a" : "b"}',
            },
          },
        },
      ]),
    },
  ],
};

local forTests = {
  name: 'for',
  tests: [
    {
      name: 'list',
      input:: [
        tf.Output('example', {
          value: tf.For('s').In(['a', 'b', 'c']).List(function(s) s),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${[for s in ["a","b","c"]: s]}',
            },
          },
        },
      ]),
    },
    {
      name: 'list variable',
      input::
        local var = tf.Local('var', [1, 2, 3]);
        [
          var,
          tf.Output('example', {
            value: tf.For('s').In(var).List(function(s) s),
          }),
        ],
      expected: cfg([
        {
          locals: {
            var: [1, 2, 3],
          },
        },
        {
          output: {
            example: {
              value: '${[for s in local.var: s]}',
            },
          },
        },
      ]),
    },
    {
      name: 'list inline variable',
      input::
        local var = tf.Local('var', [1, 2, 3]);
        [
          tf.Output('example', {
            value: tf.For('s').In(var).List(function(s) s),
          }),
        ],
      expected: cfg([
        {
          locals: {
            var: [1, 2, 3],
          },
        },
        {
          output: {
            example: {
              value: '${[for s in local.var: s]}',
            },
          },
        },
      ]),
    },
    {
      name: 'list function',
      input:: [
        tf.Output('example', {
          value: tf.For('s').In(['a', 'b', 'c']).List(function(s) tf.upper(s)),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${[for s in ["a","b","c"]: upper(s)]}',
            },
          },
        },
      ]),
    },
    {
      name: 'list index',
      input:: [
        tf.Output('example', {
          value: tf.For('i', 's').In([1, 2, 3]).List(function(i, s) { index: i, value: s }),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${[for i, s in [1,2,3]: {"index":i,"value":s}]}',
            },
          },
        },
      ]),
    },
    {
      name: 'map',
      input:: [
        tf.Output('example', {
          value: tf.For('s').In(['a', 'b', 'c']).Map(function(s) [s, s]),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${{for s in ["a","b","c"]: s => s }}',
            },
          },
        },
      ]),
    },
    {
      name: 'map to map',
      input:: [
        tf.Output('example', {
          value: tf.For('k', 'v').In({ foo: 'a', bar: 'b' }).Map(function(k, v) [v, k]),
        }),
      ],
      expected: cfg([
        {
          output: {
            example: {
              value: '${{for k, v in {"bar":"b","foo":"a"}: v => k }}',
            },
          },
        },
      ]),
    },
  ],
};

local providerTests = {
  name: 'resource',
  tests: [
    {
      name: 'alias',
      input::
        local localAlias = Local.withConfiguration('test', {});
        [
          localAlias.resource.file('example_txt', {
            filename: 'example.txt',
            content: 'hello',
          }),
        ],
      expected: localAliasCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                provider: 'local.test',
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
      ]),
    },
    {
      name: 'variable',
      input::
        local localAlias = Local.withConfiguration('test', {
          token: tf.Variable('token', {
            default: 'asdf',
          }),
        });
        [
          localAlias.resource.file('example_txt', {
            filename: 'example.txt',
            content: 'hello',
          }),
        ],
      expected: localAliasCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                provider: 'local.test',
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
        {
          variable: {
            token: {
              default: 'asdf',
            },
          },
        },
      ]),
    },
    {
      name: 'provider function',
      input::
        [
          Local.resource.file('example_txt', {
            filename: 'example.txt',
            content: jsonnet.func.evaluate('{}', { jpaths: [] }),
          }),
        ],
      expected: localJsonnetCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                content: '${provider::jsonnet::evaluate("{}", {"jpaths":[]})}',
                filename: 'example.txt',
              },
            },
          },
        },
      ]),
    },
  ],
};

local resourceTests = {
  name: 'resource',
  tests: [
    {
      name: 'reference',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          example,
          tf.Output('example', {
            value: example,
            sensitive: true,
          }),
        ],
      expected: localCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${local_file.example_txt}',
              sensitive: true,
            },
          },
        },
      ]),
    },
    {
      name: 'inline reference',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          tf.Output('example', {
            value: example,
            sensitive: true,
          }),
        ],
      expected: localCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${local_file.example_txt}',
              sensitive: true,
            },
          },
        },
      ]),
    },
    {
      name: 'field reference',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          example,
          tf.Output('example', {
            value: example.content,
            sensitive: true,
          }),
        ],
      expected: localCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${local_file.example_txt.content}',
              sensitive: true,
            },
          },
        },
      ]),
    },
    {
      name: 'inline field reference',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          tf.Output('example', {
            value: example.content,
            sensitive: true,
          }),
        ],
      expected: localCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${local_file.example_txt.content}',
              sensitive: true,
            },
          },
        },
      ]),
    },
    {
      name: 'function call',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          example,
          tf.Output('example', {
            value: tf.jsonencode(example),
            sensitive: true,
          }),
        ],
      expected: localCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${jsonencode(local_file.example_txt)}',
              sensitive: true,
            },
          },
        },
      ]),
    },
    {
      name: 'inline function call',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          tf.Output('example', {
            value: tf.jsonencode(example),
            sensitive: true,
          }),
        ],
      expected: localCfg([
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${jsonencode(local_file.example_txt)}',
              sensitive: true,
            },
          },
        },
      ]),
    },
    {
      name: 'inbound reference',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          example,
          Local.resource.file('example_2_txt', {
            filename: 'example2.txt',
            content: example.content,
          }),
        ],
      expected: localCfg([
        {
          resource: {
            local_file: {
              example_2_txt: {
                content: '${local_file.example_txt.content}',
                filename: 'example2.txt',
              },
            },
          },
        },
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
      ]),
    },
    {
      name: 'inline inbound reference',
      input::
        local example = Local.resource.file('example_txt', {
          filename: 'example.txt',
          content: 'hello',
        });
        [
          Local.resource.file('example_2_txt', {
            filename: 'example2.txt',
            content: example.content,
          }),
        ],
      expected: localCfg([
        {
          resource: {
            local_file: {
              example_2_txt: {
                content: '${local_file.example_txt.content}',
                filename: 'example2.txt',
              },
            },
          },
        },
        {
          resource: {
            local_file: {
              example_txt: {
                content: 'hello',
                filename: 'example.txt',
              },
            },
          },
        },
      ]),
    },
  ],
};

local dataTests = {
  name: 'data',
  tests: [
    {
      name: 'reference',
      input::
        local example = Local.data.file('example_txt', {
          filename: '../tests/example/example.txt',
        });
        [
          example,
          tf.Output('example', {
            value: example,
          }),
        ],
      expected: localCfg([
        {
          data: {
            local_file: {
              example_txt: {
                filename: '../tests/example/example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${data.local_file.example_txt}',
            },
          },
        },
      ]),
    },
    {
      name: 'inline reference',
      input::
        local example = Local.data.file('example_txt', {
          filename: '../tests/example/example.txt',
        });
        [
          tf.Output('example', {
            value: example,
          }),
        ],
      expected: localCfg([
        {
          data: {
            local_file: {
              example_txt: {
                filename: '../tests/example/example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${data.local_file.example_txt}',
            },
          },
        },
      ]),
    },
    {
      name: 'field reference',
      input::
        local example = Local.data.file('example_txt', {
          filename: '../tests/example/example.txt',
        });
        [
          example,
          tf.Output('example', {
            value: example.content,
          }),
        ],
      expected: localCfg([
        {
          data: {
            local_file: {
              example_txt: {
                filename: '../tests/example/example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${data.local_file.example_txt.content}',
            },
          },
        },
      ]),
    },
    {
      name: 'inline field reference',
      input::
        local example = Local.data.file('example_txt', {
          filename: '../tests/example/example.txt',
        });
        [
          tf.Output('example', {
            value: example.content,
          }),
        ],
      expected: localCfg([
        {
          data: {
            local_file: {
              example_txt: {
                filename: '../tests/example/example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${data.local_file.example_txt.content}',
            },
          },
        },
      ]),
    },
    {
      name: 'function call',
      input::
        local example = Local.data.file('example_txt', {
          filename: '../tests/example/example.txt',
        });
        [
          example,
          tf.Output('example', {
            value: tf.jsonencode(example),
          }),
        ],
      expected: localCfg([
        {
          data: {
            local_file: {
              example_txt: {
                filename: '../tests/example/example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${jsonencode(data.local_file.example_txt)}',
            },
          },
        },
      ]),
    },
    {
      name: 'inline function call',
      input::
        local example = Local.data.file('example_txt', {
          filename: '../tests/example/example.txt',
        });
        [
          tf.Output('example', {
            value: tf.jsonencode(example),
          }),
        ],
      expected: localCfg([
        {
          data: {
            local_file: {
              example_txt: {
                filename: '../tests/example/example.txt',
              },
            },
          },
        },
        {
          output: {
            example: {
              value: '${jsonencode(data.local_file.example_txt)}',
            },
          },
        },
      ]),
    },
    {
      name: 'inbound reference',
      input::
        local example = Local.data.file('example_txt', {
          filename: '../tests/example/example.txt',
        });
        [
          example,
          Local.data.file('example_2_txt', {
            filename: example.filename,
          }),
        ],
      expected: localCfg([
        {
          data: {
            local_file: {
              example_2_txt: {
                filename: '${data.local_file.example_txt.filename}',
              },
            },
          },
        },
        {
          data: {
            local_file: {
              example_txt: {
                filename: '../tests/example/example.txt',
              },
            },
          },
        },
      ]),
    },
    {
      name: 'inline inbound reference',
      input::
        local example = Local.data.file('example_txt', {
          filename: '../tests/example/example.txt',
        });
        [
          Local.data.file('example_2_txt', {
            filename: example.filename,
          }),
        ],
      expected: localCfg([
        {
          data: {
            local_file: {
              example_2_txt: {
                filename: '${data.local_file.example_txt.filename}',
              },
            },
          },
        },
        {
          data: {
            local_file: {
              example_txt: {
                filename: '../tests/example/example.txt',
              },
            },
          },
        },
      ]),
    },
  ],
};

{
  output(input): std.manifestJson(tf.Cfg(input)),
  tests: [
    formatTests,
    variableTests,
    outputTests,
    localTests,
    moduleTests,
    importTests,
    functionTests,
    ifTests,
    forTests,
    providerTests,
    resourceTests,
    dataTests,
  ],
}
