class CreateRecipesAndRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.integer :prep_time
      t.integer :cook_time
      t.decimal :ratings, precision: 3, scale: 2
      t.string :category
      t.string :author
      t.string :image_url

      t.timestamps
    end

    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      # The line exactly as it comes in the dataset, shown to the user.
      t.string :raw_text, null: false
      # The cleaned, normalized ingredient name, used for matching.
      t.string :name, null: false

      t.timestamps
    end

    add_index :recipe_ingredients, :name
  end
end
