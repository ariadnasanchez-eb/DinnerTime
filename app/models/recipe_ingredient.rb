class RecipeIngredient < ApplicationRecord
  belongs_to :recipe

  validates :raw_text, :name, presence: true
end
