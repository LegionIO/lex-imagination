# frozen_string_literal: true

module Legion
  module Extensions
    module Imagination
      class Client
        include Runners::Imagination

        attr_reader :simulation_store

        def initialize(simulation_store: nil, **)
          @simulation_store = simulation_store || Helpers::SimulationStore.new
        end
      end
    end
  end
end
