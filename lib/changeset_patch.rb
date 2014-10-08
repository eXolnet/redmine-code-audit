require_dependency 'changeset'

class Changeset
	after_create :scan_for_auditors
	
  def scan_for_auditors
    scan_comment_for_auditors
  end
  
  def scan_comment_for_auditors
    return if comments.blank?

    referenced_auditors = []

    comments.scan(/(?:Audit|Auditor)s?\s*:\s*((?:(?:\s*,\s*)?[a-z0-9_\-@\.]+)+)/i) do |match|
      auditors = match[0].gsub(/\.$/, '')
	  referenced_auditors = auditors.split(/\s*,\s*/)
    end

    referenced_auditors.uniq!

    unless referenced_auditors.empty?
      @audit = Audit.new()
      @audit.project = self.repository.project
      @audit.user = self.user
      @audit.changeset = self
      @audit.summary = self.short_comments
    
      @audit.save
    
	  # TODO-AD: Save referenced auditors
    end
  end
end
