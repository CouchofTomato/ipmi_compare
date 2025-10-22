# frozen_string_literal: true

require 'rake'

IpmiCompare::Application.load_tasks

RSpec.configure do |config|
  # Skip assets precompilcation if we exclude system specs.
  # For example, you can run all non-system tests via the following command:
  #
  #    rspec --tag ~type:system
  #
  # In this case, we don't need to precompile assets.
  next if config.filter.opposite.rules[:type] == 'system' || config.exclude_pattern.match?(%r{spec/system})

  config.before(:suite) do
    Rake::Task['assets:precompile'].invoke
  end
end
