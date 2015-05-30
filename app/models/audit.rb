class Audit < ActiveRecord::Base
  # Audit statuses
  STATUS_NONE               = '';
  STATUS_AUDIT_NOT_REQUIRED = 'audit_not_required';
  STATUS_AUDIT_REQUIRED     = 'audit_required';
  STATUS_CONCERNED          = 'concerned';
  STATUS_ACCEPTED           = 'accepted';
  STATUS_AUDIT_REQUESTED    = 'requested';
  STATUS_RESIGNED           = 'resigned';
  STATUS_CLOSED             = 'closed';
  STATUS_CC                 = 'cc';

  belongs_to :project
  belongs_to :user
  belongs_to :changeset

  has_many :comments, :class_name => 'AuditComment', :dependent => :destroy

  has_many :auditors, :class_name => 'AuditAuditor', :dependent => :delete_all
  has_many :auditor_users, :through => :auditors, :source => :user, :validate => false

  acts_as_watchable

  after_save :send_notification

  def author
    user
  end

  def opened?
    [STATUS_AUDIT_REQUIRED, STATUS_AUDIT_REQUESTED, STATUS_CONCERNED].include?(status)
  end

  def closed?
    !opened?
  end

  def status_label
    l("status_#{status}")
  end

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

  # Returns the users that should be notified
  def notified_users
    notified = []

    # Author and auditors are always notified unless they have been
    # locked or don't want to be notified
    notified << user if user

    notified += auditor_users

    # Only notify active users
    notified = notified.select { |u| u.active? }

    notified.uniq!

    notified
  end

  # Returns the email addresses that should be notified
  def recipients
    notified_users.collect(&:mail)
  end

  private

  def send_notification
    # new_record? returns false in after_save callbacks
    if id_changed?
      Mailer.audit_created(self).deliver
    elsif text_changed?
      #Mailer.wiki_content_updated(self).deliver
    end
  end
end