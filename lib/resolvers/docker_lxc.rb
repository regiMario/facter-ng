# frozen_string_literal: true

module Facter
  module Resolvers
    class DockerLxc < BaseResolver
      # :name
      # :version
      # :codename

      @semaphore = Mutex.new
      @fact_list ||= {}

      class << self
        private

        def post_resolve(fact_name)
          @fact_list.fetch(fact_name) { read_cgroup(fact_name) }
        end

        def read_cgroup(_fact_name)
          vm = nil
          info = nil
          output = Util::FileHelper.safe_readlines('/proc/1/cgroup', nil)
          return unless output

          output_docker = output.find { |line| info ||= %r{docker/(.+)}.match(line) }
          output_lxc = output.find { |line| %r{/lxc}.match?(line) }

          vm = 'docker' if output_docker
          vm = 'lxc' if output_lxc
          info = info[1] ? { 'id' => info[1] } : {}
          @fact_list[:vm] = vm
          @fact_list[:hypervisor] = { vm.to_i => info } if vm
        end
      end
    end
  end
end
