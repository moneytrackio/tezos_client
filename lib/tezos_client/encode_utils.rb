class TezosClient

  module EncodeUtils

    class ArgsEncoder
      attr_accessor :expr, :popen, :sopen, :escaped, :pl, :ret


      def initialize(expr)
        @expr = expr.gsub(/(?:@[a-z_]+)|(?:#.*$)/m, '')
                    .gsub(/\s+/, ' ')
                    .strip
        initialize_statuses
        initialize_ret
      end

      def initialize_statuses
        @popen = false
        @sopen = false
        @escaped = false
        @pl = 0
        @val = ''
      end

      def initialize_ret
        @ret = {
          prim: nil,
          args: []
        }
      end

      def treat_val
        unless @val.empty?
          if @val == @val.to_i.to_s
            if !ret[:prim]
              @ret = { 'int' => @val }
            else
              @ret[:args] << { 'int' => @val }
            end
          elsif ret[:prim]
            @ret[:args] << ArgsEncoder.new(@val).encode
          else
            @ret[:prim] = @val
          end
          @val = ''
        end
      end

      def treat_double_quote(char)
        return false unless char == '"'

        if @sopen
          @sopen = false
          if !ret[:prim]
            @ret = { 'string' => @val }
          else
            @ret[:args] << { 'string' => @val }
          end
          @val = ''
        else
          @sopen = true
        end
        true
      end

      def treat_parenthesis(char)
        case char
        when '('
          @val += char if @popen
          @popen = true
          @pl += 1
          true
        when ')'
          raise "closing parenthesis while none was opened #{val}" unless popen
          @pl -= 1
          if pl.zero?
            @ret[:args] << ArgsEncoder.new(@val).encode
            @val = ''
            @popen = false
          else
            @val += char
          end
          true
        else
          false
        end
      end

      def treat_escape(char)
        if escaped
          @val += char
          @escaped = false
          true
        elsif char == "\\"
          @escaped = true
          true
        end
        false
      end

      def treat_char(char, is_last_char)

        return if treat_escape(char)

        unless popen || sopen
          if is_last_char || char == ' '
            @val += char if is_last_char
            treat_val
            return
          end
        end

        unless popen
          return if treat_double_quote(char)
        end

        return if treat_parenthesis(char)

        @val += char
      end

      def encode
        expr.each_char.with_index do |char, i|

          is_last_char = (i == (expr.length - 1))
          treat_char(char, is_last_char)
        end

        if sopen
          raise ArgumentError, "string '#{@val}' has not been closed"
        end

        ret
      end
    end

    def encode_args(expr)
      ArgsEncoder.new(expr).encode
    end


  end
end