# Redmine Code Audit

Code Audit is a Redmine plugin that allows users to post audits on commits in repositories linked to projects.

## Installation

1. Follow the Redmine plugin installation steps at: http://www.redmine.org/wiki/redmine/Plugins and make sure the plugin is installed to +vendor/plugins/redmine_code_audit+
2. Restart your Redmine web servers (e.g. mongrel, thin, mod_rails)
3. Login and enable the "Audit" module on the projects you want to use it.

# Contributing

* `rake redmine:plugins:migrate RAILS_ENV=production`
