# Loads recipes from the dataset (an array of hashes, as parsed from recipes-en.json)
# into the database. Each ingredient line is stored twice: `raw_text` to display it
# and `name` (cleaned by IngredientParser) to search on it.
#
# Running it again replaces everything, so it never creates duplicates.
class RecipeImporter
  BATCH_SIZE = 500

  def self.call(recipes_data)
    new(recipes_data).call
  end

  def initialize(recipes_data)
    @recipes_data = recipes_data
  end

  # Returns the number of recipes imported.
  def call
    Recipe.transaction do
      # Children first because of the foreign key.
      RecipeIngredient.delete_all
      Recipe.delete_all

      # Batches with insert_all: a few big INSERTs are much faster than 10,000 small ones.
      @recipes_data.each_slice(BATCH_SIZE) { |batch| import_batch(batch) }
    end

    @recipes_data.size
  end

  private

  def import_batch(batch)
    # `returning` gives back the new ids, in the same order as the rows we sent.
    ids = Recipe.insert_all(batch.map { |data| recipe_row(data) }, returning: %w[id]).map { |row| row["id"] }

    ingredient_rows = batch.zip(ids).flat_map do |data, recipe_id|
      ingredient_rows(data["ingredients"], recipe_id)
    end
    RecipeIngredient.insert_all(ingredient_rows) if ingredient_rows.any?
  end

  # The dataset calls the picture `image`; our column is `image_url`.
  # Empty strings become nil so "no category" is stored as NULL.
  def recipe_row(data)
    {
      title: data["title"],
      prep_time: data["prep_time"],
      cook_time: data["cook_time"],
      ratings: data["ratings"],
      category: data["category"].presence,
      author: data["author"].presence,
      image_url: original_image_url(data["image"])
    }
  end

  def ingredient_rows(lines, recipe_id)
    Array(lines).filter_map do |line|
      name = IngredientParser.call(line)
      next if name.empty?

      { recipe_id: recipe_id, raw_text: line, name: name }
    end
  end

  # Most dataset images go through a resizing service that no longer answers (HTTP 400):
  #   https://imagesvc.meredithcorp.io/v3/mm/image?url=<original image address>
  # The original address is still alive, so we store that one. Any other URL is kept as is.
  def original_image_url(image)
    return if image.blank?

    original = URI.decode_www_form(URI(image).query.to_s).to_h["url"]
    original.presence || image
  rescue URI::InvalidURIError
    image
  end
end
