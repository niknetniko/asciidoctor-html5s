# frozen_string_literal: true

require 'asciidoctor/html5s'
require 'date' unless RUBY_PLATFORM == 'opal'

# Add custom functions to this module that you want to use in your Slim
# templates. Within the template you can invoke them as top-level functions
# just like in Haml.
module Slim::Helpers # rubocop:disable Style/ClassAndModuleChildren
  # URIs of external assets.
  CDN_BASE_URI         = 'https://cdnjs.cloudflare.com/ajax/libs'
  FONT_AWESOME_URI     = 'https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css'
  HIGHLIGHTJS_BASE_URI = 'https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@9.15.1/build/'
  KATEX_CSS_URI        = 'https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.min.css'
  KATEX_JS_URI         = 'https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.min.js'

  # Defaults
  DEFAULT_HIGHLIGHTJS_THEME = 'github'
  DEFAULT_LANG = 'en'
  DEFAULT_SECTNUMLEVELS = 3
  DEFAULT_TOCLEVELS = 2

  CURLY_QUOTES = [
    [%w[af en eo ga hi ia id ko mt th tr zh], ['&#x2018;', '&#x2019;', '&#x201c;', '&#x201d;']], # ‘…’ “…”
    [%w[bs fi sv], ['&#x2019;', '&#x2019;', '&#x201d;', '&#x201d;']], # ’…’ ”…”
    [%w[cs da de is lt sl sk sr], ['&#x201a;', '&#x2018;', '&#x201e;', '&#x201c;']], # ‚…‘ „…“
    [%w[nl], ['&#x201a;', '&#x2019;', '&#x201e;', '&#x201d;']], # ‚…’ „…”
    [%w[hu pl ro], ['&#x00ab;', '&#x00bb;', '&#x201e;', '&#x201d;']] # «…» „…”
  ].each_with_object({}) do |(langs, codes), hsh|
    langs.each { |lang| hsh[lang] = codes }
  end
  CURLY_QUOTES.default = CURLY_QUOTES[DEFAULT_LANG]

  KATEX_RENDER_CODE = <<-JS.gsub(/\s+/, ' ')
    document.addEventListener("DOMContentLoaded", function() {
      var elements = document.getElementsByClassName("math");
      for (var i = 0; i < elements.length; i++) {
        var el = elements[i];
        if (el.getAttribute("data-lang") !== "tex") {
          continue;
        }
        katex.render(el.textContent.slice(2, -2), el, {
          "displayMode": el.nodeName.toUpperCase() !== "SPAN",
          "throwOnError": false,
        });
      }
    });
  JS

  VOID_ELEMENTS = %w[area base br col command embed hr img input keygen link
                     meta param source track wbr].freeze

  # @return [Logger]
  def log
    ::Asciidoctor::LoggerManager.logger
  end

  ##
  # Captures the given block for later yield.
  #
  # @example Basic capture usage.
  #   - capture
  #     img src=image_uri
  #   - if title?
  #     figure.image
  #       - yield_capture
  #       figcaption =captioned_title
  #   - else
  #     - yield_capture
  #
  # @example Capture with passing parameters.
  #   - capture do |id|
  #     img src=image_uri
  #   - if title?
  #     figure id=@id
  #       - yield_capture
  #       figcaption =caption
  #   - else
  #     - yield_capture @id
  #
  # @see yield_capture
  def capture(&block)
    @_html5s_capture = block
    nil
  end

  ##
  # Yields the captured block (see {#capture}).
  #
  # @param *params parameters to pass to the block.
  # @return A content of the captured block.
  # @see capture
  def yield_capture(*params)
    @_html5s_capture&.call(*params)
  end

  ##
  # Creates an HTML tag with the given name and optionally attributes. Can take
  # a block that will run between the opening and closing tags.
  #
  # @param name [#to_s] the name of the tag.
  # @param attributes [Hash] (default: {})
  # @param content [#to_s] the content; +nil+ to call the block. (default: nil).
  # @yield The block of Slim/HTML code within the tag (optional).
  # @return [String] a rendered HTML element.
  #
  def html_tag(name, attributes = {}, content = nil)
    attrs = attributes.inject([]) do |attrs_, (k, v)|
      next attrs_ if !v || v.nil_or_empty?

      v = v.compact.join(' ') if v.is_a? Array
      attrs_ << (v == true ? k : %(#{k}="#{v}"))
    end
    attrs_str = attrs.empty? ? '' : ' ' + attrs.join(' ')

    if VOID_ELEMENTS.include? name.to_s
      %(<#{name}#{attrs_str}>)
    else
      content ||= yield if block_given?
      %(<#{name}#{attrs_str}>#{content}</#{name}>)
    end
  end

  ##
  # Conditionally wraps a block in an element. If condition is +true+ then it
  # renders the specified tag with optional attributes and the given
  # block inside, otherwise it just renders the block.
  #
  # For example:
  #
  #    = html_tag_if link?, 'a', {class: 'image', href: (attr :link)}
  #      img src='./img/tux.png'
  #
  # will produce:
  #
  #    <a href="http://example.org" class="image">
  #      <img src="./img/tux.png">
  #    </a>
  #
  # if +link?+ is truthy, and just
  #
  #   <img src="./img/tux.png">
  #
  # otherwise.
  #
  # @param condition [Boolean] the condition to test to determine whether to
  #        render the enclosing tag.
  # @param name (see #html_tag)
  # @param attributes (see #html_tag)
  # @param content (see #html_tag)
  # @yield (see #html_tag)
  # @return [String] a rendered HTML fragment.
  #
  def html_tag_if(condition, name, attributes = {}, content = nil, &)
    if condition
      html_tag(name, attributes, content, &)
    else
      content || yield
    end
  end

  ##
  # Wraps a block in a div element with the specified class and optionally
  # the node's +id+ and +role+(s). If the node's +title+ is not empty, then a
  # nested div with the class "title" and the title's content is added as well.
  #
  # @example When @id, @role and @title attributes are set.
  #   = block_with_title :class=>['quote-block', 'center']
  #     blockquote =content
  #
  #   <section id="myid" class="quote-block center myrole1 myrole2">
  #     <h6>Block Title</h6>
  #     <blockquote>Lorem ipsum</blockquote>
  #   </section>
  #
  # @example When @id, @role and @title attributes are empty.
  #   = block_with_title :class=>'quote-block center', :style=>style_value(float: 'left')
  #     blockquote =content
  #
  #   <div class="quote-block center" style="float: left;">
  #     <blockquote>Lorem ipsum</blockquote>
  #   </div>
  #
  # @example When shorthand style for class attribute is used.
  #   = block_with_title 'quote-block center'
  #     blockquote =content
  #
  #   <div class="quote-block center">
  #     <blockquote>Lorem ipsum</blockquote>
  #   </div>
  #
  # @param attrs [Hash, String] the tag's attributes as Hash),
  #        or the tag's class if it's not a Hash.
  # @param title [String, nil] the title.
  # @yield The block of Slim/HTML code within the tag (optional).
  # @return [String] a rendered HTML fragment.
  #
  def block_with_title(attrs = {}, title = @title)
    if (klass = attrs[:class]).is_a? String
      klass = klass.split
    end
    attrs[:class] = [klass, role].flatten.uniq
    attrs[:id] = id

    if title.nil_or_empty?
      # XXX quick hack
      nested = is_a?(::Asciidoctor::List) &&
               (parent.is_a?(::Asciidoctor::ListItem) || parent.is_a?(::Asciidoctor::List))
      html_tag_if !nested, :div, attrs, yield
    else
      html_tag :section, attrs do
        [html_tag(:h6, { class: 'block-title' }, title), yield].join("\n")
      end
    end
  end

  def block_with_caption(position = :bottom, attrs = {})
    if (klass = attrs[:class]).is_a? String
      klass = klass.split
    end
    attrs[:class] = [klass, role].flatten.uniq
    attrs[:id] = id

    if title.nil_or_empty?
      html_tag :div, attrs, yield
    else
      html_tag :figure, attrs do
        ary = [yield, html_tag(:figcaption) { captioned_title }]
        ary.reverse! if position == :top
        ary.compact.join("\n")
      end
    end
  end

  ##
  # Delimite the given equation as a STEM of the specified type.
  #
  # Note: This is not needed nor used for KaTeX, but keep this for the case
  # user wants to use a different method.
  #
  # @param equation [String] the equation to delimite.
  # @param type [#to_sym] the type of the STEM renderer (latexmath, or asciimath).
  # @return [String] the delimited equation.
  #
  def delimit_stem(equation, type)
    type = @_html5s_stem_type if @_html5s_stem_type ||= document.attr('html5s-force-stem-type')

    if is_a? ::Asciidoctor::Block
      open, close = ::Asciidoctor::BLOCK_MATH_DELIMITERS[type.to_sym]
    else
      open, close = ::Asciidoctor::INLINE_MATH_DELIMITERS[type.to_sym]
    end

    equation = [open, equation, close].join if !equation.start_with?(open) || !equation.end_with?(close)
    equation
  end

  ##
  # Formats the given hash as CSS declarations for an inline style.
  #
  # @example
  #   style_value(text_align: 'right', float: 'left')
  #   => "text-align: right; float: left;"
  #
  #   style_value(text_align: nil, float: 'left')
  #   => "float: left;"
  #
  #   style_value(width: [90, '%'], height: '50px')
  #   => "width: 90%; height: 50px;"
  #
  #   style_value(width: ['120px', 'px'])
  #   => "width: 90px;"
  #
  #   style_value(width: [nil, 'px'])
  #   => nil
  #
  # @param declarations [Hash]
  # @return [String, nil]
  #
  def style_value(declarations)
    decls = []

    declarations.each do |prop, value|
      next if value.nil?

      if value.is_a? Array
        value, unit = value
        next if value.nil?

        value = value.to_s + unit unless value.end_with? unit
      end
      prop = prop.to_s.gsub('_', '-')
      decls << "#{prop}: #{value}"
    end

    decls.empty? ? nil : decls.join('; ') + ';'
  end

  def urlize(*segments)
    path = segments * '/'
    if path.start_with? '//'
      @_html5s_uri_scheme ||= document.attr('asset-uri-scheme', 'https')
      path = "#{@_html5s_uri_scheme}:#{path}" unless @_html5s_uri_scheme.empty?
    end
    normalize_web_path path
  end

  ##
  # Gets the value of the specified attribute in this node.
  #
  # This is just an alias for +attr+ method with disabled _inherit_ to make it
  # more clear.
  #
  # @param name [String, Symbol] the name of the attribute to lookup.
  # @param default_val the value to return if the attribute is not found.
  # @return value of the attribute or +default_val+ if not found.
  #
  def local_attr(name, default_val = nil)
    attr(name, default_val, false)
  end

  ##
  # Checks if the attribute is defined on this node, optionally performing
  # a comparison of its value if +expect_val+ is not nil.
  #
  # This is just an alias for +attr?+ method with disabled _inherit_ to make it
  # more clear.
  #
  # @param name [String, Symbol] the name of the attribute to lookup.
  # @param default_val the expected value of the attribute.
  # @return [Boolean] whether the attribute exists and, if +expect_val+ is
  #   specified, whether the value of the attribute matches the +expect_val+.
  #
  def local_attr?(name, expect_val = nil)
    attr?(name, expect_val, false)
  end

  ##
  # @param index [Integer] the footnote's index.
  # @return [String] footnote id to be used in a link.
  def footnote_id(index = local_attr(:index))
    "_footnote_#{index}"
  end

  ##
  # @param index (see #footnote_id)
  # @return [String] footnoteref id to be used in a link.
  def footnoteref_id(index = local_attr(:index))
    "_footnoteref_#{index}"
  end

  def nowrap?
    'nowrap' if !document.attr?(:prewrap) || option?('nowrap')
  end

  def print_item_content(item)
    wrap = item.blocks? && !item.blocks.all? { |b| b.is_a? ::Asciidoctor::List }
    [(html_tag_if(wrap, :p) { item.text } if item.text?), item.content].join
  end

  ##
  # Returns corrected section level.
  #
  # @param sec [Asciidoctor::Section] the section node (default: self).
  # @return [Integer]
  #
  def section_level(sec = self)
    sec.level.zero? && sec.special ? 1 : sec.level
  end

  ##
  # Returns the captioned section's title, optionally numbered.
  #
  # @param sec [Asciidoctor::Section] the section node (default: self).
  # @param drop_anchors [Boolean] Remove +<a>+ tags from the title?
  # @return [String]
  #
  def section_title(sec = self, drop_anchors: false)
    title =
      if sec.caption
        sec.captioned_title
      elsif sec.numbered && sec.level <= document.attr(:sectnumlevels, DEFAULT_SECTNUMLEVELS).to_i
        if sec.level < 2 && document.doctype == 'book' && %w[chapter part].include?(sec.sectname)
          signifier = document.attr("#{sec.sectname}-signifier")
          sectnum = sec.sectname == 'part' ? sec.sectnum(nil, ':') : sec.sectnum
          "#{signifier&.+ ' '}#{sectnum} #{sec.title}"
        else
          "#{sec.sectnum} #{sec.title}"
        end
      else
        sec.title
      end

    if drop_anchors && title.include?('<a')
      title.gsub(%r{<(?:a[^>+]+|/a)>}, '')
    else
      title
    end
  end

  ##
  # @return [String] language of STEM block or inline node (tex or asciimath).
  def stem_lang
    value = (inline? ? type : style).to_s
    value == 'latexmath' ? 'tex' : value
  end

  def link_rel
    rel = [
      ('nofollow' if option?('nofollow')),
      ('noopener' if option?('noopener') || local_attr(:window) == '_blank')
    ].compact

    rel.empty? ? nil : rel.join(' ')
  end

  #--------------------------------------------------------
  # block_admonition
  #

  ##
  # @return [Boolean] should be this admonition wrapped in aside element?
  def admonition_aside?
    %w[note tip].include? attr(:name)
  end

  ##
  # @return [String, nil] WAI-ARIA role of this admonition.
  def admonition_aria
    case attr(:name)

    when 'note'
      'note' # https://www.w3.org/TR/wai-aria/roles#note
    when 'tip'
      'doc-tip' # https://www.w3.org/TR/dpub-aria-1.0/#doc-tip
    when 'caution', 'important', 'warning'
      'doc-notice' # https://www.w3.org/TR/dpub-aria-1.0/#doc-notice
    end
  end

  #--------------------------------------------------------
  # block_image
  #

  ##
  # @return [String, nil] an URL for the image's link.
  def image_link
    @image_link ||=
      case (link = attr(:link))
      when 'none', 'false'
        return
      when 'self'
        image_uri(attr(:target))
      when nil, ''
        image_uri(attr(:target)) if document.attr?('html5s-image-default-link', 'self')
      else
        link
      end
  end

  ##
  # @return [String, nil] a label/title of the image link.
  def image_link_label
    return unless image_uri(attr(:target)) == image_link

    document.attr('html5s-image-self-link-label', 'Open the image in full size')
  end

  #--------------------------------------------------------
  # block_listing
  #

  ##
  # See {Asciidoctor::SyntaxHighlighter#format}.
  #
  # @return [String, nil] a rendered HTML.
  def formatted_source
    hl = document.syntax_highlighter or return nil

    opts = { nowrap: nowrap? }
    if hl.highlight?
      opts[:css_mode] = document.attr("#{hl.name}-css", :class).to_sym
      opts[:style] = document.attr("#{hl.name}-style")
    end

    hl.format(self, source_lang, opts)
  end

  ##
  # Returns the callout list attached to this listing node, or +nil+ if none.
  #
  # Note: This variable is set by extension
  # {Asciidoctor::Html5s::AttachedColistTreeprocessor}.
  #
  # @return [Asciidoctor::List, nil]
  def callout_list
    @html5s_colist
  end

  def source_lang
    local_attr :language, false
  end

  # This is needed only for Asciidoctor <2.0.0.
  def source_code_class
    if document.attr? 'source-highlighter', 'highlightjs'
      "language-#{source_lang || 'none'} hljs"
    elsif source_lang
      "language-#{source_lang}"
    end
  end

  #--------------------------------------------------------
  # block_open
  #

  ##
  # Returns +true+ if an abstract block is allowed in this document type,
  # otherwise prints warning and returns +false+.
  def abstract_allowed?
    if (result = parent == document && document.doctype == 'book')
      log.warn 'asciidoctor: WARNING: abstract block cannot be used in a document
without a title when doctype is book. Excluding block content.'
    end
    !result
  end

  ##
  # Returns +true+ if a partintro block is allowed in this context, otherwise
  # prints warning and returns +false+.
  def partintro_allowed?
    if (result = level != 0 || parent.context != :section || document.doctype != 'book')
      log.warn "asciidoctor: ERROR: partintro block can only be used when doctype
is book and must be a child of a book part. Excluding block content."
    end
    !result
  end

  #--------------------------------------------------------
  # block_table
  #

  def autowidth?(node = self)
    node.option? :autowidth
  end

  def stretch?
    return unless !autowidth? || local_attr?('width') # rubocop:disable Style/ReturnNilInPredicateMethodDefinition

    'stretch' if attr? :tablepcwidth, 100
  end

  #--------------------------------------------------------
  # block_video
  #

  # @return [Boolean] +true+ if the video should be embedded in an iframe.
  def video_iframe?
    %w[vimeo youtube].include? attr(:poster)
  end

  def video_uri
    case attr(:poster, '').to_sym
    when :vimeo
      params = {
        autoplay: (1 if option? 'autoplay'),
        loop: (1 if option? 'loop'),
        muted: (1 if option? 'muted')
      }
      start_anchor = "#at=#{attr :start}" if attr? :start
      "//player.vimeo.com/video/#{attr :target}#{start_anchor}#{url_query params}"

    when :youtube
      video_id, list_id = attr(:target).split('/', 2)
      params = {
        rel: 0,
        start: (attr :start),
        end: (attr :end),
        list: (attr :list, list_id),
        autoplay: (1 if option? 'autoplay'),
        loop: (1 if option? 'loop'),
        muted: (1 if option? 'muted'),
        controls: (0 if option? 'nocontrols')
      }
      "//www.youtube.com/embed/#{video_id}#{url_query params}"
    else
      anchor = [attr(:start), attr(:end)].join(',').chomp(',')
      anchor = '' if anchor == ',' # XXX: https://github.com/opal/opal/issues/1902
      anchor = '#t=' + anchor unless anchor.empty?
      media_uri "#{attr :target}#{anchor}"
    end
  end

  # Formats URL query parameters.
  def url_query(params)
    str = params.map do |k, v|
      next if v.nil? || v.to_s.empty?

      [k, v].join('=')
    end.compact.join('&amp;')

    '?' + str unless str.empty?
  end

  #--------------------------------------------------------
  # document
  #

  ##
  # @return [String, nil] the revision date in ISO 8601, or nil if not
  #   available or in invalid format.
  def revdate_iso
    ::Date.parse(revdate).iso8601 if defined? ::Date
  rescue ArgumentError
    nil
  end

  ##
  # Returns HTML meta tag if the given +content+ is not +nil+.
  #
  # @param name [#to_s] the name for the metadata.
  # @param content [#to_s, nil] the value of the metadata, or +nil+.
  # @return [String, nil] the meta tag, or +nil+ if the +content+ is +nil+.
  #
  def html_meta_if(name, content)
    %(<meta name="#{name}" content="#{content}">) if content
  end

  # Returns formatted style/link and script tags for header.
  def styles_and_scripts
    scripts = []
    styles = []
    tags = []

    stylesheet = attr :stylesheet
    stylesdir = attr :stylesdir, ''
    default_style = ::Asciidoctor::DEFAULT_STYLESHEET_KEYS.include? stylesheet
    ss = ::Asciidoctor::Stylesheets.instance

    if attr?(:linkcss)
      path = default_style ? ::Asciidoctor::DEFAULT_STYLESHEET_NAME : stylesheet
      styles << { href: [stylesdir, path] }
    elsif default_style
      styles << { text: ss.primary_stylesheet_data }
    else
      styles << { text: read_asset(normalize_system_path(stylesheet, stylesdir), true) }
    end

    if attr? :icons, 'font'
      styles << if attr? 'iconfont-remote'
                  { href: attr('iconfont-cdn', FONT_AWESOME_URI) }
                else
                  { href: [stylesdir, "#{attr 'iconfont-name', 'font-awesome'}.css"] }
                end
    end

    if attr? 'stem'
      styles << { href: KATEX_CSS_URI }
      scripts << { src: KATEX_JS_URI }
      scripts << { text: KATEX_RENDER_CODE }
    end

    if !defined?(::Asciidoctor::SyntaxHighlighter) && attr?('source-highlighter', 'highlightjs')
      hjs_base = attr :highlightjsdir, HIGHLIGHTJS_BASE_URI
      hjs_theme = attr 'highlightjs-theme', DEFAULT_HIGHLIGHTJS_THEME

      scripts << { src: [hjs_base, 'highlight.min.js'] }
      scripts << { text: 'hljs.initHighlightingOnLoad()' }
      styles  << { href: [hjs_base, "styles/#{hjs_theme}.min.css"] }
    end

    styles.each do |item|
      tags << if item.key?(:text)
                html_tag(:style) { item[:text] }
              else
                html_tag(:link, rel: 'stylesheet', href: urlize(*item[:href]))
              end
    end

    scripts.each do |item|
      tags << if item.key? :text
                html_tag(:script, type: item[:type]) { item[:text] }
              else
                html_tag(:script, type: item[:type], src: urlize(*item[:src]))
              end
    end

    if defined?(::Asciidoctor::SyntaxHighlighter) && (hl = syntax_highlighter) # Asciidoctor >=2.0.0
      # XXX: We don't care about the declared location and put all to head.
      %i[head footer].each do |location|
        if hl.docinfo?(location)
          tags << hl.docinfo(location, self, cdn_base_url: CDN_BASE_URI, linkcss: attr?(:linkcss))
        end
      end
    end

    tags.join("\n")
  end

  #--------------------------------------------------------
  # inline_anchor
  #

  # @return [String] text of the xref anchor.
  def xref_text
    str =
      if text
        text
      elsif (path = local_attr :path)
        path
      else
        ref = document.catalog[:refs][attr :refid]
        ref.xreftext(attr(:xrefstyle, nil, true)) if ref.is_a? Asciidoctor::AbstractNode
      end
    (str || "[#{attr :refid}]").tr_s("\n", ' ')
  end

  # @return [String, nil] text of the bibref anchor, or +nil+ if not found.
  def bibref_text
    if ::Asciidoctor::VERSION[0] == '1'
      text
    else # Asciidoctor >= 2.0.0
      "[#{reftext || id}]"
    end
  end

  #--------------------------------------------------------
  # inline_image
  #

  # @return [Array] style classes for a Font Awesome icon.
  def icon_fa_classes
    ["fa fa-#{target}",
     ("fa-#{attr :size}" if attr? :size),
     ("fa-rotate-#{attr :rotate}" if attr? :rotate),
     ("fa-flip-#{attr :flip}" if attr? :flip)].compact
  end

  #--------------------------------------------------------
  # inline_quoted
  #

  # @param text [String] the text to wrap in double quotes.
  # @return [String] quoted *text*.
  def double_quoted(text)
    quotes = CURLY_QUOTES[attr(:lang, DEFAULT_LANG, true)]
    "#{quotes[2]}#{text}#{quotes[3]}"
  end

  # @param text [String] the text to wrap in single quotes.
  # @return [String] quoted *text*.
  def single_quoted(text)
    quotes = CURLY_QUOTES[attr(:lang, DEFAULT_LANG, true)]
    "#{quotes[0]}#{text}#{quotes[1]}"
  end
end
