class CreateMarks < ActiveRecord::Migration
  def change
    create_table :marks do |t|
      t.belongs_to :page_version, index: true
      t.float :start_x
      t.float :start_y
      t.float :end_x
      t.float :end_y
    end
  end
end
