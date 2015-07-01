class AuditComment < ActiveRecord::Base
  belongs_to :audit
  belongs_to :user

  has_many :inline_comments, :class_name => 'AuditCommentInline', :dependent => :destroy

  validates_presence_of :audit, :user
end