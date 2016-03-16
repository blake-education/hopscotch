module Hopscotch
  module With
    module Matching
      extend self

      def parse_returned(vars, line, returned)
        pattern = line.pattern

        # nil or [] means "wildcard"
        if wildcard_pattern?(pattern)
          return [vars, true, returned]
        end

        # the patterns are identical...
        if exact_match?(pattern, returned)
          return [vars, true, returned]
        end

        # no way to match this
        if cannot_match?(pattern, returned)
          return [vars, false, Nomatch.wrap_return_as_error(returned, line)]
        end

        zip_pattern_with_returned(pattern, returned).each do |p, v|
          case p
          when Hopscotch::With::Var
            vars[p.name] = v
          else
            unless p == v
              return [vars, false, Nomatch.wrap_return_as_error(returned, line)]
            end
          end
        end

        [vars, true, returned]
      end

      def zip_pattern_with_returned(pattern, returned)
        pattern.parts.zip(returned)
      end

      def exact_match?(pattern, returned)
        returned == pattern.parts
      end

      def wildcard_pattern?(pattern)
        pattern.parts.nil? || pattern.parts.empty?
      end

      def cannot_match?(pattern, returned)
        returned.nil?  || (pattern.parts.class != returned.class) || (Array === returned && pattern.parts.size != returned.size)
      end
    end
  end
end
