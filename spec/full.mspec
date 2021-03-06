load 'spec/default.mspec'

class MSpecScript
  # An ordered list of the directories containing specs to run
  # as the CI process.
  set :ci_files, [
    'spec/ruby/core',
    'spec/ruby/language',
    'spec/core',
    'spec/compiler',
    'spec/command_line',
    'spec/capi',
    'spec/ruby/library',
    'spec/library',

    'spec/build',

    # Disable until Kernel#require/load is rewritten
    '^spec/core/kernel/require',
    '^spec/core/kernel/load',
    '^spec/ruby/language/file',
    '^spec/ruby/language/line',
    '^spec/ruby/core/kernel/require',
    '^spec/ruby/core/kernel/load',

    # excluded because significantly broken
    '^spec/core/compiledmethod',
    '^spec/core/module',
    '^spec/capi/globals',
    '^spec/capi/module',
    '^spec/capi/proc',
    '^spec/capi/struct',

    '^spec/ruby/library/net/ftp',
    '^spec/ruby/library/net/http',
    '^spec/ruby/library/ping',
    '^spec/ruby/library/syslog',

    # 1.9 features
    '^spec/ruby/library/cmath',
    '^spec/ruby/library/continuation',
    '^spec/ruby/library/coverage',
    '^spec/ruby/library/fiber',
    '^spec/ruby/library/json',
    '^spec/ruby/library/minitest',
    '^spec/ruby/library/prime',
    '^spec/ruby/library/ripper',
    '^spec/ruby/library/rake',
    '^spec/ruby/library/rubygems',
  ]
end
