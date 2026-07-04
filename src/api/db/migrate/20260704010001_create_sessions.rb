# frozen_string_literal: true

# SESSIONS（設計書 2 ER図）: session_id(UUID v4) を主キーとするオーナーキー。
class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions, id: false do |t|
      t.string :session_id, null: false
      t.datetime :created_at, null: false
      t.datetime :last_accessed_at, null: false
    end
    add_index :sessions, :session_id, unique: true
  end
end
