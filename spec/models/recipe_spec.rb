require "rails_helper"

RSpec.describe Recipe, type: :model do
  it "is valid with only a title" do
    expect(Recipe.new(title: "Golden Sweet Cornbread")).to be_valid
  end

  it "is invalid without a title" do
    recipe = Recipe.new(title: nil)

    expect(recipe).not_to be_valid
    expect(recipe.errors[:title]).to be_present
  end

  it "allows missing times, rating and category" do
    recipe = Recipe.create!(title: "Ice water")

    expect(recipe.prep_time).to be_nil
    expect(recipe.cook_time).to be_nil
    expect(recipe.ratings).to be_nil
  end

  it "has many ingredient lines, removed together with the recipe" do
    recipe = Recipe.create!(title: "Omelette")
    recipe.recipe_ingredients.create!(raw_text: "2 large eggs, beaten", name: "egg")

    expect { recipe.destroy }.to change(RecipeIngredient, :count).by(-1)
  end
end
