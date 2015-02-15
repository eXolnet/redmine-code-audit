class AuditsController < ApplicationController
  unloadable

  helper :repositories
  include RepositoriesHelper

  def index
  	@project = Project.find(params[:project_id])
  	@audits = @project.audits.order("#{Audit.table_name}.updated_on DESC").all
  end

  def new
  	@project = Project.find(params[:project_id])
  end

  def create
  	@project = Project.find(params[:project_id])

  	revision = params[:revision]

  	@audit = Audit.new(params[:audit])
  	@audit.project = @project
  	@audit.user = User.current
  	@audit.changeset = @project.repository.changesets.where("#{Changeset.table_name}.revision LIKE ?", "%#{revision}%").first

    if @audit.save
      flash[:notice] = 'The audit was succesfully created.'
      redirect_to project_audit_path(@project, @audit)
      return
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

  def update
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

  def delete
  	@project = Project.find(params[:project_id])
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
