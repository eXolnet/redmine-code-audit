class AuditsController < ApplicationController
  unloadable

  helper :repositories
  include RepositoriesHelper
  helper :watchers
  include WatchersHelper
  helper :sort
  include SortHelper

  def index
    @project = Project.find(params[:project_id])

    sort_init 'updated_on', 'desc'
    sort_update 'revision' => "#{Changeset.table_name}.revision",
                'summary' => "#{Audit.table_name}.summary",
                'committed_on' => "#{Changeset.table_name}.committed_on",
                'updated_on' => "#{Audit.table_name}.updated_on"

    @query = @project.audits

    @limit = per_page_option
    @audit_count = @query.count
    @audit_pages = Paginator.new @audit_count, @limit, params['page']
    @offset ||= @audit_pages.offset

    @audits = @query
      .includes(:changeset, :user)
      .reorder(sort_clause)
      .offset(@offset)
      .limit(@limit)
      .all
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

    revision = params[:revision]

    @audit = Audit.new(params[:audit])
    @audit.project = @project
    @audit.user = User.current
    @audit.changeset = @project.repository.changesets.where("#{Changeset.table_name}.revision LIKE ?", "%#{revision}%").first

    if @audit.save
      unless params[:auditors_user_ids].nil?
          params[:auditors_user_ids].each do |value|
          @audit.add_auditor(User.find(value))
          end
      end

      flash[:notice] = l(:notice_audit_successful_create, :id => view_context.link_to("##{@audit.id}", project_audit_path(@project, @audit)))
      redirect_to project_audit_path(@project, @audit)
      return
    else
      redirect_to new_project_audit_path(@project)
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

    # Save comment
    @comment = AuditComment.new(params[:audit])
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
