class CreateFunctionroles < ActiveRecord::Migration
  def change
    create_table :functionroles do |t|
      t.string :name
      t.string :uri
      t.text :descripton
      t.timestamps null: false
    end
    create_table :functionroles_roles, id: false do |t|
      t.belongs_to :functionrole
      t.belongs_to :role
    end
  end
  
end
