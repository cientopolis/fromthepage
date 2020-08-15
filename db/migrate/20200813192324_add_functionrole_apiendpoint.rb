class AddFunctionroleApiendpoint < ActiveRecord::Migration
  def change
    add_column :functionroles, :apiendpoint, :text
  end
end