class AddWordsPage < ActiveRecord::Migration
  def change
    add_column  :pages, :words, :integer, :default => 0
    add_column  :pages, :lines, :integer, :default => 0
  end
end
