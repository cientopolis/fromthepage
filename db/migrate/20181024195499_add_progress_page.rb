class AddProgressPage < ActiveRecord::Migration
  def change
    add_column  :pages, :progress, :integer, :default => 0
  end
end
