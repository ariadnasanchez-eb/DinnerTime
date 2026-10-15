# Finds the best recipes for the ingredients a user has.
#
#   RecipeMatcher.call([ "chicken", "Tomatoes" ])
#   # => [ #<data Result recipe=..., matched_ingredients=[...], missing_lines=[...], total_lines=8>, ... ]
#
# How it works, in three steps:
#   1. PostgreSQL narrows down the candidate recipes (fast, but approximate).
#   2. Ruby checks every ingredient line of each candidate with IngredientMatcher
#      (precise) and scores the recipe: what the user has and what is missing.
#   3. Ruby filters and ranks the recipes following ADR 0004, keeps the first 20 and
#      only then loads those 20 recipes in full.
#
# Steps 1 and 2 work on plain values (ids, names) and not on ActiveRecord objects: a common
# ingredient like "chicken" has thousands of candidate recipes, and building an object for
# each of their ingredient lines used up the memory of the free Render instance.
class RecipeMatcher
  LIMIT = 20

  # What we know about one recipe for this search:
  #   recipe:              the Recipe record
  #   matched_ingredients: the user ingredients this recipe uses, e.g. [ "chicken", "rice" ]
  #   missing_lines:       the raw ingredient lines the user does not have
  #   total_lines:         how many ingredient lines the recipe has
  Result = Data.define(:recipe, :matched_ingredients, :missing_lines, :total_lines) do
    # How many ingredient lines the user has: the ones they matched plus the pantry staples.
    def available_count
      total_lines - missing_lines.size
    end
  end

  # A light version of a Result, used to rank before loading anything heavy.
  #   missing_line_ids: ids of the RecipeIngredient lines the user does not have
  Score = Data.define(:recipe_id, :rating, :matched_ingredients, :missing_line_ids, :total_lines)

  def self.call(user_ingredients)
    new(user_ingredients).call
  end

  def initialize(user_ingredients)
    # Same normalization as the recipe side (ADR 0005): lowercase and singular, so
    # "Tomatoes" becomes "tomato". Blank entries and repeated ones are dropped.
    @user_ingredients = Array(user_ingredients).map { |text| IngredientParser.normalize(text) }.reject(&:empty?).uniq
  end

  def call
    # Nothing to search for: no results, and we do not even query the database.
    return [] if @user_ingredients.empty?

    # Rank (ADR 0004) and keep only the best ones, still without loading full recipes.
    best = scores.sort_by { |score| ranking_key(score) }.first(LIMIT)

    build_results(best)
  end

  private

  # Step 1. Cheap filter in the database: recipes with at least one ingredient name
  # containing any of the user ingredients. It can include false positives
  # ("chicken broth" contains "chicken"), which the scoring discards afterwards.
  # It is a subquery: the database keeps the list of ids, not Ruby.
  def candidate_recipe_ids
    # `%chicken%` means "contains chicken". sanitize_sql_like escapes any % or _ the user typed.
    patterns = @user_ingredients.map { |text| "%#{RecipeIngredient.sanitize_sql_like(text)}%" }

    RecipeIngredient.where("name LIKE ANY (ARRAY[?])", patterns).select(:recipe_id)
  end

  # Step 2. Scores every candidate recipe. Only recipes that use at least one user
  # ingredient get a score (ADR 0004): the rest are not shown.
  def scores
    ratings = Recipe.where(id: candidate_recipe_ids).pluck(:id, :ratings).to_h

    # [ recipe_id, line id, cleaned name ] for every ingredient line of the candidates,
    # as plain arrays. Ordered by id so "missing" lines keep the order of the recipe.
    lines = RecipeIngredient.where(recipe_id: candidate_recipe_ids).order(:id).pluck(:recipe_id, :id, :name)

    lines.group_by(&:first).filter_map do |recipe_id, recipe_lines|
      score_recipe(recipe_id, ratings[recipe_id], recipe_lines)
    end
  end

  # Goes through each ingredient line of a recipe and decides if the user has it.
  # Returns nil when the recipe uses none of the user ingredients.
  def score_recipe(recipe_id, rating, recipe_lines)
    matched = []
    missing_line_ids = []

    recipe_lines.each do |_recipe_id, line_id, name|
      # Which of the user ingredients does this line use? (the rules of IngredientMatcher)
      used = @user_ingredients.select { |text| IngredientMatcher.match?(text, name) }

      if used.any?
        # The user has it.
        matched.concat(used)
      elsif !IngredientMatcher.pantry_staple?(name)
        # The user did not type it and it is not a pantry staple: it is missing.
        missing_line_ids << line_id
      end
      # A pantry staple the user did not type is simply skipped: it is neither used nor missing.
    end

    # ADR 0004: a recipe must use at least one ingredient the user typed.
    # Pantry staples alone are not enough ("Ice water" must not appear for "chicken").
    return if matched.empty?

    Score.new(
      recipe_id: recipe_id,
      rating: rating,
      matched_ingredients: matched.uniq,
      missing_line_ids: missing_line_ids,
      total_lines: recipe_lines.size
    )
  end

  # Step 3. ADR 0004. Ruby sorts arrays element by element, so this means:
  #   1. fewest missing ingredients first
  #   2. then most user ingredients used (negative so that "more" sorts first)
  #   3. then highest rating (negative for the same reason; no rating counts as 0)
  # The id only makes the order stable when everything else ties.
  def ranking_key(score)
    [ score.missing_line_ids.size, -score.matched_ingredients.size, -(score.rating || 0), score.recipe_id ]
  end

  # Loads the full recipes only for the (at most 20) winners, and turns the ids of their
  # missing lines into the raw text to show ("1 (14 ounce) can diced tomatoes").
  def build_results(best)
    recipes = Recipe.where(id: best.map(&:recipe_id)).includes(:recipe_ingredients).index_by(&:id)

    best.map do |score|
      recipe = recipes.fetch(score.recipe_id)
      raw_texts = recipe.recipe_ingredients.to_h { |line| [ line.id, line.raw_text ] }

      Result.new(
        recipe: recipe,
        matched_ingredients: score.matched_ingredients,
        missing_lines: score.missing_line_ids.map { |line_id| raw_texts.fetch(line_id) },
        total_lines: score.total_lines
      )
    end
  end
end
