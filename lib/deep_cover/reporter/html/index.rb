# frozen_string_literal: true

module DeepCover
  module Reporter
    require_relative 'tree'
    class HTML::Index < Struct.new(:analysis)
      def initialize(analysis)
        raise ArgumentError unless analysis.is_a? Coverage::Analysis
        super
      end

      include HTML::Tree

      def stats_to_data
        @map = Tools.transform_keys(analysis.stat_map, &:name)
        tree = paths_to_tree(@map.keys)
        transform_data(populate(tree))
      end

      def columns
        _covered_code, analyser_map = analysis.analyser_map.first
        columns = analyser_map.flat_map do |type, analyser|
          [{
             value: type,
             header: analyser.class.human_name,
           }, {
                value: :"#{type}_percent",
                header: '%',
              },
]
        end
        columns.unshift(width: 400, header: 'Path')
        columns
      end

      private

      # {a: {}}    => [{text: a, data: stat_map[a]}]
      # {b: {...}} => [{text: b, data: sum(stats), children: [...]}]
      def populate(tree)
        tree.map do |path, children_hash|
          if children_hash.empty?
            {
              text: %{<a href="#{path}.html">#{path}</a>},
              data: @map[path],
            }
          else
            children = populate(children_hash)
            data = Tools.merge(*children.map { |c| c[:data] }, :+)
            {
              text: path,
              data: data,
              children: children,
              state: {opened: true},
            }
          end
        end
      end

      # Modifies in place the tree:
      # {per_char: Stat, ...} => {per_char: {ignored: ...}, per_char_percent: 55.55, ...}
      def transform_data(tree)
        return unless tree
        tree.each do |node|
          node[:data] = Tools.merge(
              node[:data].transform_values(&:to_h),
              *node[:data].map { |type, stat| {:"#{type}_percent" => stat.percent_covered} }
          )
          transform_data(node[:children])
        end
      end
    end
  end
end
