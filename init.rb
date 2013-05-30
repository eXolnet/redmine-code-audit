require 'redmine'

# Patch the Redmine core
require 'application_helper_patch'


Redmine::Plugin.register :code_audit do
  name 'Code Audit'
  author 'eXolnet'
  description 'This is allow developers to audit code from the repositories.'
  version '0.0.2'
  url 'https://redmine.exolnet.com/projects/redmine-code-audit'
  author_url 'http://www.exolnet.com'
  
  project_module :audits do
    permission :audits, { :audits => [:index] }, :public => true
  end

  menu :project_menu, :audits, { :controller => 'audits', :action => 'index' }, :caption => 'Audits', :before => :settings, :param => :project_id
end
