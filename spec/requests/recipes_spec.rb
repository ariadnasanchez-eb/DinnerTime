require "rails_helper"

RSpec.describe "Recipes", type: :request do
  # Builds a recipe with its ingredient lines, cleaned with the real IngredientParser.
  def create_recipe(title, lines, ratings: 4.0)
    recipe = Recipe.create!(title: title, ratings: ratings, prep_time: 10, cook_time: 20)
    lines.each do |line|
      recipe.recipe_ingredients.create!(raw_text: line, name: IngredientParser.call(line))
    end
    recipe
  end

  describe "GET / (home and results)" do
    it "shows the ingredient form and the pantry staples we assume" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Find recipes")
      expect(response.body).to include('aria-label="Add ingredient"') # the + button, for phones
      expect(response.body).to include("Clear all")
      expect(response.body).to include("We assume you have salt, black pepper, water and cooking oil.")
    end

    it "lists the recipes that use the ingredients, with what is missing" do
      create_recipe("Chicken Rice", [ "2 chicken breasts", "1 cup white rice", "1 onion, diced" ])
      create_recipe("Ice Water", [ "2 cups water", "1 cup ice" ])

      get root_path, params: { ingredients: "chicken, rice" }

      expect(response.body).to include("Chicken Rice")
      expect(response.body).to include("You have 2 of 3 ingredients")
      expect(response.body).to include("Missing: 1 onion, diced")
      expect(response.body).not_to include("Ice Water")
    end

    it "shows which of your ingredients each recipe uses, its time and its rating" do
      create_recipe("Chicken Rice", [ "2 chicken breasts", "1 cup white rice" ])

      get root_path, params: { ingredients: "Chicken, rice" }

      expect(response.body).to include("✓ chicken", "✓ rice")
      expect(response.body).to include("⏱ 30 min")
      expect(response.body).to include("★ 4.0")
    end

    it "has a loading message that replaces the old content while searching" do
      get root_path, params: { ingredients: "chicken" }

      expect(response.body).to include("data-loading-message", "data-loading-content", "Looking for recipes…")
    end

    it "suggests example searches on the first visit only" do
      get root_path
      expect(response.body).to include("Try:")
      expect(response.body).to include(root_path(ingredients: "chicken,rice"))

      get root_path, params: { ingredients: "chicken" }
      expect(response.body).not_to include("Try:")
    end

    it "keeps the search in the links to the recipe pages" do
      recipe = create_recipe("Chicken Rice", [ "2 chicken breasts" ])

      get root_path, params: { ingredients: "chicken" }

      expect(response.body).to include(recipe_path(recipe, ingredients: "chicken"))
    end

    it "shows a clear message when nothing matches" do
      create_recipe("Chicken Rice", [ "2 chicken breasts" ])

      get root_path, params: { ingredients: "dragonfruit" }

      expect(response.body).to include("No recipes found")
    end

    it "does not search when no ingredients were given" do
      create_recipe("Chicken Rice", [ "2 chicken breasts" ])

      get root_path, params: { ingredients: " , " }

      expect(response.body).not_to include("Chicken Rice")
      expect(response.body).not_to include("No recipes found")
    end

    it "shows the ingredients back in the field so the search can be edited" do
      get root_path, params: { ingredients: "egg, tomato" }

      expect(response.body).to include('value="egg, tomato"')
    end
  end

  describe "GET /recipes/:id" do
    let!(:recipe) { create_recipe("Chicken Rice", [ "2 chicken breasts", "1 cup white rice", "1 onion, diced" ]) }

    it "shows time, rating and every ingredient line" do
      get recipe_path(recipe)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Chicken Rice")
      expect(response.body).to include("Prep: 10 min")
      expect(response.body).to include("Cook: 20 min")
      expect(response.body).to include("Rating: 4.0 / 5")
      expect(response.body).to include("2 chicken breasts", "1 cup white rice", "1 onion, diced")
    end

    it "marks the ingredients the user does not have when it comes from a search" do
      get recipe_path(recipe, ingredients: "chicken, rice")

      expect(response.body).to match(/<li class="missing">\s*1 onion, diced/)
      expect(response.body).not_to match(/<li class="missing">\s*2 chicken breasts/)
    end

    it "marks nothing when there was no search" do
      get recipe_path(recipe)

      expect(response.body).not_to include('class="missing"')
    end

    it "links back to the results keeping the ingredients" do
      get recipe_path(recipe, ingredients: "chicken, rice")

      expect(response.body).to include("Back to results")
      expect(response.body).to include("ingredients=chicken%2Crice")
    end
  end
end
