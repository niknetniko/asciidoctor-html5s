# frozen_string_literal: true

require 'asciidoctor/extensions'

module Asciidoctor
  module Html5s
    class SmallCapsPostProcessor < Asciidoctor::Extensions::Postprocessor
      # TODO: should we parse with Nokogiri?
      def process(document, output)
        return output unless document.basebackend? 'html'

        words_raw = document.attr('html5s-small-caps', '')
        return output if words_raw.empty?

        words = words_raw.split(',').map(&:strip).reject(&:empty?)
        return output if words.empty?

        pattern = /\b(?:#{words.map { |w| Regexp.escape(w) }.join('|')})\b/

        output.gsub(/<code>.*?<\/code>|<[^>]*>|#{pattern}/) do |match|
          match.start_with?('<') ? match : %(<span class="sc">#{match}</span>)
        end
      end
    end
  end
end
