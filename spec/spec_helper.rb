# frozen_string_literal: true

require 'byebug'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Code sample from rspec_api_documentation
# Adds to metadata :headers hash
def set_header(example, name, value)
  example.metadata[:headers] ||= {}
  example.metadata[:headers][name] = value
end
