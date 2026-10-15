require "rails_helper"

RSpec.describe RecipeImporter do
  let(:data) do
    [
      {
        "title" => "Golden Sweet Cornbread", "prep_time" => 10, "cook_time" => 25, "ratings" => 4.74,
        "category" => "Cornbread", "author" => "bluegirl", "image" => "https://example.com/cornbread.jpg",
        "ingredients" => [ "1 cup all-purpose flour", "8 large eggs", "1 (14.5 ounce) can diced tomatoes" ]
      },
      {
        "title" => "Plain Rice", "prep_time" => 5, "cook_time" => 20, "ratings" => 3.5,
        "category" => "", "author" => "", "image" => "https://example.com/rice.jpg",
        "ingredients" => [ "1 cup white rice", "2 cups water" ]
      },
      {
        "title" => "Empty Ingredients", "prep_time" => 0, "cook_time" => 0, "ratings" => 1.0,
        "category" => "Misc", "author" => "someone", "image" => "https://example.com/x.jpg",
        "ingredients" => []
      }
    ]
  end

  it "creates the recipes and returns how many" do
    expect(described_class.call(data)).to eq(3)
    expect(Recipe.pluck(:title)).to contain_exactly("Golden Sweet Cornbread", "Plain Rice", "Empty Ingredients")
  end

  it "maps the dataset fields, renaming image to image_url" do
    described_class.call(data)

    recipe = Recipe.find_by!(title: "Golden Sweet Cornbread")
    expect(recipe).to have_attributes(
      prep_time: 10, cook_time: 25, ratings: 4.74, category: "Cornbread",
      author: "bluegirl", image_url: "https://example.com/cornbread.jpg"
    )
  end

  it "stores the original image address instead of the resizing service one" do
    data.first["image"] = "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fimages.media-allrecipes.com%2Fuserphotos%2F1228850.jpg"
    described_class.call(data)

    expect(Recipe.find_by!(title: "Golden Sweet Cornbread").image_url).to eq("https://images.media-allrecipes.com/userphotos/1228850.jpg")
  end

  it "stores empty category and author as nil" do
    described_class.call(data)

    expect(Recipe.find_by!(title: "Plain Rice")).to have_attributes(category: nil, author: nil)
  end

  it "stores each ingredient line as raw_text and its parsed name" do
    described_class.call(data)

    ingredients = Recipe.find_by!(title: "Golden Sweet Cornbread").recipe_ingredients
    expect(ingredients.pluck(:raw_text, :name)).to contain_exactly(
      [ "1 cup all-purpose flour", "all-purpose flour" ],
      [ "8 large eggs", "large egg" ],
      [ "1 (14.5 ounce) can diced tomatoes", "diced tomato" ]
    )
  end

  it "attaches the ingredients to the right recipe" do
    described_class.call(data)

    expect(Recipe.find_by!(title: "Plain Rice").recipe_ingredients.pluck(:name)).to contain_exactly("white rice", "water")
  end

  it "does not duplicate anything when run twice" do
    2.times { described_class.call(data) }

    expect(Recipe.count).to eq(3)
    expect(RecipeIngredient.count).to eq(5)
  end
end
