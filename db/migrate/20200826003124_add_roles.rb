class AddRoles < ActiveRecord::Migration
  def change
    adminrole = Role.find_by(name: "administrator")
    if !adminrole
        role = Role.new 
        role.name = "administrator"
        role.description = "A role for admin it all"
        role.save!
    end

    collaboratorrole = Role.find_by(name: "collaborator")
    if !collaboratorrole
        role = Role.new 
        role.name = "collaborator"
        role.description = "A role for collaborate"
        role.save!
    end
  end
end