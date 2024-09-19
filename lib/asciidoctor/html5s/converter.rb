# This file has been generated!

module Asciidoctor; module Html5s; end end
class Asciidoctor::Html5s::Converter < ::Asciidoctor::Converter::Base

  #------------------------------ Begin of Helpers ------------------------------#

  require 'asciidoctor/html5s'
  require 'date' unless RUBY_PLATFORM == 'opal'

  # Add custom functions to this module that you want to use in your Slim
  # templates. Within the template you can invoke them as top-level functions
  # just like in Haml.
  module Helpers

    # URIs of external assets.
    CDN_BASE_URI         = 'https://cdnjs.cloudflare.com/ajax/libs'  # for highlighters in Asciidoctor >=2.0.0
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
      [%w[af en eo ga hi ia id ko mt th tr zh], ['&#x2018;', '&#x2019;', '&#x201c;', '&#x201d;']],  # ‘…’ “…”
      [%w[bs fi sv], ['&#x2019;', '&#x2019;', '&#x201d;', '&#x201d;']],  # ’…’ ”…”
      [%w[cs da de is lt sl sk sr], ['&#x201a;', '&#x2018;', '&#x201e;', '&#x201c;']],  # ‚…‘ „…“
      [%w[nl], ['&#x201a;', '&#x2019;', '&#x201e;', '&#x201d;']],  # ‚…’ „…”
      [%w[hu pl ro], ['&#x00ab;', '&#x00bb;', '&#x201e;', '&#x201d;']],  # «…» „…”
    ].reduce({}) do |hsh, (langs, codes)|
      langs.each { |lang| hsh[lang] = codes }
      hsh
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

    VOID_ELEMENTS = %w(area base br col command embed hr img input keygen link
                       meta param source track wbr)


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
      @_html5s_capture.call(*params) if @_html5s_capture
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
      attrs = attributes.inject([]) do |attrs, (k, v)|
        next attrs if !v || v.nil_or_empty?
        v = v.compact.join(' ') if v.is_a? Array
        attrs << (v == true ? k : %(#{k}="#{v}"))
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
    def html_tag_if(condition, name, attributes = {}, content = nil, &block)
      if condition
        html_tag name, attributes, content, &block
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
    def block_with_title(attrs = {}, title = @title, &block)
      if (klass = attrs[:class]).is_a? String
        klass = klass.split(' ')
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
          [html_tag(:h6, {class: 'block-title'}, title), yield].join("\n")
        end
      end
    end

    def block_with_caption(position = :bottom, attrs = {}, &block)
      if (klass = attrs[:class]).is_a? String
        klass = klass.split(' ')
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
      if (@_html5s_stem_type ||= document.attr('html5s-force-stem-type'))
        type = @_html5s_stem_type
      end

      if is_a? ::Asciidoctor::Block
        open, close = ::Asciidoctor::BLOCK_MATH_DELIMITERS[type.to_sym]
      else
        open, close = ::Asciidoctor::INLINE_MATH_DELIMITERS[type.to_sym]
      end

      if !equation.start_with?(open) || !equation.end_with?(close)
        equation = [open, equation, close].join
      end
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
      [ (html_tag_if(wrap, :p) { item.text } if item.text?), item.content ].join
    end

    ##
    # Returns corrected section level.
    #
    # @param sec [Asciidoctor::Section] the section node (default: self).
    # @return [Integer]
    #
    def section_level(sec = self)
      (sec.level == 0 && sec.special) ? 1 : sec.level
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
        title.gsub(/<(?:a[^>+]+|\/a)>/, '')
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
        'note'  # https://www.w3.org/TR/wai-aria/roles#note
      when 'tip'
        'doc-tip'  # https://www.w3.org/TR/dpub-aria-1.0/#doc-tip
      when 'caution', 'important', 'warning'
        'doc-notice'  # https://www.w3.org/TR/dpub-aria-1.0/#doc-notice
      end
    end

    #--------------------------------------------------------
    # block_image
    #

    ##
    # @return [String, nil] an URL for the image's link.
    def image_link
      @_html5s_image_link ||=
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
      if image_uri(attr(:target)) == image_link
        document.attr('html5s-image-self-link-label', 'Open the image in full size')
      end
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
      if result = (parent == document && document.doctype == 'book')
        log.warn 'asciidoctor: WARNING: abstract block cannot be used in a document
  without a title when doctype is book. Excluding block content.'
      end
      !result
    end

    ##
    # Returns +true+ if a partintro block is allowed in this context, otherwise
    # prints warning and returns +false+.
    def partintro_allowed?
      if result = (level != 0 || parent.context != :section || document.doctype != 'book')
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
      if !autowidth? || local_attr?('width')
        'stretch' if attr? :tablepcwidth, 100
      end
    end

    #--------------------------------------------------------
    # block_video
    #

    # @return [Boolean] +true+ if the video should be embedded in an iframe.
    def video_iframe?
      ['vimeo', 'youtube'].include? attr(:poster)
    end

    def video_uri
      case attr(:poster, '').to_sym
      when :vimeo
        params = {
          autoplay: (1 if option? 'autoplay'),
          loop:     (1 if option? 'loop'),
          muted:    (1 if option? 'muted')
        }
        start_anchor = "#at=#{attr :start}" if attr? :start
        "//player.vimeo.com/video/#{attr :target}#{start_anchor}#{url_query params}"

      when :youtube
        video_id, list_id = attr(:target).split('/', 2)
        params = {
          rel:      0,
          start:    (attr :start),
          end:      (attr :end),
          list:     (attr :list, list_id),
          autoplay: (1 if option? 'autoplay'),
          loop:     (1 if option? 'loop'),
          muted:    (1 if option? 'muted'),
          controls: (0 if option? 'nocontrols')
        }
        "//www.youtube.com/embed/#{video_id}#{url_query params}"
      else
        anchor = [attr(:start), attr(:end)].join(',').chomp(',')
        anchor = '' if anchor == ','  # XXX: https://github.com/opal/opal/issues/1902
        anchor = '#t=' + anchor unless anchor.empty?
        media_uri "#{attr :target}#{anchor}"
      end
    end

    # Formats URL query parameters.
    def url_query(params)
      str = params.map { |k, v|
        next if v.nil? || v.to_s.empty?
        [k, v] * '='
      }.compact.join('&amp;')

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
        if attr? 'iconfont-remote'
          styles << { href: attr('iconfont-cdn', FONT_AWESOME_URI) }
        else
          styles << { href: [stylesdir, "#{attr 'iconfont-name', 'font-awesome'}.css"] }
        end
      end

      if attr? 'stem'
        styles << { href: KATEX_CSS_URI }
        scripts << { src: KATEX_JS_URI }
        scripts << { text: KATEX_RENDER_CODE }
      end

      if !defined?(::Asciidoctor::SyntaxHighlighter)  # Asciidoctor <2.0.0
        if attr? 'source-highlighter', 'highlightjs'
          hjs_base = attr :highlightjsdir, HIGHLIGHTJS_BASE_URI
          hjs_theme = attr 'highlightjs-theme', DEFAULT_HIGHLIGHTJS_THEME

          scripts << { src: [hjs_base, 'highlight.min.js'] }
          scripts << { text: 'hljs.initHighlightingOnLoad()' }
          styles  << { href: [hjs_base, "styles/#{hjs_theme}.min.css"] }
        end
      end

      styles.each do |item|
        if item.key?(:text)
          tags << html_tag(:style) { item[:text] }
        else
          tags << html_tag(:link, rel: 'stylesheet', href: urlize(*item[:href]))
        end
      end

      scripts.each do |item|
        if item.key? :text
          tags << html_tag(:script, type: item[:type]) { item[:text] }
        else
          tags << html_tag(:script, type: item[:type], src: urlize(*item[:src]))
        end
      end

      if defined?(::Asciidoctor::SyntaxHighlighter) && (hl = syntax_highlighter)  # Asciidoctor >=2.0.0
        # XXX: We don't care about the declared location and put all to head.
        [:head, :footer].each do |location|
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
          if ref.kind_of? Asciidoctor::AbstractNode
            ref.xreftext(attr(:xrefstyle, nil, true))
          end
        end
      (str || "[#{attr :refid}]").tr_s("\n", ' ')
    end

    # @return [String, nil] text of the bibref anchor, or +nil+ if not found.
    def bibref_text
      if ::Asciidoctor::VERSION[0] == '1'
        text
      else  # Asciidoctor >= 2.0.0
        "[#{reftext || id}]"
      end
    end

    #--------------------------------------------------------
    # inline_image
    #

    # @return [Array] style classes for a Font Awesome icon.
    def icon_fa_classes
      [ "fa fa-#{target}",
        ("fa-#{attr :size}" if attr? :size),
        ("fa-rotate-#{attr :rotate}" if attr? :rotate),
        ("fa-flip-#{attr :flip}" if attr? :flip)
      ].compact
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


  # Make Helpers' constants accessible from transform methods.
  Helpers.constants.each do |const|
    const_set(const, Helpers.const_get(const))
  end

  #------------------------------- End of Helpers -------------------------------#


  register_for "html5s"

  def initialize(backend, opts = {})
    super
    basebackend "html" if respond_to? :basebackend
    outfilesuffix ".html" if respond_to? :outfilesuffix
    filetype "html" if respond_to? :filetype
    supports_templates if respond_to? :supports_templates
  end

  def convert(node, transform = nil, opts = {})
    transform ||= node.node_name
    opts ||= {}
    converter = self

    if opts.empty?
      converter.send(transform, node)
    else
      converter.send(transform, node, opts)
    end
  end

  def handles?(transform)
    respond_to?("convert_#{transform}") || respond_to?(transform)
  end

  #----------------- Begin of generated transformation methods -----------------#


  def admonition(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; capture do; 
      ; _buf << ("<h6"); _temple_html_attributeremover1 = []; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "block-title"; _temple_html_attributemerger1[1] = []; _slim_codeattributes1 = ('label-only' unless title?); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << (_slim_codeattributes1.join(" ")); else; _temple_html_attributemerger1[1] << (_slim_codeattributes1); end; _temple_html_attributemerger1[1] = _temple_html_attributemerger1[1].join(""); _temple_html_attributeremover1 << (_temple_html_attributemerger1.reject(&:empty?).join(" ")); _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << ("><span class=\"title-label\">"); 
      ; _buf << ("#{local_attr :textlabel}: "); 
      ; _buf << ("</span>"); _buf << (title); 
      ; _buf << ("</h6>"); _slim_controls1 = html_tag_if !blocks?, :p do; _slim_controls2 = []; 
      ; _slim_controls2 << (content); 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); end; if admonition_aside?; 
      ; _buf << ("<aside"); _temple_html_attributeremover2 = []; _temple_html_attributemerger2 = []; _temple_html_attributemerger2[0] = "admonition-block"; _temple_html_attributemerger2[1] = []; _slim_codeattributes2 = [(attr :name), role]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributemerger2[1] << (_slim_codeattributes2.join(" ")); else; _temple_html_attributemerger2[1] << (_slim_codeattributes2); end; _temple_html_attributemerger2[1] = _temple_html_attributemerger2[1].join(""); _temple_html_attributeremover2 << (_temple_html_attributemerger2.reject(&:empty?).join(" ")); _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover2); _buf << ("\""); end; _slim_codeattributes3 = id; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _slim_codeattributes4 = admonition_aria; if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" role"); else; _buf << (" role=\""); _buf << (_slim_codeattributes4); _buf << ("\""); end; end; _buf << (">"); 
      ; yield_capture; 
      ; _buf << ("</aside>"); else; 
      ; _buf << ("<section"); _temple_html_attributeremover3 = []; _temple_html_attributemerger3 = []; _temple_html_attributemerger3[0] = "admonition-block"; _temple_html_attributemerger3[1] = []; _slim_codeattributes5 = [(attr :name), role]; if Array === _slim_codeattributes5; _slim_codeattributes5 = _slim_codeattributes5.flatten; _slim_codeattributes5.map!(&:to_s); _slim_codeattributes5.reject!(&:empty?); _temple_html_attributemerger3[1] << (_slim_codeattributes5.join(" ")); else; _temple_html_attributemerger3[1] << (_slim_codeattributes5); end; _temple_html_attributemerger3[1] = _temple_html_attributemerger3[1].join(""); _temple_html_attributeremover3 << (_temple_html_attributemerger3.reject(&:empty?).join(" ")); _temple_html_attributeremover3 = _temple_html_attributeremover3.join(""); if !_temple_html_attributeremover3.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover3); _buf << ("\""); end; _slim_codeattributes6 = id; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes6); _buf << ("\""); end; end; _slim_codeattributes7 = admonition_aria; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" role"); else; _buf << (" role=\""); _buf << (_slim_codeattributes7); _buf << ("\""); end; end; _buf << (">"); 
      ; yield_capture; 
      ; _buf << ("</section>"); end; _buf = _buf.join("")
    end
  end

  def audio(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_caption :bottom, :class=>'audio-block' do; _slim_controls2 = []; 
      ; 
      ; 
      ; 
      ; 
      ; _slim_controls2 << ("<audio"); _slim_codeattributes1 = media_uri(attr :target); if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes1); _slim_controls2 << ("\""); end; end; _slim_codeattributes2 = (option? 'autoplay'); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" autoplay"); else; _slim_controls2 << (" autoplay=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_codeattributes3 = !(option? 'nocontrols'); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" controls"); else; _slim_controls2 << (" controls=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_codeattributes4 = (option? 'loop'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" loop"); else; _slim_controls2 << (" loop=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">Your browser does not support the audio tag.</audio>"); 
      ; 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def colist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; 
      ; _buf << ("<ol"); _temple_html_attributeremover1 = []; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "callout-list"; _temple_html_attributemerger1[1] = []; _slim_codeattributes1 = [style, role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << (_slim_codeattributes1.join(" ")); else; _temple_html_attributemerger1[1] << (_slim_codeattributes1); end; _temple_html_attributemerger1[1] = _temple_html_attributemerger1[1].join(""); _temple_html_attributeremover1 << (_temple_html_attributemerger1.reject(&:empty?).join(" ")); _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _slim_codeattributes2 = id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes2); _buf << ("\""); end; end; _buf << (">"); 
      ; items.each do |item|; 
      ; _buf << ("<li>"); _buf << (item.text); 
      ; _buf << ("</li>"); end; _buf << ("</ol>"); _buf = _buf.join("")
    end
  end

  def dlist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_title :class=>['dlist', style], :role=>('doc-qna' if style == 'qanda') do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<dl"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = style; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); 
      ; items.each do |terms, dd|; 
      ; [*terms].each do |dt|; 
      ; _slim_controls2 << ("<dt>"); _slim_controls2 << (dt.text); 
      ; _slim_controls2 << ("</dt>"); end; unless dd.nil?; 
      ; _slim_controls2 << ("<dd>"); _slim_controls2 << ((print_item_content dd)); 
      ; _slim_controls2 << ("</dd>"); end; end; _slim_controls2 << ("</dl>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def document(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << ("<!DOCTYPE html><html"); 
      ; _slim_codeattributes1 = (attr :lang, 'en' unless attr? :nolang); if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" lang"); else; _buf << (" lang=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _buf << (">"); 
      ; 
      ; 
      ; 
      ; 
      ; document_content = content; 
      ; _buf << ("<head><meta"); 
      ; _slim_codeattributes2 = (attr :encoding, 'UTF-8'); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" charset"); else; _buf << (" charset=\""); _buf << (_slim_codeattributes2); _buf << ("\""); end; end; _buf << ("><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><meta name=\"generator\" content=\"Asciidoctor "); 
      ; 
      ; 
      ; _buf << (attr 'asciidoctor-version'); _buf << ("\">"); 
      ; _buf << (html_meta_if 'application-name', (attr 'app-name')); 
      ; _buf << (html_meta_if 'author', (attr :authors)); 
      ; _buf << (html_meta_if 'copyright', (attr :copyright)); 
      ; _buf << (html_meta_if 'description', (attr :description)); 
      ; _buf << (html_meta_if 'keywords', (attr :keywords)); 
      ; _buf << ("<title>"); _buf << (((doctitle sanitize: true) || (attr 'untitled-label'))); 
      ; _buf << ("</title>"); _buf << (styles_and_scripts); 
      ; unless (docinfo_content = docinfo).empty?; 
      ; _buf << (docinfo_content); 
      ; end; _buf << ("</head><body"); 
      ; 
      ; 
      ; _slim_codeattributes3 = id; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _temple_html_attributeremover1 = []; _slim_codeattributes4 = [(attr :doctype),
      ("#{attr 'toc-class'} toc-#{attr 'toc-position', 'left'}" if (attr? 'toc-class') && (attr? :toc) && (attr? 'toc-placement', 'auto')),
      (attr :docrole) || (attr :role)]; if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes4.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes4); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _slim_codeattributes5 = style_value(max_width: (attr 'max-width')); if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" style"); else; _buf << (" style=\""); _buf << (_slim_codeattributes5); _buf << ("\""); end; end; _buf << (">"); 
      ; unless (docinfo_content = (docinfo :header)).empty?; 
      ; _buf << (docinfo_content); 
      ; end; unless noheader; 
      ; _buf << ("<header>"); 
      ; if header?; 
      ; unless notitle; 
      ; _buf << ("<h1>"); _buf << (header.title); 
      ; _buf << ("</h1>"); end; if [:author, :revnumber, :revdate, :revremark].any? {|a| attr? a }; 
      ; _buf << ("<div class=\"details\">"); 
      ; if attr? :author; 
      ; _buf << ("<span class=\"author\" id=\"author\">"); _buf << ((attr :author)); 
      ; _buf << ("</span><br>"); 
      ; if attr? :email; 
      ; _buf << ("<span class=\"email\" id=\"email\">"); _buf << (sub_macros(attr :email)); 
      ; _buf << ("</span><br>"); 
      ; end; if (authorcount = (attr :authorcount).to_i) > 1; 
      ; (2..authorcount).each do |idx|; 
      ; _buf << ("<span class=\"author\" id=\"author"); _buf << (idx); _buf << ("\">"); _buf << ((attr "author_#{idx}")); 
      ; _buf << ("</span><br>"); 
      ; if attr? "email_#{idx}"; 
      ; _buf << ("<span class=\"email\" id=\"email"); _buf << (idx); _buf << ("\">"); _buf << (sub_macros(attr "email_#{idx}")); 
      ; _buf << ("</span>"); end; end; end; end; if attr? :revnumber; 
      ; _buf << ("<span id=\"revnumber\">"); _buf << (((attr 'version-label') || '').downcase); _buf << (" "); _buf << (attr :revnumber); _buf << (',' if attr? :revdate); _buf << ("</span> "); 
      ; 
      ; end; if attr? :revdate; 
      ; _buf << ("<time id=\"revdate\""); _slim_codeattributes6 = revdate_iso; if _slim_codeattributes6; if _slim_codeattributes6 == true; _buf << (" datetime"); else; _buf << (" datetime=\""); _buf << (_slim_codeattributes6); _buf << ("\""); end; end; _buf << (">"); _buf << ((attr :revdate)); 
      ; _buf << ("</time>"); end; if attr? :revremark; 
      ; _buf << ("<br><span id=\"revremark\">"); 
      ; _buf << ((attr :revremark)); 
      ; _buf << ("</span>"); end; _buf << ("</div>"); end; end; if (attr? :toc) && (attr? 'toc-placement', 'auto'); 
      ; _buf << ("<nav id=\"toc\""); _temple_html_attributeremover2 = []; _slim_codeattributes7 = (document.attr 'toc-class', 'toc'); if Array === _slim_codeattributes7; _slim_codeattributes7 = _slim_codeattributes7.flatten; _slim_codeattributes7.map!(&:to_s); _slim_codeattributes7.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes7.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes7); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover2); _buf << ("\""); end; _buf << (" role=\"doc-toc\"><h2 id=\"toc-title\">"); 
      ; _buf << ((document.attr 'toc-title')); 
      ; _buf << ("</h2>"); 
      ; _buf << (converter.convert document, 'outline'); 
      ; _buf << ("</nav>"); 
      ; end; 
      ; _buf << ("</header>"); end; _buf << ("<div id=\"content\">"); _buf << (document_content); 
      ; _buf << ("</div>"); unless !footnotes? || (attr? :nofootnotes); 
      ; _buf << ("<section class=\"footnotes\" aria-label=\"Footnotes\" role=\"doc-endnotes\"><hr><ol class=\"footnotes\">"); 
      ; 
      ; 
      ; footnotes.each do |fn|; 
      ; _buf << ("<li class=\"footnote\""); _slim_codeattributes8 = (footnote_id fn.index); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes8); _buf << ("\""); end; end; _buf << (" role=\"doc-endnote\">"); 
      ; _buf << ("#{fn.text} "); 
      ; 
      ; 
      ; 
      ; _buf << ("<a class=\"footnote-backref\" href=\"#"); _buf << (footnoteref_id fn.index); _buf << ("\" role=\"doc-backlink\" title=\"Jump to the first occurrence in the text\">&#8617;</a></li>"); 
      ; 
      ; end; _buf << ("</ol></section>"); 
      ; end; unless nofooter; 
      ; _buf << ("<footer><div id=\"footer-text\">"); 
      ; 
      ; if attr? :revnumber; 
      ; _buf << (attr 'version-label'); _buf << (" "); _buf << (attr :revnumber); 
      ; end; if attr? 'last-update-label'; 
      ; _buf << ("<br>"); 
      ; _buf << (attr 'last-update-label'); _buf << (" "); _buf << (attr :docdatetime); 
      ; end; _buf << ("</div>"); unless (docinfo_content = (docinfo :footer)).empty?; 
      ; _buf << (docinfo_content); 
      ; end; 
      ; _buf << ("</footer>"); end; _buf << ("</body></html>"); _buf = _buf.join("")
    end
  end

  def embedded(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; if !notitle && header?; 
      ; _buf << ("<h1"); _slim_codeattributes1 = id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _buf << (">"); _buf << (header.title); 
      ; _buf << ("</h1>"); end; if node.sections? && (attr? :toc) && (attr 'toc-placement', 'auto') == 'auto'; 
      ; _buf << ("<nav id=\"toc\""); _temple_html_attributeremover1 = []; _slim_codeattributes2 = (document.attr 'toc-class', 'toc'); if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (" role=\"doc-toc\"><h2 id=\"toc-title\">"); 
      ; _buf << ((document.attr 'toc-title')); 
      ; _buf << ("</h2>"); 
      ; _buf << (converter.convert document, 'outline'); 
      ; _buf << ("</nav>"); 
      ; end; _buf << (content); 
      ; if footnotes? && !(attr? :nofootnotes); 
      ; _buf << ("<section class=\"footnotes\" aria-label=\"Footnotes\" role=\"doc-endnotes\"><hr><ol class=\"footnotes\">"); 
      ; 
      ; 
      ; footnotes.each do |fn|; 
      ; _buf << ("<li class=\"footnote\""); _slim_codeattributes3 = (footnote_id fn.index); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _buf << (" role=\"doc-endnote\">"); 
      ; _buf << ("#{fn.text} "); 
      ; 
      ; 
      ; 
      ; _buf << ("<a class=\"footnote-backref\" href=\"#"); _buf << (footnoteref_id fn.index); _buf << ("\" role=\"doc-backlink\" title=\"Jump to the first occurrence in the text\">&#8617;</a></li>"); 
      ; 
      ; end; _buf << ("</ol></section>"); 
      ; end; _buf = _buf.join("")
    end
  end

  def empty(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; ; _buf = _buf.join("")
    end
  end

  def example(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; if option? :collapsible; 
      ; _buf << ("<details"); _slim_codeattributes1 = id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _temple_html_attributeremover1 = []; _slim_codeattributes2 = role; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _slim_codeattributes3 = (option? :open); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" open"); else; _buf << (" open=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _buf << (">"); 
      ; if title; 
      ; _buf << ("<summary>"); 
      ; _buf << (title); 
      ; _buf << ("</summary>"); end; _buf << ("<div class=\"content\">"); 
      ; _buf << (content); 
      ; _buf << ("</div></details>"); else; 
      ; _slim_controls1 = block_with_caption :top, :class=>'example-block' do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<div class=\"example\">"); 
      ; _slim_controls2 << (content); 
      ; _slim_controls2 << ("</div>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); end; _buf = _buf.join("")
    end
  end

  def floating_title(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_htag_filter1 = ((level + 1)).to_s; _buf << ("<h"); _buf << (_slim_htag_filter1); _slim_codeattributes1 = id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _temple_html_attributeremover1 = []; _slim_codeattributes2 = [style, role]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (">"); 
      ; _buf << (title); 
      ; _buf << ("</h"); _buf << (_slim_htag_filter1); _buf << (">"); _buf = _buf.join("")
    end
  end

  def image(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_caption(:bottom, :class=>'image-block', :style=>style_value(text_align: (attr :align), float: (attr :float))) do; _slim_controls2 = []; 
      ; target_url = image_uri(attr :target); 
      ; _slim_controls3 = html_tag_if(image_link, :a,
      :class=>['image', ('bare' if image_link == target_url)],
      :href=>image_link,
      :title=>image_link_label,
      'aria-label'=>image_link_label,
      :target=>(attr :window),
      :rel=>link_rel) do; _slim_controls4 = []; 
      ; _slim_controls4 << ("<img"); _slim_codeattributes1 = target_url; if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls4 << (" src"); else; _slim_controls4 << (" src=\""); _slim_controls4 << (_slim_codeattributes1); _slim_controls4 << ("\""); end; end; _slim_codeattributes2 = (attr :alt); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls4 << (" alt"); else; _slim_controls4 << (" alt=\""); _slim_controls4 << (_slim_codeattributes2); _slim_controls4 << ("\""); end; end; _slim_codeattributes3 = (attr :width); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls4 << (" width"); else; _slim_controls4 << (" width=\""); _slim_controls4 << (_slim_codeattributes3); _slim_controls4 << ("\""); end; end; _slim_codeattributes4 = (attr :height); if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls4 << (" height"); else; _slim_controls4 << (" height=\""); _slim_controls4 << (_slim_codeattributes4); _slim_controls4 << ("\""); end; end; _slim_codeattributes5 = (attr :loading); if _slim_codeattributes5; if _slim_codeattributes5 == true; _slim_controls4 << (" loading"); else; _slim_controls4 << (" loading=\""); _slim_controls4 << (_slim_codeattributes5); _slim_controls4 << ("\""); end; end; _slim_controls4 << (">"); 
      ; _slim_controls4 = _slim_controls4.join(""); end; _slim_controls2 << (_slim_controls3); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def inline_anchor(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; case type; 
      ; when :xref; 
      ; _buf << ("<a"); _slim_codeattributes1 = target; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" href"); else; _buf << (" href=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _temple_html_attributeremover1 = []; _slim_codeattributes2 = role; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (">"); _buf << (xref_text); 
      ; _buf << ("</a>"); when :ref; 
      ; _buf << ("<a"); _slim_codeattributes3 = id; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _buf << (" aria-hidden=\"true\"></a>"); 
      ; when :bibref; 
      ; _buf << ("<a"); _slim_codeattributes4 = id; if _slim_codeattributes4; if _slim_codeattributes4 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes4); _buf << ("\""); end; end; _buf << (" aria-hidden=\"true\"></a>"); 
      ; _buf << (bibref_text); 
      ; else; 
      ; _buf << ("<a"); _slim_codeattributes5 = id; if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes5); _buf << ("\""); end; end; _temple_html_attributeremover2 = []; _slim_codeattributes6 = role; if Array === _slim_codeattributes6; _slim_codeattributes6 = _slim_codeattributes6.flatten; _slim_codeattributes6.map!(&:to_s); _slim_codeattributes6.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes6.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes6); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover2); _buf << ("\""); end; _slim_codeattributes7 = target; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" href"); else; _buf << (" href=\""); _buf << (_slim_codeattributes7); _buf << ("\""); end; end; _slim_codeattributes8 = (attr :window); if _slim_codeattributes8; if _slim_codeattributes8 == true; _buf << (" target"); else; _buf << (" target=\""); _buf << (_slim_codeattributes8); _buf << ("\""); end; end; _slim_codeattributes9 = link_rel; if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" rel"); else; _buf << (" rel=\""); _buf << (_slim_codeattributes9); _buf << ("\""); end; end; _slim_codeattributes10 = (attr :title); if _slim_codeattributes10; if _slim_codeattributes10 == true; _buf << (" title"); else; _buf << (" title=\""); _buf << (_slim_codeattributes10); _buf << ("\""); end; end; _buf << (">"); _buf << (text); 
      ; _buf << ("</a>"); end; _buf = _buf.join("")
    end
  end

  def inline_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << (text); 
      ; _buf << ("<br>"); 
      ; _buf = _buf.join("")
    end
  end

  def inline_button(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << ("<kbd class=\"button\"><samp>"); 
      ; _buf << (text); 
      ; _buf << ("</samp></kbd>"); _buf = _buf.join("")
    end
  end

  def inline_callout(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << ("<b class=\"conum\""); _slim_codeattributes1 = text; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" data-value"); else; _buf << (" data-value=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _buf << (">"); _buf << (text); 
      ; _buf << ("</b>"); _buf = _buf.join("")
    end
  end

  def inline_footnote(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; if (index = local_attr :index); 
      ; _buf << ("<sup><a class=\"footnote-ref\""); 
      ; 
      ; 
      ; 
      ; 
      ; _slim_codeattributes1 = (footnoteref_id unless type == :xref); if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _buf << (" href=\"#"); _buf << (footnote_id); _buf << ("\""); _slim_codeattributes2 = ((document.attr 'view-footnote', "View footnote") + " #{index}"); if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" title"); else; _buf << (" title=\""); _buf << (_slim_codeattributes2); _buf << ("\""); end; end; _buf << (" role=\"doc-noteref\">"); 
      ; _buf << (index); 
      ; _buf << ("</a></sup>"); else; 
      ; _buf << ("<a class=\"footnote-ref broken\" title=\"Unresolved footnote reference.\">["); _buf << (text); _buf << ("]</a>"); 
      ; end; _buf = _buf.join("")
    end
  end

  def inline_image(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = html_tag_if((attr? :link), :a, :class=>'image', :href=>(attr :link), :target=>(attr :window), :rel=>link_rel) do; _slim_controls2 = []; 
      ; if type == 'icon' && (document.attr? :icons, 'font'); 
      ; _slim_controls2 << ("<i"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = [*icon_fa_classes, role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_codeattributes2 = (attr :title); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" title"); else; _slim_controls2 << (" title=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_controls2 << ("></i>"); 
      ; elsif type == 'icon' && !(document.attr? :icons); 
      ; _slim_controls2 << ("<b"); _temple_html_attributeremover2 = []; _slim_codeattributes3 = ['icon', role]; if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes3.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes3); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover2); _slim_controls2 << ("\""); end; _slim_codeattributes4 = (attr :title); if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" title"); else; _slim_controls2 << (" title=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">["); 
      ; _slim_controls2 << (attr :alt); _slim_controls2 << ("]</b>"); 
      ; else; 
      ; 
      ; 
      ; _slim_controls2 << ("<img"); _slim_codeattributes5 = (type == 'icon' ? (icon_uri target) : (image_uri target)); if _slim_codeattributes5; if _slim_codeattributes5 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes5); _slim_controls2 << ("\""); end; end; _slim_codeattributes6 = (attr :alt); if _slim_codeattributes6; if _slim_codeattributes6 == true; _slim_controls2 << (" alt"); else; _slim_controls2 << (" alt=\""); _slim_controls2 << (_slim_codeattributes6); _slim_controls2 << ("\""); end; end; _slim_codeattributes7 = (attr :width); if _slim_codeattributes7; if _slim_codeattributes7 == true; _slim_controls2 << (" width"); else; _slim_controls2 << (" width=\""); _slim_controls2 << (_slim_codeattributes7); _slim_controls2 << ("\""); end; end; _slim_codeattributes8 = (attr :height); if _slim_codeattributes8; if _slim_codeattributes8 == true; _slim_controls2 << (" height"); else; _slim_controls2 << (" height=\""); _slim_controls2 << (_slim_codeattributes8); _slim_controls2 << ("\""); end; end; _slim_codeattributes9 = (attr :title); if _slim_codeattributes9; if _slim_codeattributes9 == true; _slim_controls2 << (" title"); else; _slim_controls2 << (" title=\""); _slim_controls2 << (_slim_codeattributes9); _slim_controls2 << ("\""); end; end; _slim_codeattributes10 = (attr :loading); if _slim_codeattributes10; if _slim_codeattributes10 == true; _slim_controls2 << (" loading"); else; _slim_controls2 << (" loading=\""); _slim_controls2 << (_slim_codeattributes10); _slim_controls2 << ("\""); end; end; _temple_html_attributeremover3 = []; _slim_codeattributes11 = [(type if type != 'image'), role]; if Array === _slim_codeattributes11; _slim_codeattributes11 = _slim_codeattributes11.flatten; _slim_codeattributes11.map!(&:to_s); _slim_codeattributes11.reject!(&:empty?); _temple_html_attributeremover3 << (_slim_codeattributes11.join(" ")); else; _temple_html_attributeremover3 << (_slim_codeattributes11); end; _temple_html_attributeremover3 = _temple_html_attributeremover3.join(""); if !_temple_html_attributeremover3.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover3); _slim_controls2 << ("\""); end; _slim_codeattributes12 = style_value(float: (attr :float)); if _slim_codeattributes12; if _slim_codeattributes12 == true; _slim_controls2 << (" style"); else; _slim_controls2 << (" style=\""); _slim_controls2 << (_slim_codeattributes12); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); 
      ; end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def inline_indexterm(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; if type == :visible; 
      ; _buf << (text); 
      ; end; _buf = _buf.join("")
    end
  end

  def inline_kbd(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; if (keys = attr 'keys').size == 1; 
      ; _buf << ("<kbd class=\"key\">"); _buf << (keys.first); 
      ; _buf << ("</kbd>"); else; 
      ; _buf << ("<kbd class=\"keyseq\">"); 
      ; keys.each_with_index do |key, idx|; 
      ; _buf << ("+" unless idx.zero?); 
      ; _buf << ("<kbd class=\"key\">"); _buf << (key); 
      ; _buf << ("</kbd>"); end; _buf << ("</kbd>"); end; _buf = _buf.join("")
    end
  end

  def inline_menu(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; if local_attr :menuitem; 
      ; capture do; 
      ; _buf << ("&#160;<span class=\"caret\">&#8250;</span>&#32;"); 
      ; 
      ; 
      ; end; _buf << ("<kbd class=\"menuseq\"><kbd class=\"menu\"><samp>"); 
      ; 
      ; _buf << ((attr :menu)); 
      ; _buf << ("</samp></kbd>"); yield_capture; 
      ; (attr 'submenus').each do |submenu|; 
      ; _buf << ("<kbd class=\"menu\"><samp>"); 
      ; _buf << (submenu); 
      ; _buf << ("</samp></kbd>"); yield_capture; 
      ; end; _buf << ("<kbd class=\"menu\"><samp>"); 
      ; _buf << ((local_attr :menuitem)); 
      ; _buf << ("</samp></kbd></kbd>"); else; 
      ; _buf << ("<kbd class=\"menu\"><samp>"); 
      ; _buf << ((attr :menu)); 
      ; _buf << ("</samp></kbd>"); end; _buf = _buf.join("")
    end
  end

  def inline_quoted(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; case type; 
      ; when :emphasis; 
      ; _buf << ("<em"); _slim_codeattributes1 = id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _temple_html_attributeremover1 = []; _slim_codeattributes2 = role; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (">"); _buf << (text); 
      ; _buf << ("</em>"); when :strong; 
      ; _buf << ("<strong"); _slim_codeattributes3 = id; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _temple_html_attributeremover2 = []; _slim_codeattributes4 = role; if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes4.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes4); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover2); _buf << ("\""); end; _buf << (">"); _buf << (text); 
      ; _buf << ("</strong>"); when :monospaced; 
      ; _buf << ("<code"); _slim_codeattributes5 = id; if _slim_codeattributes5; if _slim_codeattributes5 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes5); _buf << ("\""); end; end; _temple_html_attributeremover3 = []; _slim_codeattributes6 = role; if Array === _slim_codeattributes6; _slim_codeattributes6 = _slim_codeattributes6.flatten; _slim_codeattributes6.map!(&:to_s); _slim_codeattributes6.reject!(&:empty?); _temple_html_attributeremover3 << (_slim_codeattributes6.join(" ")); else; _temple_html_attributeremover3 << (_slim_codeattributes6); end; _temple_html_attributeremover3 = _temple_html_attributeremover3.join(""); if !_temple_html_attributeremover3.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover3); _buf << ("\""); end; _buf << (">"); _buf << (text); 
      ; _buf << ("</code>"); when :superscript; 
      ; _buf << ("<sup"); _slim_codeattributes7 = id; if _slim_codeattributes7; if _slim_codeattributes7 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes7); _buf << ("\""); end; end; _temple_html_attributeremover4 = []; _slim_codeattributes8 = role; if Array === _slim_codeattributes8; _slim_codeattributes8 = _slim_codeattributes8.flatten; _slim_codeattributes8.map!(&:to_s); _slim_codeattributes8.reject!(&:empty?); _temple_html_attributeremover4 << (_slim_codeattributes8.join(" ")); else; _temple_html_attributeremover4 << (_slim_codeattributes8); end; _temple_html_attributeremover4 = _temple_html_attributeremover4.join(""); if !_temple_html_attributeremover4.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover4); _buf << ("\""); end; _buf << (">"); _buf << (text); 
      ; _buf << ("</sup>"); when :subscript; 
      ; _buf << ("<sub"); _slim_codeattributes9 = id; if _slim_codeattributes9; if _slim_codeattributes9 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes9); _buf << ("\""); end; end; _temple_html_attributeremover5 = []; _slim_codeattributes10 = role; if Array === _slim_codeattributes10; _slim_codeattributes10 = _slim_codeattributes10.flatten; _slim_codeattributes10.map!(&:to_s); _slim_codeattributes10.reject!(&:empty?); _temple_html_attributeremover5 << (_slim_codeattributes10.join(" ")); else; _temple_html_attributeremover5 << (_slim_codeattributes10); end; _temple_html_attributeremover5 = _temple_html_attributeremover5.join(""); if !_temple_html_attributeremover5.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover5); _buf << ("\""); end; _buf << (">"); _buf << (text); 
      ; _buf << ("</sub>"); when :mark; 
      ; _buf << ("<mark"); _slim_codeattributes11 = id; if _slim_codeattributes11; if _slim_codeattributes11 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes11); _buf << ("\""); end; end; _temple_html_attributeremover6 = []; _slim_codeattributes12 = role; if Array === _slim_codeattributes12; _slim_codeattributes12 = _slim_codeattributes12.flatten; _slim_codeattributes12.map!(&:to_s); _slim_codeattributes12.reject!(&:empty?); _temple_html_attributeremover6 << (_slim_codeattributes12.join(" ")); else; _temple_html_attributeremover6 << (_slim_codeattributes12); end; _temple_html_attributeremover6 = _temple_html_attributeremover6.join(""); if !_temple_html_attributeremover6.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover6); _buf << ("\""); end; _buf << (">"); _buf << (text); 
      ; _buf << ("</mark>"); when :double; 
      ; _slim_controls1 = html_tag_if role? || id, :span, :id=>id, :class=>role do; _slim_controls2 = []; 
      ; _slim_controls2 << ((double_quoted text)); 
      ; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); when :single; 
      ; _slim_controls3 = html_tag_if role? || id, :span, :id=>id, :class=>role do; _slim_controls4 = []; 
      ; _slim_controls4 << ((single_quoted text)); 
      ; _slim_controls4 = _slim_controls4.join(""); end; _buf << (_slim_controls3); when :asciimath, :latexmath; 
      ; _buf << ("<span class=\"math\""); _slim_codeattributes13 = id; if _slim_codeattributes13; if _slim_codeattributes13 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes13); _buf << ("\""); end; end; _slim_codeattributes14 = stem_lang; if _slim_codeattributes14; if _slim_codeattributes14 == true; _buf << (" data-lang"); else; _buf << (" data-lang=\""); _buf << (_slim_codeattributes14); _buf << ("\""); end; end; _buf << (">"); _buf << ((delimit_stem text, type)); 
      ; _buf << ("</span>"); else; 
      ; case role; 
      ; when 'line-through', 'strike'; 
      ; _buf << ("<s"); _slim_codeattributes15 = id; if _slim_codeattributes15; if _slim_codeattributes15 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes15); _buf << ("\""); end; end; _buf << (">"); _buf << (text); 
      ; _buf << ("</s>"); when 'del'; 
      ; _buf << ("<del"); _slim_codeattributes16 = id; if _slim_codeattributes16; if _slim_codeattributes16 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes16); _buf << ("\""); end; end; _buf << (">"); _buf << (text); 
      ; _buf << ("</del>"); when 'ins'; 
      ; _buf << ("<ins"); _slim_codeattributes17 = id; if _slim_codeattributes17; if _slim_codeattributes17 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes17); _buf << ("\""); end; end; _buf << (">"); _buf << (text); 
      ; _buf << ("</ins>"); else; 
      ; _slim_controls5 = html_tag_if role? || id, :span, :id=>id, :class=>role do; _slim_controls6 = []; 
      ; _slim_controls6 << (text); 
      ; _slim_controls6 = _slim_controls6.join(""); end; _buf << (_slim_controls5); end; end; _buf = _buf.join("")
    end
  end

  def listing(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_caption :top, :class=>'listing-block' do; _slim_controls2 = []; 
      ; if style == 'source'; 
      ; highlighter = document.attr('source-highlighter'); 
      ; 
      ; if defined?(::Asciidoctor::SyntaxHighlighter) && document.syntax_highlighter; 
      ; _slim_controls2 << (formatted_source); 
      ; 
      ; elsif highlighter == 'html-pipeline'; 
      ; _slim_controls2 << ("<pre><code"); _slim_codeattributes1 = source_lang; if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" data-lang"); else; _slim_controls2 << (" data-lang=\""); _slim_controls2 << (_slim_codeattributes1); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</code></pre>"); else; 
      ; 
      ; _slim_controls2 << ("<pre"); _temple_html_attributeremover1 = []; _slim_codeattributes2 = [highlighter, 'highlight', ('linenums' if attr? :linenums), nowrap?]; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_controls2 << ("><code"); 
      ; _temple_html_attributeremover2 = []; _slim_codeattributes3 = source_code_class; if Array === _slim_codeattributes3; _slim_codeattributes3 = _slim_codeattributes3.flatten; _slim_codeattributes3.map!(&:to_s); _slim_codeattributes3.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes3.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes3); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover2); _slim_controls2 << ("\""); end; _slim_codeattributes4 = source_lang; if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" data-lang"); else; _slim_controls2 << (" data-lang=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</code></pre>"); end; else; 
      ; _slim_controls2 << ("<pre"); _temple_html_attributeremover3 = []; _slim_codeattributes5 = nowrap?; if Array === _slim_codeattributes5; _slim_codeattributes5 = _slim_codeattributes5.flatten; _slim_codeattributes5.map!(&:to_s); _slim_codeattributes5.reject!(&:empty?); _temple_html_attributeremover3 << (_slim_codeattributes5.join(" ")); else; _temple_html_attributeremover3 << (_slim_codeattributes5); end; _temple_html_attributeremover3 = _temple_html_attributeremover3.join(""); if !_temple_html_attributeremover3.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover3); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</pre>"); 
      ; 
      ; end; if callout_list; 
      ; _slim_controls2 << (converter.convert callout_list, 'colist'); 
      ; end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def literal(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_title :class=>'literal-block' do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<pre"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = nowrap?; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</pre>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def olist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_title :class=>['olist', style] do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<ol"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = style; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_codeattributes2 = (attr :start); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" start"); else; _slim_controls2 << (" start=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_codeattributes3 = list_marker_keyword; if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" type"); else; _slim_controls2 << (" type=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_codeattributes4 = (option? 'reversed'); if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" reversed"); else; _slim_controls2 << (" reversed=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); 
      ; items.each do |item|; 
      ; _slim_controls2 << ("<li"); _slim_codeattributes5 = item.id; if _slim_codeattributes5; if _slim_codeattributes5 == true; _slim_controls2 << (" id"); else; _slim_controls2 << (" id=\""); _slim_controls2 << (_slim_codeattributes5); _slim_controls2 << ("\""); end; end; _temple_html_attributeremover2 = []; _slim_codeattributes6 = item.role; if Array === _slim_codeattributes6; _slim_codeattributes6 = _slim_codeattributes6.flatten; _slim_codeattributes6.map!(&:to_s); _slim_codeattributes6.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes6.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes6); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover2); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); _slim_controls2 << ((print_item_content item)); 
      ; _slim_controls2 << ("</li>"); end; _slim_controls2 << ("</ol>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def open(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; if style == 'abstract'; 
      ; if abstract_allowed?; 
      ; _slim_controls1 = block_with_title :class=>'quote-block abstract' do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<blockquote>"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</blockquote>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); end; elsif style != 'partintro' || partintro_allowed?; 
      ; _slim_controls3 = block_with_title :class=>['open-block', (style if style != 'open')] do; _slim_controls4 = []; 
      ; _slim_controls4 << ("<div class=\"content\">"); _slim_controls4 << (content); 
      ; _slim_controls4 << ("</div>"); _slim_controls4 = _slim_controls4.join(""); end; _buf << (_slim_controls3); end; _buf = _buf.join("")
    end
  end

  def outline(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; unless sections.empty?; 
      ; 
      ; toclevels ||= opts[:toclevels] || (document.attr 'toclevels', DEFAULT_TOCLEVELS).to_i; 
      ; slevel = section_level sections.first; 
      ; _buf << ("<ol class=\"toc-list level-"); _buf << (slevel); _buf << ("\">"); 
      ; sections.each do |sec|; 
      ; _buf << ("<li><a href=\"#"); 
      ; _buf << (sec.id); _buf << ("\">"); _buf << ((section_title sec, drop_anchors: true)); 
      ; _buf << ("</a>"); if (sec.level < toclevels) && (child_toc = converter.convert sec, 'outline'); 
      ; _buf << (child_toc); 
      ; end; _buf << ("</li>"); end; _buf << ("</ol>"); end; _buf = _buf.join("")
    end
  end

  def page_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << ("<div role=\"doc-pagebreak\" style=\"page-break-after: always;\"></div>"); 
      ; _buf = _buf.join("")
    end
  end

  def paragraph(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; if title?; 
      ; _buf << ("<section class=\"paragraph\""); _slim_codeattributes1 = id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _buf << ("><h6 class=\"block-title\">"); 
      ; _buf << (title); 
      ; _buf << ("</h6><p"); _temple_html_attributeremover1 = []; _slim_codeattributes2 = role; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (">"); _buf << (content); 
      ; _buf << ("</p></section>"); else; 
      ; _buf << ("<p"); _slim_codeattributes3 = id; if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _temple_html_attributeremover2 = []; _slim_codeattributes4 = role; if Array === _slim_codeattributes4; _slim_codeattributes4 = _slim_codeattributes4.flatten; _slim_codeattributes4.map!(&:to_s); _slim_codeattributes4.reject!(&:empty?); _temple_html_attributeremover2 << (_slim_codeattributes4.join(" ")); else; _temple_html_attributeremover2 << (_slim_codeattributes4); end; _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover2); _buf << ("\""); end; _buf << (">"); _buf << (content); 
      ; _buf << ("</p>"); end; _buf = _buf.join("")
    end
  end

  def pass(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << (content); 
      ; _buf = _buf.join("")
    end
  end

  def preamble(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << ("<section id=\"preamble\" aria-label=\"Preamble\">"); 
      ; _buf << (content); 
      ; _buf << ("</section>"); if (document.attr? :toc) && (document.attr? 'toc-placement', 'preamble'); 
      ; _buf << ("<nav id=\"toc\""); _temple_html_attributeremover1 = []; _slim_codeattributes1 = (document.attr 'toc-class', 'toc'); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (" role=\"doc-toc\"><h2 id=\"toc-title\">"); 
      ; _buf << ((document.attr 'toc-title')); 
      ; _buf << ("</h2>"); 
      ; _buf << (converter.convert document, 'outline'); 
      ; _buf << ("</nav>"); 
      ; end; _buf = _buf.join("")
    end
  end

  def quote(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_title :class=>'quote-block' do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<blockquote>"); 
      ; _slim_controls3 = html_tag_if !blocks?, :p do; _slim_controls4 = []; 
      ; _slim_controls4 << (content); 
      ; _slim_controls4 = _slim_controls4.join(""); end; _slim_controls2 << (_slim_controls3); if attr?(:attribution) || attr?(:citetitle); 
      ; _slim_controls2 << ("<footer>&#8212; <cite>"); 
      ; 
      ; 
      ; _slim_controls2 << ([(attr :attribution), (attr :citetitle)].compact.join(', ')); 
      ; _slim_controls2 << ("</cite></footer>"); 
      ; end; _slim_controls2 << ("</blockquote>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def section(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << ("<section"); _temple_html_attributeremover1 = []; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "doc-section"; _temple_html_attributemerger1[1] = []; _slim_codeattributes1 = ["level-#{section_level}", role]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << (_slim_codeattributes1.join(" ")); else; _temple_html_attributemerger1[1] << (_slim_codeattributes1); end; _temple_html_attributemerger1[1] = _temple_html_attributemerger1[1].join(""); _temple_html_attributeremover1 << (_temple_html_attributemerger1.reject(&:empty?).join(" ")); _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (">"); 
      ; _slim_htag_filter1 = ((section_level + 1)).to_s; _buf << ("<h"); _buf << (_slim_htag_filter1); _slim_codeattributes2 = id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes2); _buf << ("\""); end; end; _buf << (">"); 
      ; if id; 
      ; if document.attr? :sectanchors; 
      ; _buf << ("<a class=\"anchor\" href=\"#"); _buf << (id); _buf << ("\" aria-hidden=\"true\"></a>"); 
      ; end; if document.attr? :sectlinks; 
      ; _buf << ("<a class=\"link\" href=\"#"); _buf << (id); _buf << ("\">"); _buf << (section_title); 
      ; _buf << ("</a>"); else; 
      ; _buf << (section_title); 
      ; end; else; 
      ; _buf << (section_title); 
      ; end; _buf << ("</h"); _buf << (_slim_htag_filter1); _buf << (">"); _buf << (content); 
      ; _buf << ("</section>"); _buf = _buf.join("")
    end
  end

  def sidebar(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << ("<aside"); _temple_html_attributeremover1 = []; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "sidebar"; _temple_html_attributemerger1[1] = []; _slim_codeattributes1 = role; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributemerger1[1] << (_slim_codeattributes1.join(" ")); else; _temple_html_attributemerger1[1] << (_slim_codeattributes1); end; _temple_html_attributemerger1[1] = _temple_html_attributemerger1[1].join(""); _temple_html_attributeremover1 << (_temple_html_attributemerger1.reject(&:empty?).join(" ")); _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _slim_codeattributes2 = id; if _slim_codeattributes2; if _slim_codeattributes2 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes2); _buf << ("\""); end; end; _buf << (">"); 
      ; if title?; 
      ; _buf << ("<h6 class=\"block-title\">"); _buf << (title); 
      ; _buf << ("</h6>"); end; _buf << (content); 
      ; _buf << ("</aside>"); _buf = _buf.join("")
    end
  end

  def stem(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_caption :top, :class=>'stem-block' do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<div class=\"math\""); _slim_codeattributes1 = stem_lang; if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" data-lang"); else; _slim_controls2 << (" data-lang=\""); _slim_controls2 << (_slim_codeattributes1); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); _slim_controls2 << ((delimit_stem content, style)); 
      ; _slim_controls2 << ("</div>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def table(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_caption :top, :class=>'table-block' do; _slim_controls2 = []; 
      ; 
      ; 
      ; _slim_controls2 << ("<table"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = ["frame-#{attr :frame, 'all'}", "grid-#{attr :grid, 'all'}", stretch?, ("stripes-#{attr :stripes}" if attr? :stripes)]; if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_codeattributes2 = style_value(width: ("#{attr :tablepcwidth}%" if !autowidth? && !stretch? || (local_attr :width)),
      float: (attr :float)); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" style"); else; _slim_controls2 << (" style=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); 
      ; unless (attr :rowcount).zero?; 
      ; _slim_controls2 << ("<colgroup>"); 
      ; if autowidth?; 
      ; columns.each do; 
      ; _slim_controls2 << ("<col>"); 
      ; end; else; 
      ; columns.each do |col|; 
      ; _slim_controls2 << ("<col"); _slim_codeattributes3 = style_value(width: ("#{col.attr :colpcwidth}%" if !autowidth? col)); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" style"); else; _slim_controls2 << (" style=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">"); 
      ; end; end; _slim_controls2 << ("</colgroup>"); [:head, :foot, :body].reject { |tblsec| rows[tblsec].empty? }.each do |tblsec|; 
      ; _slim_controls2 << ("<t"); _slim_controls2 << (tblsec); _slim_controls2 << (">"); 
      ; rows[tblsec].each do |row|; 
      ; _slim_controls2 << ("<tr>"); 
      ; row.each do |cell|; 
      ; _slim_controls3 = html_tag(tblsec == :head || cell.style == :header ? 'th' : 'td',
      :class=>["halign-#{cell.attr :halign}", "valign-#{cell.attr :valign}"],
      :colspan=>cell.colspan,
      :rowspan=>cell.rowspan,
      :style=>style_value(background_color: (document.attr :cellbgcolor))) do; _slim_controls4 = []; 
      ; if tblsec == :head; 
      ; _slim_controls4 << (cell.text); 
      ; else; 
      ; case cell.style; 
      ; when :asciidoc; 
      ; _slim_controls4 << (cell.content); 
      ; when :literal; 
      ; _slim_controls4 << ("<div class=\"literal\"><pre>"); _slim_controls4 << (cell.text); 
      ; _slim_controls4 << ("</pre></div>"); else; 
      ; if (content = cell.content).one?; 
      ; _slim_controls4 << (content.first); 
      ; else; 
      ; content.each do |text|; 
      ; _slim_controls4 << ("<p>"); _slim_controls4 << (text); 
      ; _slim_controls4 << ("</p>"); end; end; end; end; _slim_controls4 = _slim_controls4.join(""); end; _slim_controls2 << (_slim_controls3); end; _slim_controls2 << ("</tr>"); end; _slim_controls2 << ("</t"); _slim_controls2 << (tblsec); _slim_controls2 << (">"); 
      ; end; end; _slim_controls2 << ("</table>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def thematic_break(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _buf << ("<hr>"); 
      ; _buf = _buf.join("")
    end
  end

  def toc(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; 
      ; 
      ; if document.attr?(:toc) && document.sections?; 
      ; toc_id = id || ('toc' if document.embedded? || !document.attr?('toc-placement')); 
      ; _buf << ("<nav"); _slim_codeattributes1 = toc_id; if _slim_codeattributes1; if _slim_codeattributes1 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes1); _buf << ("\""); end; end; _temple_html_attributeremover1 = []; _slim_codeattributes2 = (attr :role, (document.attr 'toc-class', 'toc')); if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes2.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes2); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _buf << (" class=\""); _buf << (_temple_html_attributeremover1); _buf << ("\""); end; _buf << (" role=\"doc-toc\">"); 
      ; _slim_htag_filter1 = ((level + 2)).to_s; _buf << ("<h"); _buf << (_slim_htag_filter1); _slim_codeattributes3 = ("#{toc_id}-title" if toc_id); if _slim_codeattributes3; if _slim_codeattributes3 == true; _buf << (" id"); else; _buf << (" id=\""); _buf << (_slim_codeattributes3); _buf << ("\""); end; end; _buf << (">"); 
      ; _buf << ((title || (document.attr 'toc-title'))); 
      ; _buf << ("</h"); _buf << (_slim_htag_filter1); _buf << (">"); 
      ; _buf << (converter.convert document, 'outline', :toclevels=>((attr :levels).to_i if attr? :levels)); 
      ; _buf << ("</nav>"); else; 
      ; _buf << ("<!--toc disabled-->"); 
      ; end; _buf = _buf.join("")
    end
  end

  def ulist(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; checklist = 'task-list' if option? 'checklist'; 
      ; _slim_controls1 = block_with_title :class=>['ulist', style] do; _slim_controls2 = []; 
      ; _slim_controls2 << ("<ul"); _temple_html_attributeremover1 = []; _slim_codeattributes1 = (checklist || style); if Array === _slim_codeattributes1; _slim_codeattributes1 = _slim_codeattributes1.flatten; _slim_codeattributes1.map!(&:to_s); _slim_codeattributes1.reject!(&:empty?); _temple_html_attributeremover1 << (_slim_codeattributes1.join(" ")); else; _temple_html_attributeremover1 << (_slim_codeattributes1); end; _temple_html_attributeremover1 = _temple_html_attributeremover1.join(""); if !_temple_html_attributeremover1.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover1); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); 
      ; items.each do |item|; 
      ; if checklist && (item.attr? :checkbox); 
      ; _slim_controls2 << ("<li"); _temple_html_attributeremover2 = []; _temple_html_attributemerger1 = []; _temple_html_attributemerger1[0] = "task-list-item"; _temple_html_attributemerger1[1] = []; _slim_codeattributes2 = item.role; if Array === _slim_codeattributes2; _slim_codeattributes2 = _slim_codeattributes2.flatten; _slim_codeattributes2.map!(&:to_s); _slim_codeattributes2.reject!(&:empty?); _temple_html_attributemerger1[1] << (_slim_codeattributes2.join(" ")); else; _temple_html_attributemerger1[1] << (_slim_codeattributes2); end; _temple_html_attributemerger1[1] = _temple_html_attributemerger1[1].join(""); _temple_html_attributeremover2 << (_temple_html_attributemerger1.reject(&:empty?).join(" ")); _temple_html_attributeremover2 = _temple_html_attributeremover2.join(""); if !_temple_html_attributeremover2.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover2); _slim_controls2 << ("\""); end; _slim_codeattributes3 = item.id; if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" id"); else; _slim_controls2 << (" id=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_controls2 << ("><input class=\"task-list-item-checkbox\" type=\"checkbox\" disabled"); 
      ; _slim_codeattributes4 = (item.attr? :checked); if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" checked"); else; _slim_controls2 << (" checked=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_controls2 << ("> "); 
      ; _slim_controls2 << (item.text); 
      ; _slim_controls2 << ("</li>"); else; 
      ; _slim_controls2 << ("<li"); _slim_codeattributes5 = item.id; if _slim_codeattributes5; if _slim_codeattributes5 == true; _slim_controls2 << (" id"); else; _slim_controls2 << (" id=\""); _slim_controls2 << (_slim_codeattributes5); _slim_controls2 << ("\""); end; end; _temple_html_attributeremover3 = []; _slim_codeattributes6 = item.role; if Array === _slim_codeattributes6; _slim_codeattributes6 = _slim_codeattributes6.flatten; _slim_codeattributes6.map!(&:to_s); _slim_codeattributes6.reject!(&:empty?); _temple_html_attributeremover3 << (_slim_codeattributes6.join(" ")); else; _temple_html_attributeremover3 << (_slim_codeattributes6); end; _temple_html_attributeremover3 = _temple_html_attributeremover3.join(""); if !_temple_html_attributeremover3.empty?; _slim_controls2 << (" class=\""); _slim_controls2 << (_temple_html_attributeremover3); _slim_controls2 << ("\""); end; _slim_controls2 << (">"); 
      ; _slim_controls2 << ((print_item_content item)); 
      ; _slim_controls2 << ("</li>"); end; end; _slim_controls2 << ("</ul>"); _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def verse(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_title :class=>'verse-block' do; _slim_controls2 = []; 
      ; if attr?(:attribution) || attr?(:citetitle); 
      ; _slim_controls2 << ("<blockquote class=\"verse\"><pre class=\"verse\">"); 
      ; _slim_controls2 << (content); 
      ; _slim_controls2 << ("</pre><footer>&#8212; <cite>"); 
      ; 
      ; 
      ; _slim_controls2 << ([(attr :attribution), (attr :citetitle)].compact.join(', ')); 
      ; _slim_controls2 << ("</cite></footer></blockquote>"); 
      ; else; 
      ; _slim_controls2 << ("<pre class=\"verse\">"); _slim_controls2 << (content); 
      ; _slim_controls2 << ("</pre>"); end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end

  def video(node, opts = {})
    node.extend(Helpers)
    node.instance_eval do
      _buf = []; _slim_controls1 = block_with_caption :bottom, :class=>'video-block' do; _slim_controls2 = []; 
      ; if video_iframe?; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _slim_controls2 << ("<iframe"); _slim_codeattributes1 = video_uri; if _slim_codeattributes1; if _slim_codeattributes1 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes1); _slim_controls2 << ("\""); end; end; _slim_codeattributes2 = (attr :width); if _slim_codeattributes2; if _slim_codeattributes2 == true; _slim_controls2 << (" width"); else; _slim_controls2 << (" width=\""); _slim_controls2 << (_slim_codeattributes2); _slim_controls2 << ("\""); end; end; _slim_codeattributes3 = (attr :height); if _slim_codeattributes3; if _slim_codeattributes3 == true; _slim_controls2 << (" height"); else; _slim_controls2 << (" height=\""); _slim_controls2 << (_slim_codeattributes3); _slim_controls2 << ("\""); end; end; _slim_codeattributes4 = 0; if _slim_codeattributes4; if _slim_codeattributes4 == true; _slim_controls2 << (" frameborder"); else; _slim_controls2 << (" frameborder=\""); _slim_controls2 << (_slim_codeattributes4); _slim_controls2 << ("\""); end; end; _slim_codeattributes5 = !(option? 'nofullscreen'); if _slim_codeattributes5; if _slim_codeattributes5 == true; _slim_controls2 << (" allowfullscreen"); else; _slim_controls2 << (" allowfullscreen=\""); _slim_controls2 << (_slim_codeattributes5); _slim_controls2 << ("\""); end; end; _slim_controls2 << ("></iframe>"); 
      ; else; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; 
      ; _slim_controls2 << ("<video"); _slim_codeattributes6 = video_uri; if _slim_codeattributes6; if _slim_codeattributes6 == true; _slim_controls2 << (" src"); else; _slim_controls2 << (" src=\""); _slim_controls2 << (_slim_codeattributes6); _slim_controls2 << ("\""); end; end; _slim_codeattributes7 = (attr :width); if _slim_codeattributes7; if _slim_codeattributes7 == true; _slim_controls2 << (" width"); else; _slim_controls2 << (" width=\""); _slim_controls2 << (_slim_codeattributes7); _slim_controls2 << ("\""); end; end; _slim_codeattributes8 = (attr :height); if _slim_codeattributes8; if _slim_codeattributes8 == true; _slim_controls2 << (" height"); else; _slim_controls2 << (" height=\""); _slim_controls2 << (_slim_codeattributes8); _slim_controls2 << ("\""); end; end; _slim_codeattributes9 = (media_uri(attr :poster) if attr? :poster); if _slim_codeattributes9; if _slim_codeattributes9 == true; _slim_controls2 << (" poster"); else; _slim_controls2 << (" poster=\""); _slim_controls2 << (_slim_codeattributes9); _slim_controls2 << ("\""); end; end; _slim_codeattributes10 = (option? 'autoplay'); if _slim_codeattributes10; if _slim_codeattributes10 == true; _slim_controls2 << (" autoplay"); else; _slim_controls2 << (" autoplay=\""); _slim_controls2 << (_slim_codeattributes10); _slim_controls2 << ("\""); end; end; _slim_codeattributes11 = (option? 'muted'); if _slim_codeattributes11; if _slim_codeattributes11 == true; _slim_controls2 << (" muted"); else; _slim_controls2 << (" muted=\""); _slim_controls2 << (_slim_codeattributes11); _slim_controls2 << ("\""); end; end; _slim_codeattributes12 = !(option? 'nocontrols'); if _slim_codeattributes12; if _slim_codeattributes12 == true; _slim_controls2 << (" controls"); else; _slim_controls2 << (" controls=\""); _slim_controls2 << (_slim_codeattributes12); _slim_controls2 << ("\""); end; end; _slim_codeattributes13 = (option? 'loop'); if _slim_codeattributes13; if _slim_codeattributes13 == true; _slim_controls2 << (" loop"); else; _slim_controls2 << (" loop=\""); _slim_controls2 << (_slim_codeattributes13); _slim_controls2 << ("\""); end; end; _slim_controls2 << (">Your browser does not support the video tag.</video>"); 
      ; 
      ; end; _slim_controls2 = _slim_controls2.join(""); end; _buf << (_slim_controls1); _buf = _buf.join("")
    end
  end
  #------------------ End of generated transformation methods ------------------#


end
