class AuditQuery < Query
  self.queried_class = Audit

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{Audit.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
    QueryColumn.new(:project),
    QueryColumn.new(:revision, :sortable => "#{Changeset.table_name}.revision"),
    QueryColumn.new(:summary, :sortable => "#{Audit.table_name}.summary"),
    QueryColumn.new(:status, :sortable => "#{Audit.table_name}.status"),
    QueryColumn.new(:committer),
    QueryColumn.new(:committed_on, :sortable => "#{Changeset.table_name}.committed_on"),
    QueryColumn.new(:user, :sortable => lambda {User.fields_for_order_statement("users")}),
    QueryColumn.new(:updated_on, :sortable => "#{Audit.table_name}.updated_on"),
  ]

  def initialize(attributes=nil, *args)
     super attributes
     self.filters = {}
     #self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
  end

  # Returns true if the query is visible to +user+ or the current user.
  def visible?(user=User.current)
    true
  end

  def initialize_available_filters
    principals = []
    subprojects = []

    if project
      principals += project.principals.sort
      unless project.leaf?
        subprojects = project.descendants.visible.all
        principals += Principal.member_of(subprojects)
      end
    else
      if all_projects.any?
        principals += Principal.member_of(all_projects)
      end
    end
    principals.uniq!
    principals.sort!
    users = principals.select {|p| p.is_a?(User)}

    # Project
    # if project.nil?
    #   project_values = []
    #   if User.current.logged? && User.current.memberships.any?
    #     project_values << ["<< #{l(:label_my_projects).downcase} >>", "mine"]
    #   end
    #   project_values += all_projects_values
    #   add_available_filter("project_id",
    #     :type => :list, :values => project_values
    #   ) unless project_values.empty?
    # end

    # User
    author_values = []
    author_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    author_values += users.collect{|s| [s.name, s.id.to_s] }
    add_available_filter("user_id",
      :name => l("label_submitter"), :type => :list, :values => author_values
    ) unless author_values.empty?

    # Misc
    add_available_filter "summary", :type => :text
    add_available_filter "status",
      :type => :list, :values => Audit.statuses.collect{|value, name| [name, value] }
    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past
  end

  # def available_columns
  #   return @available_columns if @available_columns
  # end

  def default_columns_names
    @default_columns_names = [:revision, :summary, :status, :committer, :committed_on, :user, :updated_on]
  end

  def audit_count
    Audit.count(:conditions => statement)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def audits(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    audits = Audit
      .joins(joins_for_order_statement(order_option.join(',')))
      .eager_load([:project, :changeset, :user])
      .where(options[:conditions])
      .order(order_option)
      .limit(options[:limit])
      .offset(options[:offset])

    audits
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
end