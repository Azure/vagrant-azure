module VagrantPlugins
  module Azure
    module Util
      class Timer
        def self.time
          start_time = Time.now.to_f
          yield
          end_time = Time.now.to_f

          end_time - start_time
        end
      end
    end
  end
end