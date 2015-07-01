require_dependency 'changeset'

module CodeAudit
  module ChangesetPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        after_create :scan_for_auditors
      end
    end

    module ClassMethods
    end

    module InstanceMethods
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
  end
end

Changeset.send(:include, CodeAudit::ChangesetPatch) unless Changeset.included_modules.include? CodeAudit::ChangesetPatch
