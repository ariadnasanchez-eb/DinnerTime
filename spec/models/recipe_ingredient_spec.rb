require "rails_helper"

RSpec.describe RecipeIngredient, type: :model do
  let(:recipe) { Recipe.create!(title: "Omelette") }

  it "is valid with a recipe, the original line and the cleaned name" do
    ingredient = recipe.recipe_ingredients.build(raw_text: "2 large eggs, beaten", name: "egg")

    expect(ingredient).to be_valid
  end

  it "is invalid without the original line" do
    expect(recipe.recipe_ingredients.build(raw_text: nil, name: "egg")).not_to be_valid
  end

  it "is invalid without the cleaned name" do
    expect(recipe.recipe_ingredients.build(raw_text: "2 large eggs", name: nil)).not_to be_valid
  end

  it "belongs to a recipe" do
    expect(RecipeIngredient.new(raw_text: "1 egg", name: "egg")).not_to be_valid
  end
end
