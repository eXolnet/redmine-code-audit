require_dependency 'application_helper'

module CodeAudit
  module Patches
    module ApplicationHelperPatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
      end

      module InstanceMethods
        def link_to_audit(audit, options={})
          changeset = audit.changeset
          repository = changeset.repository
          project = repository.project

          text = options.delete(:text) || audit.summary
          #rev = revision.respond_to?(:identifier) ? revision.identifier : revision

          link_to(h(text), {:controller => 'audits', :action => 'show', :project_id => project, :id => audit}, :title => text)
        end
      end
    end
  end
end

unless ApplicationHelper.included_modules.include? CodeAudit::Patches::ApplicationHelperPatch
  ApplicationHelper.send(:include, CodeAudit::Patches::ApplicationHelperPatch)
end
