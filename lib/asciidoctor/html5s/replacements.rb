# frozen_string_literal: true

require 'asciidoctor'

module Asciidoctor
  # XXX: Modifies constant defined in Asciidoctor.
  REPLACEMENTS.unshift(
    # foo --- bar -> &thinsp;&mdash;&thinsp;
    [/(^|\n| )---( |\n|$)/, '&#8201;&#8212;&#8201;', :none],
    # foo---bar -> &mdash;{ZERO WIDTH SPACE}
    [/(#{CG_WORD})---(?=#{CG_WORD})/, '&#8212;&#8203;', :leading],
    # foo -- bar -> &thinksp;&ndash;&thinsp;
    # Note: The regexp is copied from Asciidoctor.
    [/(^|\n|\\| )--( |\n|$)/, '&#8201;&#8211;&#8201;', :none],
    # foo--bar -> &ndash;
    # Note: The regexp is copied from Asciidoctor.
    [/(#{CG_WORD})\\?--(?=#{CG_WORD})/, '&#8211;', :leading]
  )
end
