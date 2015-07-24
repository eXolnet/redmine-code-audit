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

  validates_presence_of :summary, :project, :user, :changeset
  validates_length_of :summary, :maximum => 255

  after_save :send_notification

  def self.statuses
    {
      STATUS_AUDIT_NOT_REQUIRED => l('status_audit_not_required'),
      STATUS_AUDIT_REQUIRED     => l('status_audit_required'),
      STATUS_CONCERNED          => l('status_concerned'),
      STATUS_ACCEPTED           => l('status_accepted'),
      STATUS_AUDIT_REQUESTED    => l('status_requested'),
      STATUS_RESIGNED           => l('status_resigned'),
      STATUS_CLOSED             => l('status_closed'),
      STATUS_CC                 => l('status_cc'),
    }
  end

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

  def revision
    self.changeset.revision if self.changeset
  end

  def revision=(revision)
    if self.project && self.project.repository
      self.changeset = self.project.repository.changesets.where("#{Changeset.table_name}.revision LIKE ?", "%#{revision}%").first
    end
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

  def auditor_user_ids
    self.auditors.pluck(:user_id)
  end

  def audited_by?(user)
    !!(user && self.auditor_user_ids.detect {|uid| uid == user.id })
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
    #elsif text_changed?
      #Mailer.wiki_content_updated(self).deliver
    end
  end
end