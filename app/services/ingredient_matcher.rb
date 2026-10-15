# Decides whether a user ingredient matches the cleaned name of a recipe's ingredient line.
# Pure Ruby: no database, so every rule can be tested on its own.
#
# The rules come from the ADRs in docs/adr:
#
#   - ADR 0001/0002: "chicken" matches "chicken breast" but not "chicken broth".
#   - ADR 0003:      pantry staples are covered only by an exact name.
#   - ADR 0005:      both sides are normalized (lowercase, singular) before comparing.
#   - ADR 0006:      generic ingredients also match their varieties ("butter" matches "peanut butter").
class IngredientMatcher
  # If one of these words comes right after the ingredient, the line is a different
  # product made from it, not the ingredient itself: "chicken broth" is not "chicken".
  # To fix a wrong result in the future, add or remove a word here and add a test.
  DERIVED_PRODUCT_WORDS = %w[
    broth stock bouillon soup sauce powder paste juice extract syrup flavoring seasoning
    dressing vinegar oil salt puree gravy jam jelly marinade mix
  ].freeze

  # Things we assume every user has at home, so they are never reported as missing.
  # Only exact names count: "red bell pepper" is not "black pepper" and "sesame oil" is
  # not "vegetable oil". They go through the same normalization as everything else.
  PANTRY_STAPLES = [
    "salt", "black pepper", "ground black pepper", "water", "vegetable oil", "olive oil", "cooking spray"
  ].map { |name| IngredientParser.normalize(name) }.freeze

  # True if the recipe line uses the ingredient the user typed.
  #
  # Both arguments are expected to be already normalized (see IngredientParser):
  #   user_ingredient: what the user typed, e.g. "chicken"
  #   name:            the cleaned name of a recipe line, e.g. "skinless chicken breast half"
  def self.match?(user_ingredient, name)
    wanted = user_ingredient.split
    words = name.split
    return false if wanted.empty?

    # Slide over the words of the name looking for the user's words, one next to the other.
    # Comparing whole words (and not text) avoids "egg" matching "eggplant".
    # Words before the ingredient are allowed ("cheddar cheese" matches "cheese", ADR 0006).
    (0..words.size - wanted.size).any? do |start|
      next false unless words[start, wanted.size] == wanted

      # The ingredient is there. If the next word is a derived-product word the line is
      # a different product ("chicken broth"), so it does not count (ADR 0002).
      !DERIVED_PRODUCT_WORDS.include?(words[start + wanted.size])
    end
  end

  # True if the name is a pantry staple (ADR 0003).
  # The comparison is exact on purpose, never "contains". The only flexibility: a line that
  # lists several staples with "and" counts when EVERY part is a staple, because the dataset
  # often writes them together: "salt and freshly ground black pepper to taste".
  def self.pantry_staple?(name)
    parts = name.split(/\s+and\s+/).map { |part| part.gsub(/\bfreshly\s+/, "") }
    parts.all? { |part| PANTRY_STAPLES.include?(part) }
  end

  # True if the user has this recipe line: they typed an ingredient it uses, or it is a
  # pantry staple. Used on the recipe page to mark the lines that are missing.
  def self.available?(user_ingredients, name)
    pantry_staple?(name) || user_ingredients.any? { |text| match?(text, name) }
  end
end
