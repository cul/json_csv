# frozen_string_literal: true

require 'bundler/gem_tasks'

Dir.glob('lib/tasks/**/*.rake').each do |rakefile|
  load rakefile
end

task ci: 'json_csv:ci'
task default: 'ci'
