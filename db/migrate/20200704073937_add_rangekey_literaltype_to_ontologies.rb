class AddRangekeyLiteraltypeToOntologies < ActiveRecord::Migration
  def change
    add_column :ontologies, :rangekey, :string
    add_column :ontologies, :literal_type, :string
  end
end

