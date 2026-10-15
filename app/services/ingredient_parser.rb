# Turns a raw ingredient line from the dataset into its clean name.
#
#   IngredientParser.call("1 (14.5 ounce) can diced tomatoes") # => "diced tomato"
#
# Pure Ruby: it never touches the database. It is used when importing recipes
# (to store `name`) and to normalize what the user types (ADR 0005).
class IngredientParser
  # Measure and container words that are not part of the ingredient name.
  UNITS = %w[
    cup tablespoon teaspoon ounce pound gram kilogram liter milliliter quart pint gallon
    tbsp tsp oz lb g kg ml l fluid package can jar bottle container carton box bag packet
    envelope clove slice stick head bunch sprig stalk pinch dash drop piece tub
  ].freeze

  # Unicode fraction characters (½, ⅓, ...) plus the fraction slash (⁄) used in the dataset.
  FRACTIONS = "½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞⁄".freeze

  # A "word" that is only a quantity: 1, 1.5, 1/2, 1-2, ½...
  QUANTITY = /\A[\d#{FRACTIONS}\/.\-]+\z/

  def self.call(line)
    # Work in lowercase so matching never depends on capitalization.
    text = line.to_s.downcase
    # Remove anything in parentheses, e.g. "(14.5 ounce)".
    text = text.gsub(/\([^)]*\)/, " ")
    # Drop a " - ..." suffix, e.g. "shrimp - peeled and deveined".
    text = text.sub(/\s+-\s+.*/, "")
    # "skinless, boneless chicken": remove the comma so the next step does not cut the name in half.
    text = text.gsub(/\b(skinless|boneless|seedless),/, '\1')
    # Everything after the first comma is preparation, e.g. ", chopped".
    text = text.split(",").first.to_s
    # Remove trailing notes like "to taste", "as needed" or "for frying".
    text = text.sub(/\s+(to taste|as needed|for .*)\z/, "")

    words = text.split(/\s+/).reject(&:empty?)
    # Remove the leading quantity (and the "to" of ranges like "1 to 2").
    words.shift while words.first&.match?(QUANTITY) || words.first == "to"
    # Keep a copy in case the line is only a unit, e.g. "3 cloves".
    rest = words.dup
    # Remove the leading units, e.g. "can", "cup".
    words.shift while words.first && unit?(words.first)
    # Handle "can or bottle lager beer": skip "or" plus the second unit.
    words.shift(2) if words.first == "or" && words[1] && unit?(words[1])
    # Remove a leading "of", e.g. "pinch of salt".
    words.shift if words.first == "of"

    name = normalize(words.join(" "))
    # If nothing is left, fall back to the unit word so the name is never empty.
    name.empty? ? normalize(rest.join(" ")) : name
  end

  # Lowercases and singularizes every word. Also applied to what the user types,
  # so "Tomatoes" and "tomato" end up identical.
  def self.normalize(text)
    text.to_s.downcase.split(/\s+/).reject(&:empty?).map(&:singularize).join(" ")
  end

  # True if the word is a unit, in singular or plural ("cup", "cups", "boxes").
  # Checked by hand so it does not depend on Rails' singularization rules.
  def self.unit?(word)
    UNITS.include?(word) || UNITS.include?(word.delete_suffix("s")) || UNITS.include?(word.delete_suffix("es"))
  end
  private_class_method :unit?
end
