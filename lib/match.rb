class Match < ActiveRecord::Base
  belongs_to :a, :class_name => "User", :foreign_key => :a_id
  belongs_to :b, :class_name => "User", :foreign_key => :b_id
end
