module OpsWorks
    module Callback
      def run_op_callback_from_file(release_path, callback_file)
        if ::File.exist?(callback_file)
          Dir.chdir(release_path) do
            Chef::Log.info "running deploy hook: #{callback_file}"
            recipe_eval { from_file(callback_file) }
          end
        end
      end
    end
end

class Chef::Recipe
  include OpsWorks::Callback
end