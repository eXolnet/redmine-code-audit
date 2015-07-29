class AuditsController < ApplicationController
  default_search_scope :issues

  helper :repositories
  include RepositoriesHelper
  helper :watchers
  include WatchersHelper
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include CodeAudit::AuditHelper

  def index
    retrieve_audit_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      @project = Project.find(params[:project_id])

      @limit = per_page_option
      @audit_count = @query.audit_count
      @audit_pages = Paginator.new @audit_count, @limit, params['page']
      @offset ||= @audit_pages.offset
      @audits = @query.audits(:order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)

      respond_to do |format|
        format.html { render :template => 'audits/index', :layout => !request.xhr? }
        format.js
      end
    else
      respond_to do |format|
        format.html { render(:template => 'audits/index', :layout => !request.xhr?) }
        format.js
      end
    end
  end

  def new
    @project = Project.find(params[:project_id])

    unless @project.repository
      flash[:warning] = l(:notice_audit_no_repository_configured)
    end

    @project = Project.find(params[:project_id])
    @audit ||= Audit.new(params[:audit])
    @available_auditors = @project.users.sort
    #@available_watchers = @project.users.sort
  end

  def create
    @project = Project.find(params[:project_id])

    unless @project.repository
      flash[:warning] = l(:notice_audit_no_repository_configured)
      redirect_to new_project_audit_path(@project, @audit)
      return
    end

    @audit = Audit.new
    @audit.project = @project
    @audit.user = User.current
    @audit.status = Audit::STATUS_AUDIT_REQUESTED
    @audit.safe_attributes = params[:audit]

    if @audit.save
      flash[:notice] = l(:notice_audit_successful_create, :id => view_context.link_to("##{@audit.id}", project_audit_path(@project, @audit)))
      redirect_to project_audit_path(@project, @audit)
      return
    else
      @available_auditors = @project.users.sort

      render :action => 'new'
    end
  end

  def show
    @project = Project.find(params[:project_id])
    @audit = Audit.find(params[:id])
    @changeset = @audit.changeset
    @repository = @changeset.repository
    @comments = @audit.comments.all
    @filechanges = @changeset.filechanges

    for comment in @comments
      comment.inline_comments.empty?
    end

    @rev = 'master'

    # Prepare diff with last revision
    @diff = @repository.diff(nil, @changeset.revision, nil)
    @diff_type = 'sbs'
    @diff_format_revisions = @repository.diff_format_revisions(@changeset, nil)
  end

  def comment
    @project = Project.find(params[:project_id])
    @audit = Audit.find(params[:id])

    # Update status
    unless params[:audit_action] && params[:audit_action].empty?
      @audit.status = params[:audit_action]
      @audit.save
    end

    # Save comment
    @comment = AuditComment.new()
    @comment.content = params[:audit_comment]
    @comment.audit = @audit
    @comment.user = User.current
    @audit.comments << @comment

    # Save inline comments
    unless params[:inline_comment].nil?
      params[:inline_comment].each do |key, value|
        @inline_comment = AuditCommentInline.new()

        @inline_comment.change_id  = value[:change_id]
        @inline_comment.line_begin = value[:line_begin]
        @inline_comment.content    = value[:content]

        if value[:line_begin] != value[:line_end]
          @inline_comment.line_end = value[:line_end]
        end

        @comment.inline_comments << @inline_comment
      end
    end

    #if @comment.save
    #  redirect_to project_audit_path(@project, @audit)
    #  redirect_to trackers_path
    #  return
    #end

    redirect_to project_audit_path(@project, @audit)

    #show
    #render :action => 'show'
  end

  def edit
    @project = Project.find(params[:project_id])
    @audit = Audit.find(params[:id])
    @available_auditors = @project.users.sort
  end

  def update
    @project = Project.find(params[:project_id])
    @audit = Audit.find(params[:id])

    # Reset the auditor_user_ids to uncheck selected auditors that
    # are not checked anymore
    @audit.auditor_user_ids = []

    if @audit.update_attributes(params[:audit])
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_audit_path(@project, @audit)
      return
    end

    edit
    render :action => 'edit'
  end

  def destroy
    @project = Project.find(params[:project_id])
    @audit = Audit.find(params[:id])
    @audit.destroy

    redirect_to project_audits_path(@project)
  end

  def changesets
    @project = Project.find(params[:project_id])

    @changesets = []
    q = (params[:q] || params[:term]).to_s.strip
    if q.present?
      @changesets += @project.repository.changesets.where("#{Changeset.table_name}.revision LIKE ?", "%#{q}%").order("#{Changeset.table_name}.committed_on DESC").limit(10).all
      @changesets.compact!
    end

    render :layout => false
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
