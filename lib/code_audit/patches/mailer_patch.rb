require_dependency 'mailer'

module CodeAudit
  module MailerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
    end

    module InstanceMethods
      def audit_created(audit)
        redmine_headers 'Project' => audit.project.identifier
        @audit = audit
        @project = audit.project
        @author = audit.author
        @changeset = audit.changeset
        @repository = @changeset.repository
        @audit_url = url_for(:controller => 'audits', :action => 'show', :project => @project, :id => @audit)
        recipients = audit.recipients
        cc = audit.watcher_recipients - recipients

        mail :to => recipients,
          :cc => cc,
          :subject => "[#{audit.project.name} - Audit ##{audit.id}] #{audit.summary}"
      end
    end
  end
end

Mailer.send(:include, CodeAudit::MailerPatch) unless Mailer.included_modules.include? CodeAudit::MailerPatch
