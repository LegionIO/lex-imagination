# frozen_string_literal: true

module Legion
  module Logging
    module_function

    def debug(*); end

    def info(*); end

    def warn(*); end

    def error(*); end
  end

  module Extensions
    module Helpers; end
  end
end

require 'legion/extensions/imagination'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
