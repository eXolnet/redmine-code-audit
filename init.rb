require 'redmine'

# Patch the Redmine core
if Rails::VERSION::MAJOR < 3
  require 'dispatcher'
  object_to_prepare = Dispatcher
else
  object_to_prepare = Rails.configuration
end

object_to_prepare.to_prepare do
  require 'application_helper_patch'
  require 'project_patch'
  require 'changeset_patch'
end

# Configure our plugin
Redmine::Plugin.register :code_audit do
  name 'Code Audit'
  author 'eXolnet'
  description 'Allows users to post audits on commits in repositories linked to projects.'
  version '0.1.0'
  url 'http://exolnet.github.io/redmine-code-audit'
  author_url 'http://www.exolnet.com'

  project_module :audits do
    permission :view_audits, { :audits => [:index] }
  end

  menu :project_menu, :audits, { :controller => 'audits', :action => 'index' }, :caption => 'Audits', :before => :settings, :param => :project_id
end
