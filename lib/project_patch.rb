require_dependency 'project'

module CodeAudit
	module ProjectPatch
		def self.included(base) # :nodoc:
			base.extend(ClassMethods)
			base.send(:include, InstanceMethods)

			base.class_eval do
				unloadable

				has_many :audits
			end
		end

		module ClassMethods
		end

		module InstanceMethods
		end
	end
end

Project.send(:include, CodeAudit::ProjectPatch) unless Project.included_modules.include? CodeAudit::ProjectPatch
