class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :destroy

  validates :title, presence: true
end
