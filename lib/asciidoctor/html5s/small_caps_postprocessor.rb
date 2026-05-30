# frozen_string_literal: true

require 'asciidoctor/extensions'
require 'nokogiri'
require 'cgi'

module Asciidoctor
  module Html5s
    # Asciidoctor does not expose a clean way to extend the replacements mechanism,
    # which also seems fragile in nature: it runs on some raw text.
    # See https://github.com/asciidoctor/asciidoctor/issues/1061
    # But, I was tired having to deal with the regex here, so this function
    # is highly AI-generated (reviewed, but still.)
    class SmallCapsPostProcessor < Asciidoctor::Extensions::Postprocessor
      SKIP_ELEMENTS = %w[pre script style code kbd samp var].freeze

      def process(document, output)
        return output unless document.basebackend? 'html'

        words_raw = document.attr('html5s-small-caps', '')
        return output if words_raw.empty?

        words = words_raw.split(',').map(&:strip).reject(&:empty?)
        return output if words.empty?

        is_full_document = output.match?(/\A\s*<!DOCTYPE/i) || output.match?(/\A\s*<html/i)
        doc = is_full_document ? Nokogiri::HTML5.parse(output) : Nokogiri::HTML5::DocumentFragment.parse(output)

        regex = /\b(#{Regexp.union(words).source})\b/

        doc.xpath('.//text()').each do |node|
          next if node.content.strip.empty?
          next if node.ancestors.any? { |a| SKIP_ELEMENTS.include?(a.name.downcase) }
          next unless node.content.match?(regex)

          escaped_text = CGI.escapeHTML(node.content)

          new_html = escaped_text.gsub(regex) do |match|
            %(<span class="sc">#{match}</span>)
          end

          node.replace(doc.fragment(new_html))
        end

        doc.to_html
      end
    end
  end
end
