class AuditAuditor < ActiveRecord::Base
  belongs_to :audit
  belongs_to :user

  validates_presence_of :audit, :user
  #validates_uniqueness_of :audit_id, :user_id
  validate :validate_user

  def validate_user
    errors.add :user_id, :invalid unless user.nil? || user.active?
  end
end