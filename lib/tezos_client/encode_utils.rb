class TezosClient

  module EncodeUtils
    def encode_args(expr)
      expr = expr.gsub(/(?:@[a-z_]+)|(?:#.*$)/m, '')
                 .gsub(/\s+/, ' ')
                 .strip

      pl = 0
      popen = false
      sopen = false
      escaped = false

      ret = {
          prim: nil,
          args: []
      }

      val = ''
      expr.each_char.with_index do |char, i|

        is_last_char = (i == (expr.length - 1))

        if escaped
          val += char
          escaped = false
          next

        elsif (!popen && !sopen && is_last_char) ||
            (!popen && !sopen && char == ' ')

          val += char if is_last_char

          unless val.empty?
            if val == val.to_i.to_s
              if !ret[:prim]
                return { 'int' => val }
              else
                ret[:args] <<  {'int' => val}
              end
            elsif ret[:prim]
              ret[:args] << encode_args(val)
            else
              ret[:prim] = val
            end
            val = ''
          end
          next

        elsif char == '"' && sopen
          sopen = false
          if !ret[:prim]
            return { 'string' => val }
          else
            ret[:args] << { 'string' => val }
          end
          val = ''
          next

        elsif char == '"' && !sopen && !popen
          sopen = true
          next

        elsif char == '\\'
          escaped = true

        elsif char == '('
          if  !popen
            popen = true
            next
          else
            pl += 1
          end

        elsif char == ')'
          if !popen
            raise "closing parenthesis while none was opened #{val}"
          end

          if pl.zero?
            ret[:args] << encode_args(val)
            val = ''
            popen = false
            next
          else
            pl -= 1
          end
        end

        val += char
      end

      if sopen
        raise ArgumentError, "string '#{val}' has not been closed"
      end

      ret
    end

  end
end