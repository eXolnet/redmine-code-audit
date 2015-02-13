require 'redmine'

# Patch the Redmine core
require 'application_helper_patch'
require 'project_patch'


Redmine::Plugin.register :code_audit do
  name 'Code Audit'
  author 'eXolnet'
  description 'Allows users to post audits on commits in repositories linked to projects.'
  version '0.1.0'
  url 'http://exolnet.github.io/redmine-code-audit'
  author_url 'http://www.exolnet.com'

  project_module :audits do
    permission :audits, { :audits => [:index] }, :public => true
  end

  menu :project_menu, :audits, { :controller => 'audits', :action => 'index' }, :caption => 'Audits', :before => :settings, :param => :project_id
end
