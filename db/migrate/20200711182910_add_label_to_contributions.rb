class AddLabelToContributions < ActiveRecord::Migration
  def change
    add_column :contributions, :label, :string
  end
end
