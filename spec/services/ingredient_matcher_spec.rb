require "rails_helper"

RSpec.describe IngredientMatcher do
  describe ".match?" do
    it "matches the ingredient itself" do
      expect(described_class.match?("garlic", "garlic")).to be(true)
    end

    it "matches a cut or form of the ingredient (ADR 0001)" do
      expect(described_class.match?("chicken", "skinless chicken breast half")).to be(true)
      expect(described_class.match?("chicken", "cooked shredded chicken")).to be(true)
    end

    it "matches a multi-word ingredient" do
      expect(described_class.match?("chicken breast", "skinless chicken breast half")).to be(true)
    end

    it "does not match a derived product (ADR 0002)" do
      expect(described_class.match?("chicken", "chicken broth")).to be(false)
      expect(described_class.match?("chicken", "cream of chicken soup")).to be(false)
      expect(described_class.match?("garlic", "garlic powder")).to be(false)
      expect(described_class.match?("tomato", "tomato sauce")).to be(false)
    end

    it "matches the derived product itself when the user asks for it" do
      expect(described_class.match?("chicken broth", "chicken broth")).to be(true)
    end

    it "matches when the ingredient appears again without a derived word" do
      expect(described_class.match?("chicken", "chicken broth with chicken")).to be(true)
    end

    it "matches whole words only" do
      expect(described_class.match?("egg", "eggplant")).to be(false)
      expect(described_class.match?("pea", "peanut")).to be(false)
    end

    it "matches varieties of a generic ingredient (ADR 0006, known limitation)" do
      expect(described_class.match?("cheese", "shredded cheddar cheese")).to be(true)
      expect(described_class.match?("butter", "peanut butter")).to be(true)
    end

    it "does not match an unrelated line or a blank ingredient" do
      expect(described_class.match?("chicken", "white rice")).to be(false)
      expect(described_class.match?("", "white rice")).to be(false)
    end
  end

  describe ".pantry_staple?" do
    it "is true for the exact staples (ADR 0003)" do
      %w[salt water].each { |name| expect(described_class.pantry_staple?(name)).to be(true) }
      expect(described_class.pantry_staple?("ground black pepper")).to be(true)
      expect(described_class.pantry_staple?("olive oil")).to be(true)
    end

    it "is true when a line lists only staples joined by and" do
      expect(described_class.pantry_staple?("salt and ground black pepper")).to be(true)
      expect(described_class.pantry_staple?("salt and freshly ground black pepper")).to be(true)
    end

    it "is false when one part of the line is not a staple" do
      expect(described_class.pantry_staple?("salt and red bell pepper")).to be(false)
      expect(described_class.pantry_staple?("garlic and water")).to be(false)
    end

    it "is false when the name only contains a staple" do
      expect(described_class.pantry_staple?("red bell pepper")).to be(false)
      expect(described_class.pantry_staple?("sesame oil")).to be(false)
    end
  end

  describe ".available?" do
    it "is true when a user ingredient matches or the line is a pantry staple" do
      expect(described_class.available?([ "chicken" ], "chicken breast")).to be(true)
      expect(described_class.available?([ "chicken" ], "salt")).to be(true)
    end

    it "is false otherwise" do
      expect(described_class.available?([ "chicken" ], "white rice")).to be(false)
      expect(described_class.available?([], "white rice")).to be(false)
    end
  end
end
