require "open-uri"
require "zlib"
require "json"

namespace :recipes do
  desc "Download the recipes dataset and load it into the database (replaces existing recipes)"
  task import: :environment do
    url = "https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz"

    puts "Downloading #{url} ..."
    json = URI.open(url) { |file| Zlib::GzipReader.new(file).read }

    puts "Importing ..."
    count = RecipeImporter.call(JSON.parse(json))
    puts "Done: #{count} recipes, #{RecipeIngredient.count} ingredients."
  end
end
