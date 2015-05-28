class AuditAuditor < ActiveRecord::Base
  belongs_to :audit, :polymorphic => true
  belongs_to :user

  validates_presence_of :user
  validate :validate_user

  def validate_user
    errors.add :user_id, :invalid unless user.nil? || user.active?
  end
end