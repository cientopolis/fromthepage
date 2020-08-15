class AddPublicfunctionflag < ActiveRecord::Migration
  def change
    add_column :functionroles, :public, :boolean, default: false
  end
end