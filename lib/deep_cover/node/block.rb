# frozen_string_literal: true

require_relative 'send'
require_relative 'keywords'

module DeepCover
  class Node
    module WithBlock
      def flow_completion_count
        parent.flow_completion_count
      end

      def execution_count
        last = children_nodes.last
        return last.flow_completion_count if last
        super
      end
    end

    class SendWithBlock < SendBase
      include WithBlock
    end

    class CsendWithBlock < Csend
      include WithBlock
      refine_child actual_send: {safe_send: SendWithBlock}
    end

    class SuperWithBlock < Node
      include WithBlock
      has_extra_children arguments: Node
    end

    class Block < Node
      check_completion
      has_tracker :body
      has_child call: {send: SendWithBlock, csend: CsendWithBlock,
                       zsuper: SuperWithBlock, super: SuperWithBlock,
}
      has_child args: Args
      has_child body: Node,
                can_be_empty: -> { base_node.loc.end.begin },
                rewrite: '%{body_tracker};%{local}=nil;%{node}',
                flow_entry_count: :body_tracker_hits,
                is_statement: true
      executed_loc_keys # none

      def children_nodes_in_flow_order
        [call, args] # Similarly to a def, the body is actually not part of the flow of this node...
      end
    end

    # &foo
    class BlockPass < Node
      has_child block: Node
      # TODO
    end
  end
end
