module Hopscotch
  module With
    module Execution
      extend self

      def execute(definition)
        vars = {}

        lines = [ definition.lines, definition.post_lines ].flatten.compact

        final_returned = lines.reduce(nil) do |_last_rv, line|
          begin
            vars,result,returned = *execute_line(vars, line)
          rescue
            result = false
            returned = [:err, "#{line} raised an exception: #{$!.class} #{$!}", $!]
          end

          unless result
            puts "calling nm"
            if nomatch_line = definition.nomatch
              execute_line(vars, nomatch_line)
            end
          end

          returned
        end



        line.block_self.instance_exec(definition.final_match.call(*final_returned))
      end

      def execute_line(vars, line)
        resolved_args = resolve_args(vars, line)
        returned = line.computation.computation.call( *resolved_args )

        Matching.parse_returned( vars, line, returned )
      end

      def resolve_args(vars, line)
        args = line.computation.args
        args.map do |arg|
          case arg
          when Hopscotch::With::Var
            resolve_var(vars[arg.name], arg)
          else
            arg
          end
        end
      end

      # XXX behaviour when fetch fails?
      def resolve_var(value, arg)
        value_path = arg.value_path || []

        value_path.reduce(value) do |value, index|
          value.fetch(index)
        end
      rescue IndexError,KeyError
        # XXX check for optional
        arg.default_value
      end
    end
  end
end
