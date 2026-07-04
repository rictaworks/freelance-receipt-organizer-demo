# frozen_string_literal: true

# ACCOUNT_CATEGORIES（設計書 2 ER図 / 1.6 マスタ 12件）。
class CreateAccountCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :account_categories do |t|
      t.string :code, null: false
      t.string :name, null: false
    end
    add_index :account_categories, :code, unique: true
  end
end
