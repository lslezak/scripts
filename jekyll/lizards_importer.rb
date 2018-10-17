#! /usr/bin/env ruby

require "jekyll-import"
require_relative "lizards_rss"
require_relative "lizards_html"

Dir["*.xml"].each do |xml|
  JekyllImport::Importers::LizardsRSS.run("source" => xml)
end

Dir["*.html"].each do |html|
  importer = LizardsHtmlImporter.new(html)
  importer.process
end
