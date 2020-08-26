class AddUserRoles < ActiveRecord::Migration
  def change
    adminrole = Role.find_by(name: "administrator")
    collaboratorrole = Role.find_by(name: "collaborator")
    users = User.all
    users.each do |user|
        if user.admin
            user.role=adminrole
        else
            user.role=collaboratorrole
        end
        user.save!
    end
  end
end