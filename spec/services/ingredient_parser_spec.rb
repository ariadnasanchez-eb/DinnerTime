require "rails_helper"

# Las líneas son reales, sacadas del dataset recipes-en.json.
RSpec.describe IngredientParser do
  describe ".call" do
    {
      "1 (14.5 ounce) can diced tomatoes" => "diced tomato",
      "1 cup all-purpose flour" => "all-purpose flour",
      "3 ½ teaspoons baking powder" => "baking powder",
      "⅔ cup white sugar" => "white sugar",
      "11⁄16 cup water" => "water",
      "8 eggs" => "egg",
      "8 large eggs" => "large egg",
      "1 stalk celery, chopped" => "celery",
      "¼ pound bacon, chopped" => "bacon",
      "1 cup chopped fresh basil" => "chopped fresh basil",
      "½ cup Italian dressing, or more to taste" => "italian dressing",
      "1 tablespoon extra-virgin olive oil, or more as needed" => "extra-virgin olive oil",
      "¼ pound shrimp - peeled, deveined and minced to a paste" => "shrimp",
      "1 (12 fluid ounce) can or bottle lager beer" => "lager beer",
      "1 (10.75 ounce) can cream of mushroom soup" => "cream of mushroom soup",
      "vegetable oil for frying" => "vegetable oil",
      "salt to taste" => "salt",
      "2 skinless, boneless chicken breast halves, thinly sliced" => "skinless boneless chicken breast half",
      "1 pound boneless, skinless chicken thighs" => "boneless skinless chicken thigh",
      "4 (5 ounce) boneless, center-cut pork chops, 1-inch thick" => "boneless center-cut pork chop",
      "3 cloves garlic, minced" => "garlic"
    }.each do |line, expected|
      it "#{line.inspect} -> #{expected.inspect}" do
        expect(described_class.call(line)).to eq(expected)
      end
    end

    it "returns an empty string for nil" do
      expect(described_class.call(nil)).to eq("")
    end
  end

  describe ".normalize" do
    it "lowercases and singularizes every word" do
      expect(described_class.normalize("Cherry Tomatoes")).to eq("cherry tomato")
    end

    it "ignores extra spaces" do
      expect(described_class.normalize("  egg   ")).to eq("egg")
    end
  end
end
