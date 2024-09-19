#!/usr/bin/env rake
require 'bundler/gem_tasks'
require 'rake/clean'

BACKEND_NAME = 'html5s'.freeze
CONVERTER_FILE = 'lib/asciidoctor/html5s/converter.rb'.freeze
TEMPLATES_DIR = 'data/templates'.freeze

file CONVERTER_FILE => FileList["#{TEMPLATES_DIR}/*"] do
  build_converter :fast
end

namespace :build do
  desc 'Compile Slim templates and generate converter.rb'
  task :converter do
    build_converter
  end

  desc 'Compile Slim templates and generate converter.rb for Opal'
  task 'converter:opal' do
    build_converter :opal
  end
end

task build: 'build:converter'

task :clean do
  rm_rf CONVERTER_FILE
  rm_rf Dir['*.gem']
  rm_rf Dir['asciidoctor-html5s-*.tgz']
  rm_rf Dir['pkg/*.gem']
end

begin
  require 'asciidoctor/doctest'

  DocTest::RakeTasks.new(:doctest) do |t|
    t.output_examples :html, path: 'test/examples/html5'
    t.input_examples :asciidoc, path: [
      *DocTest.examples_path,
      'test/examples/asciidoc-html'
    ]
    t.converter = DocTest::HTML::Converter
    t.converter_opts = { backend_name: BACKEND_NAME }
  end

  task '.prepare-converter' do
    # Run as an external process to ensure that it will not affect tests
    # environment with extra loaded modules (especially slim).
    `bundle exec rake #{CONVERTER_FILE}`

    require_relative 'lib/asciidoctor-html5s'
  end

  task 'doctest:test' => '.prepare-converter'
  task 'doctest:generate' => '.prepare-converter'
  task test: 'doctest:test'
  task default: :test
rescue LoadError => e
  warn "#{e.path} is not available"
end

def build_converter(mode = :pretty)
  require 'asciidoctor-templates-compiler'
  require 'slim-htag'

  generator = if mode == :opal
                Temple::Generators::ArrayBuffer.new(freeze_static: false)
              else
                Temple::Generators::StringBuffer
              end

  File.open(CONVERTER_FILE, 'w') do |file|
    puts "Generating #{file.path} (mode: #{mode})."

    Asciidoctor::TemplatesCompiler::Slim.compile_converter(
      templates_dir: TEMPLATES_DIR,
      class_name: 'Asciidoctor::Html5s::Converter',
      register_for: [BACKEND_NAME],
      backend_info: {
        basebackend: 'html',
        outfilesuffix: '.html',
        filetype: 'html',
        supports_templates: true
      },
      engine_opts: {
        generator:
      },
      ignore_convert_opts: (mode == :opal),
      pretty: (mode == :pretty),
      output: file
    )
  end
end
