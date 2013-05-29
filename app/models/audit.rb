class Audit < ActiveRecord::Base
	belongs_to :changeset
	belongs_to :user
	
	has_many :comments, :class_name => 'AuditComment'
end