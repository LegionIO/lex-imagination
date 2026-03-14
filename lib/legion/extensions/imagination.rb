# frozen_string_literal: true

require 'securerandom'
require 'legion/extensions/imagination/version'
require 'legion/extensions/imagination/helpers/constants'
require 'legion/extensions/imagination/helpers/scenario'
require 'legion/extensions/imagination/helpers/simulation_store'
require 'legion/extensions/imagination/runners/imagination'
require 'legion/extensions/imagination/client'

module Legion
  module Extensions
    module Imagination
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
