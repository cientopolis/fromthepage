class Role < ActiveRecord::Base
    has_and_belongs_to_many  :functionrole, :class_name => 'Functionrole', :join_table => :functionroles_roles
end
