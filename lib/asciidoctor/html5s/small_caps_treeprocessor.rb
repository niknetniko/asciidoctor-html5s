# frozen_string_literal: true

require 'asciidoctor/extensions'

module Asciidoctor
  module Html5s
    # Registers small-caps substitutions for words listed in the
    # +html5s-small-caps+ document attribute (comma-separated).
    # Entries are added to Asciidoctor::REPLACEMENTS, which applies them to
    # inline text content but not to attribute values such as alt text.
    class SmallCapsTreeprocessor < ::Asciidoctor::Extensions::Treeprocessor
      REGISTERED = {}

      def process(document)
        return unless document.backend == 'html5s'

        words_raw = document.attr('html5s-small-caps', '')
        return if words_raw.empty?

        words = words_raw.split(',').map(&:strip).reject(&:empty?)
        return if words.empty?

        key = words.sort.join(',')
        return if REGISTERED[key]

        REGISTERED[key] = true
        words.each do |word|
          REPLACEMENTS.unshift([/#{Regexp.escape(word)}/, "<span class=\"sc\">#{word}</span>", :none])
        end
      end
    end
  end
end
