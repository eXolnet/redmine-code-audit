require_dependency 'mailer'

module CodeAudit
  module Patches
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
          @audit_url = project_audit_path(@project, @audit)
          recipients = audit.recipients
          cc = audit.watcher_recipients - recipients

          mail :to => recipients,
            :cc => cc,
            :subject => "[#{audit.project.name} - Audit ##{audit.id}] #{audit.summary}"
        end

        def audit_comment_created(comment)
          audit = comment.audit

          redmine_headers 'Project' => audit.project.identifier
          @audit = audit
          @project = audit.project
          @author = audit.author
          @changeset = audit.changeset
          @repository = @changeset.repository
          @audit_url = project_audit_path(@project, @audit)
          @auditor = comment.user
          recipients = audit.recipients
          cc = audit.watcher_recipients - recipients

          mail :to => recipients,
            :cc => cc,
            :subject => "[#{audit.project.name} - Audit ##{audit.id}] #{audit.summary}"
        end
      end
    end
  end
end

unless Mailer.included_modules.include? CodeAudit::Patches::MailerPatch
  Mailer.send(:include, CodeAudit::Patches::MailerPatch)
end
