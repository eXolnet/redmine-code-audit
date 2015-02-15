class Audit < ActiveRecord::Base
	belongs_to :project
	belongs_to :user
	belongs_to :changeset
	
	has_many :comments, :class_name => 'AuditComment', :dependent => :destroy

	has_many :auditors, :class_name => 'AuditAuditor', :dependent => :delete_all
    has_many :auditor_users, :through => :auditors, :source => :user, :validate => false

	acts_as_watchable
	

    def add_auditor(user)
      self.auditors << AuditAuditor.new(:user => user)
    end

    def remove_auditor(user)
      return nil unless user && user.is_a?(User)
      AuditAuditor.delete_all "audit_id = #{self.id} AND user_id = #{user.id}"
    end

    def set_auditor(user, auditing=true)
      auditing ? add_auditor(user) : remove_auditor(user)
    end
end