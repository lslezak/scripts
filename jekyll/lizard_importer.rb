#! /usr/bin/env ruby

require "jekyll-import"
require_relative "lizard_rss"

Dir["*.xml"].each do |xml|
  JekyllImport::Importers::LizardRSS.run( "source" => xml )
end
