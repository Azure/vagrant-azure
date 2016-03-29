module VagrantPlugins
  module Azure
    module Util
      module VMAwait

        def await_true(env)
          config = env[:machine].provider_config
          parsed = parse_machine_id(env[:machine].id)
          azure = env[:azure_arm_service]
          tries = config.instance_ready_timeout / 2
          count = 0
          task = Concurrent::TimerTask.new(execution_interval: config.instance_check_interval ) do
            task.shutdown if env[:interrupted]

            if count > tries
              task.shutdown
              false
            end

            count += 1
            vm = azure.compute.virtual_machines.get(parsed[:group], parsed[:name], 'instanceView').value!.body
            if yield(vm)
              task.shutdown
              true
            end
          end

          task.execute
          task.wait_for_termination
          task
        end

      end
    end
  end
end
