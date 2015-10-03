class User < ActiveRecord::Base
  has_many :match_a, :class_name => "Match", :foreign_key => :a_id
  has_many :match_b, :class_name => "Match", :foreign_key => :b_id

  def matches
    return self.match_a + self.match_b
  end
end
