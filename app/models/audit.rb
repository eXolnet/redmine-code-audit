class Audit < ActiveRecord::Base
	belongs_to :project
	belongs_to :user
	belongs_to :changeset
	
	has_many :comments, :class_name => 'AuditComment'
end