class AddClassTypeToOntologies < ActiveRecord::Migration
  def change
    add_column :ontologies, :class_type, :string
  end
end
