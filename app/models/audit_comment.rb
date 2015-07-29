class AuditComment < ActiveRecord::Base
  belongs_to :audit
  belongs_to :user

  has_many :inline_comments, :class_name => 'AuditCommentInline', :dependent => :destroy

  validates_presence_of :audit, :user

  after_save :send_notification

  private

  def send_notification
    # new_record? returns false in after_save callbacks
    if id_changed?
      Mailer.audit_comment_created(self).deliver
    #elsif text_changed?
      #Mailer.audit_comment_updated(self).deliver
    end
  end
end