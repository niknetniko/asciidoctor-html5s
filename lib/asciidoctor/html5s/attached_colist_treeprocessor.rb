# frozen_string_literal: true

require 'asciidoctor/html5s/version'
require 'asciidoctor/extensions'

module Asciidoctor
  module Html5s
    # This extension moves every callout list immediately following listing block
    # to instance variable +@html5s_colist+ inside the listing block.
    # The aim is to render callout list as part of the corresponding listing.
    class AttachedColistTreeprocessor < ::Asciidoctor::Extensions::Treeprocessor
      def process(document)
        return if document.backend != 'html5s'

        document.find_by(context: :colist) do |colist|
          blocks = colist.parent.blocks
          colist_idx = blocks.find_index(colist)
          prev_block = blocks[colist_idx - 1] if colist_idx

          if prev_block && prev_block.node_name == 'listing'
            prev_block.instance_variable_set(:@html5s_colist, colist)
            # XXX: This mutates node's blocks list!
            # :empty is our special block type that just outputs nothing.
            blocks[colist_idx] = create_block(colist.parent, :empty, '', {})
          end
        end
      end
    end
  end
end
