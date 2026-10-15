class RecipesController < ApplicationController
  MAX_INGREDIENTS = 20

  # Home page: the ingredient form and, when there is a search, its results below.
  # The search lives in the URL (/?ingredients=chicken,tomato) so the back button and
  # shared links keep working.
  def index
    @ingredients = ingredients_from_params
    @results = RecipeMatcher.call(@ingredients) if @ingredients.any?
  end

  # Recipe page. If it comes from a search, the lines the user does not have are marked.
  def show
    @recipe = Recipe.includes(:recipe_ingredients).find(params[:id])
    @ingredients = ingredients_from_params

    normalized = @ingredients.map { |text| IngredientParser.normalize(text) }
    @lines = @recipe.recipe_ingredients.sort_by(&:id).map do |line|
      [ line, @ingredients.any? && !IngredientMatcher.available?(normalized, line.name) ]
    end
  end

  private

  # "chicken, Tomatoes ,," -> [ "chicken", "Tomatoes" ]. Kept as typed, to show it back to the user.
  # RecipeMatcher normalizes them itself.
  def ingredients_from_params
    params[:ingredients].to_s.first(500).split(",").map(&:strip).reject(&:blank?).uniq(&:downcase).first(MAX_INGREDIENTS)
  end
end
