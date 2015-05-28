module ApplicationHelper
  def link_to_audit(audit, options={})
    changeset = audit.changeset
    repository = changeset.repository
    project = repository.project

    text = options.delete(:text) || audit.summary
    #rev = revision.respond_to?(:identifier) ? revision.identifier : revision
    link_to(
        h(text),
        {:controller => 'audits', :action => 'show', :project_id => project, :id => audit},
        :title => text
      )
  end
end