require 'term/ansicolor'

module DeepCover
  module CLI
    class Debugger
      include Tools

      module ColorAST
        def fancy_type
          color = case
          when !executable?
            :faint
          when !was_executed?
            :red
          when flow_interrupt_count > 0
            :yellow
          else
            :green
          end
          Term::ANSIColor.send(color, super)
        end
      end

      def initialize(source, filename: '(source)', lineno: 1, pry: false)
        @source = source
        @filename = filename
        @lineno = lineno
        @pry = pry
      end

      def show
        show_line_coverage
        show_instrumented_code
        show_ast
        show_char_coverage
        pry if @pry
        finish
      end

      def show_line_coverage
        puts "Line Coverage: Builtin | DeepCover | DeepCover Strict:\n"
        begin
          builtin_line_coverage = builtin_coverage(@source, @filename, @lineno)
          our_line_coverage = our_coverage(@source, @filename, @lineno)
          our_strict_line_coverage = our_coverage(@source, @filename, @lineno, allow_partial: false)
          lines = format(builtin_line_coverage, our_line_coverage, our_strict_line_coverage, source: @source)
          puts number_lines(lines, lineno: @lineno)
        rescue Exception => e
          puts "Can't run coverage: #{e.class.name}: #{e}\n#{e.backtrace.join("\n")}"
          @failed = true
        end
      end

      def show_instrumented_code
        puts "\nInstrumented code:\n"
        puts format_generated_code(covered_code)
      end

      def show_ast
        puts "\nParsed code:\n"
        begin
          execute_sample(covered_code)
        rescue Exception => e
          puts "Can't `execute_sample`:#{e.class.name}: #{e}\n#{e.backtrace.join("\n")}"
          @failed = true
        end

        Node.prepend ColorAST
        puts covered_code.covered_ast
      end

      def show_char_coverage
        puts "\nChar coverage:\n"

        puts format_char_cover(covered_code, show_whitespace: !!ENV['W'])
      end

      def pry
        a = covered_code.covered_ast
        b = a.children.first
        binding.pry
      end

      def finish
        exit(!@failed)
      end

      def covered_code
        @covered_code ||= CoveredCode.new(source: @source, path: @filename, lineno: @lineno)
      end
    end
  end
end