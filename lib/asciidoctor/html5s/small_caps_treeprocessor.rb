# frozen_string_literal: true

require 'asciidoctor/extensions'

module Asciidoctor
  module Substitutors
    module SmallCaps
      def sub_replacements(text)
        result = super
        words_raw = document.attr('html5s-small-caps', '')
        return result if words_raw.empty?

        words = words_raw.split(',').map(&:strip).reject(&:empty?)
        return result if words.empty?

        pattern = /\b(?:#{words.map { |w| Regexp.escape(w) }.join('|')})\b/
        result.gsub(/<code>.*?<\/code>|#{pattern}/) do |match|
          match.start_with?('<code>') ? match : %(<span class="sc">#{match}</span>)
        end
      end
    end

    prepend SmallCaps
  end
end