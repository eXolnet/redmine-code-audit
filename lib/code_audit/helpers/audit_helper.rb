module CodeAudit
  module AuditHelper
    def retrieve_audit_query
      if !params[:query_id].blank?
        logger.debug "Query by ID"

        cond = "project_id IS NULL"
        cond << " OR project_id = #{@project.id}" if @project
        @query = AuditQuery.where(cond).find(params[:query_id])
        raise ::Unauthorized unless @query.visible?
        @query.project = @project
        session[:audit_query] = {:id => @query.id, :project_id => @query.project_id}
        sort_clear
      elsif true || api_request? || params[:set_filter] || session[:audit_query].nil? || session[:audit_query][:project_id] != (@project ? @project.id : nil)
        logger.debug "Query from request"

        @query = AuditQuery.new(:name => "_")
        @query.project = @project
        @query.build_from_params(params)
        session[:query] = {:project_id => @query.project_id,
                           :filters => @query.filters,
                           :group_by => @query.group_by,
                           :column_names => @query.column_names}
      else
        logger.debug "Query from session"

        # retrieve from session
        @query = nil
        @query ||= AuditQuery.find_by_id(session[:audit_query][:id]) if session[:audit_query][:id]
        @query ||= AuditQuery.new(:name => "_",
                                  :filters => session[:audit_query][:filters],
                                  :group_by => session[:audit_query][:group_by],
                                  :column_names => session[:audit_query][:column_names])
        @query.project = @project
      end
    end
  end
end

ActionView::Base.send :include, CodeAudit::AuditHelper
