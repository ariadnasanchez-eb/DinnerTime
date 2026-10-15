require "rails_helper"

RSpec.describe RecipeMatcher do
  # Builds a recipe with its ingredient lines, cleaned with the real IngredientParser.
  def create_recipe(title, lines, ratings: 4.0)
    recipe = Recipe.create!(title: title, ratings: ratings)
    lines.each do |line|
      recipe.recipe_ingredients.create!(raw_text: line, name: IngredientParser.call(line))
    end
    recipe
  end

  def titles(results)
    results.map { |result| result.recipe.title }
  end

  it "returns nothing when the user has no ingredients" do
    create_recipe("Roast Chicken", [ "1 whole chicken" ])

    expect(described_class.call([])).to eq([])
    expect(described_class.call([ " ", "" ])).to eq([])
  end

  it "only returns recipes that use at least one user ingredient (ADR 0004)" do
    create_recipe("Roast Chicken", [ "1 whole chicken", "1 teaspoon salt" ])
    create_recipe("Ice Water", [ "2 cups water", "1 cup ice" ])

    expect(titles(described_class.call([ "chicken" ]))).to eq([ "Roast Chicken" ])
  end

  it "does not count derived products as the ingredient (ADR 0001, 0002)" do
    create_recipe("Chicken Stock", [ "4 cups chicken broth" ])

    expect(described_class.call([ "chicken" ])).to eq([])
  end

  it "never counts pantry staples as missing (ADR 0003)" do
    create_recipe("Roast Chicken", [ "1 whole chicken", "1 teaspoon salt", "2 tablespoons olive oil", "water" ])

    result = described_class.call([ "chicken" ]).first
    expect(result.missing_lines).to eq([])
    expect(result.available_count).to eq(result.total_lines)
  end

  it "counts a pantry look-alike as missing (ADR 0003)" do
    create_recipe("Stuffed Peppers", [ "1 pound ground beef", "1 red bell pepper" ])

    result = described_class.call([ "beef" ]).first
    expect(result.missing_lines).to eq([ "1 red bell pepper" ])
  end

  it "reports what the user uses and what is missing" do
    create_recipe("Chicken Rice", [ "2 chicken breasts", "1 cup white rice", "1 onion, diced" ])

    result = described_class.call([ "chicken", "rice" ]).first
    expect(result.matched_ingredients).to contain_exactly("chicken", "rice")
    expect(result.missing_lines).to eq([ "1 onion, diced" ])
    expect(result.total_lines).to eq(3)
    expect(result.available_count).to eq(2)
  end

  it "ignores case and plurals on both sides (ADR 0005)" do
    create_recipe("Omelette", [ "3 eggs", "1 tomato" ])

    result = described_class.call([ "EGG", "Tomatoes" ]).first
    expect(result.matched_ingredients).to contain_exactly("egg", "tomato")
  end

  it "ranks fewest missing ingredients first (ADR 0004)" do
    create_recipe("Needs Three", [ "1 chicken", "1 lime", "1 mango", "1 papaya" ])
    create_recipe("Needs None", [ "1 chicken" ])
    create_recipe("Needs One", [ "1 chicken", "1 lime" ])

    expect(titles(described_class.call([ "chicken" ]))).to eq([ "Needs None", "Needs One", "Needs Three" ])
  end

  it "breaks ties by most user ingredients used (ADR 0004)" do
    create_recipe("Uses One", [ "1 chicken", "1 lime" ])
    create_recipe("Uses Two", [ "1 chicken", "1 cup rice", "1 lime" ])

    expect(titles(described_class.call([ "chicken", "rice" ]))).to eq([ "Uses Two", "Uses One" ])
  end

  it "breaks the remaining ties by highest rating (ADR 0004)" do
    create_recipe("Good", [ "1 chicken" ], ratings: 3.5)
    create_recipe("Best", [ "1 chicken" ], ratings: 4.9)
    create_recipe("Unrated", [ "1 chicken" ], ratings: nil)

    expect(titles(described_class.call([ "chicken" ]))).to eq([ "Best", "Good", "Unrated" ])
  end

  it "returns at most 20 recipes (ADR 0004)" do
    25.times { |i| create_recipe("Chicken #{i}", [ "1 chicken" ]) }

    expect(described_class.call([ "chicken" ]).size).to eq(20)
  end

  it "keeps the known limitation of varieties (ADR 0006)" do
    create_recipe("Peanut Butter Cookies", [ "1 cup peanut butter" ])

    expect(titles(described_class.call([ "butter" ]))).to eq([ "Peanut Butter Cookies" ])
  end
end
