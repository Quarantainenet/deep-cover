# frozen_string_literal: true

module DeepCover
  class Reporter::HTML::Source < Struct.new(:analyser_map)
    def initialize(analyser_map)
      raise ArgumentError unless analyser_map.values.all? { |a| a.is_a?(Analyser) }
      super
    end

    include Tools::ContentTag

    def format_source
      lines = convert_source.split("\n")
      lines.map { |line| content_tag(:td, line) }
      rows = lines.map.with_index do |line, i|
        nb = content_tag(:td, i + 1, id: "L#{i + 1}", class: :nb)
        content_tag(:tr, nb + content_tag(:td, line))
      end
      content_tag(:table, rows.join, class: :source)
    end

    def convert_source
      @rewriter = ::Parser::Source::Rewriter.new(covered_code.buffer)
      insert_tags
      html_escape
      @rewriter.process
    end

    def root_path
      Pathname('.').relative_path_from(Pathname(covered_code.name).dirname)
    end

    def stats
      cells = analyser_map.map do |type, analyser|
        data = analyser.stats
        f = ->(kind) { content_tag(:span, data.public_send(kind), class: kind, title: kind) }
        [content_tag(:th, analyser.class.human_name, class: type),
         content_tag(:td, "#{f[:executed]} #{f[:ignored] if data.ignored > 0} / #{f[:potentially_executable]}", class: type),
        ]
      end
      rows = cells.transpose.map { |line| content_tag(:tr, line.join) }
      content_tag(:table, rows.join)
    end

    def analyser
      analyser_map[:per_char]
    end

    def covered_code
      analyser.covered_code
    end

    private

    def node_attributes(node, kind)
      title, run = case runs = analyser.node_runs(node)
                   when nil
                     ['ignored', 'ignored']
                   when 0
                     ['never run', 'not-run']
                   else
                     ["#{runs}x", 'run']
                   end
      %{class="node-#{node.type} kind-#{kind} #{run}" title="#{title}"}
    end

    def insert_tags
      analyser.each_node do |node|
        node.executed_loc_hash.each do |kind, range|
          @rewriter.insert_before_multi(range, "<span #{node_attributes(node, kind)}>")
          @rewriter.insert_before_multi(range.end, '</span>')
        end
      end
    end

    def html_escape
      buffer = analyser.covered_code.buffer
      source = buffer.source
      {'<' => '&lt;', '>' => '&gt;', '&' => '&amp;'}.each do |char, escaped|
        source.scan(char) do
          m = Regexp.last_match
          range = ::Parser::Source::Range.new(buffer, m.begin(0), m.end(0))
          @rewriter.replace(range, escaped)
        end
      end
    end
  end
end
