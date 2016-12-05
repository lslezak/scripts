#! /usr/bin/env ruby

require "jekyll-import"
require_relative "lizard_rss"
require_relative "lizard_html"

Dir["*.xml"].each do |xml|
  JekyllImport::Importers::LizardRSS.run( "source" => xml )
end

Dir["*.html"].each do |html|
  importer = LizardHtmlImporter.new(html)
  importer.process
end
