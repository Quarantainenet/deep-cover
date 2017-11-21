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
      insert_node_tags
      insert_branch_tags
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

    RUNS_CLASS = Hash.new('run').merge!(0 => 'not-run', nil => 'ignored')
    RUNS_TITLE = Hash.new { |k, runs| "#{runs}x" }.merge!(0 => 'never run', nil => 'ignored')

    def node_span(node, kind)
      runs = analyser.node_runs(node)
      %{<span class="node-#{node.type} kind-#{kind} #{RUNS_CLASS[runs]}" title="#{RUNS_TITLE[runs]}">}
    end

    def insert_node_tags
      analyser.each_node do |node|
        node.executed_loc_hash.each do |kind, range|
          wrap(range, node_span(node, kind), '</span>')
        end
      end
    end

    def fork_span(node, kind, id, title: nil, klass: nil)
      runs = analyser_map[:branch].node_runs(node)
      title ||= RUNS_TITLE[runs]
      klass ||= RUNS_CLASS[runs]
      icon = %{<i class="fork-icon fa fa-code-fork" aria-hidden="true" title="#{title}"></i>}
      %{<span class="fork fork-#{kind} fork-#{klass}" data-fork-id="#{id}">#{icon}}
    end

    def insert_branch_tags
      analyser_map[:branch].each_node.with_index do |node, id|
        empty_branch = nil
        node.branches.each do |branch|
          exp = branch.expression
          if exp && !exp.empty?
            wrap(exp, fork_span(branch, :branch, id), '</span>')
          else
            empty_branch = branch
          end
        end
        if empty_branch
          runs = analyser_map[:branch].node_runs(empty_branch)
          if runs && runs > 0
            # Nothing to do
          else
            name = empty_branch.name if empty_branch.respond_to?(:name)
            name ||= 'branch'
            title = "#{name} #{RUNS_TITLE[runs]}"
            klass = "with-branch-#{RUNS_CLASS[runs]}"
          end
        end
        wrap(node.expression, fork_span(node, :whole, id, title: title, klass: klass), '</span>')
      end
    end

    def wrap(range, before, after)
      @rewriter.insert_before_multi(range, before)
      @rewriter.insert_before_multi(range.end, after)
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
