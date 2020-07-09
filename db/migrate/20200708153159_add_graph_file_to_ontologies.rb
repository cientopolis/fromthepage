class AddGraphFileToOntologies < ActiveRecord::Migration
  def change
    add_column :ontologies, :graph_file, :string
  end
end
