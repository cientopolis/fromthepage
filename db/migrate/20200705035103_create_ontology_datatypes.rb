class CreateOntologyDatatypes < ActiveRecord::Migration
  def change
    create_table :ontology_datatypes do |t|
      t.string :semantic_class
      t.string :internal_type
      t.references :ontology, index: true, foreign_key: true
    end
  end
end
