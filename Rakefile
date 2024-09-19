#!/usr/bin/env rake
require 'bundler/gem_tasks'
require 'rake/clean'
require 'asciidoctor/doctest'
require 'thread_safe'
require 'tilt'

BACKEND_NAME = 'html5s'.freeze
CONVERTER_FILE = 'lib/asciidoctor/html5s/converter.rb'.freeze
TEMPLATES_DIR = 'data/templates'.freeze

namespace :build do
  file CONVERTER_FILE, FileList["#{TEMPLATES_DIR}/*"] do |t, args|
    require 'asciidoctor-templates-compiler'
    require 'slim-htag'

    File.open(CONVERTER_FILE, 'w') do |file|
      $stderr.puts "Generating #{file.path}."
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
        pretty: (args[:mode] == :pretty),
        output: file)
    end
  end

  namespace :converter do
    desc 'Compile Slim templates and generate converter.rb (pretty mode)'
    task :pretty do
      Rake::Task[CONVERTER_FILE].invoke(:pretty)
    end

    desc 'Compile Slim templates and generate converter.rb (fast mode)'
    task :fast do
      Rake::Task[CONVERTER_FILE].invoke
    end
  end

  task :converter => 'converter:pretty'
end

task build: 'build:converter:pretty'

task :clean do
  rm_rf Dir['*.gem']
  rm_rf Dir['asciidoctor-html5s-*.tgz']
  rm_rf Dir['pkg/*.gem']
end

task :clobber do
  rm_rf CONVERTER_FILE
end

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

task test: ['.prepare-converter', 'doctest:test']
task default: :test
