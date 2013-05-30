class CreateAudits < ActiveRecord::Migration
  def change
    create_table :audits do |t|
      t.integer  :project_id,        :null => false
      t.integer  :user_id,           :null => false
      t.integer  :changeset_id,      :null => false
      t.string   :summary,           :null => false
      t.text     :details
      t.datetime :created_on,        :null => false
      t.datetime :updated_on,        :null => false
    end
    
    create_table :audit_comments do |t|
      t.integer  :audit_id,          :null => false
      t.integer  :user_id,           :null => false
      t.text     :content
      t.datetime :created_on,        :null => false
      t.datetime :updated_on,        :null => false
    end
    
    create_table :audit_comment_inlines do |t|
      t.integer  :audit_comment_id,  :null => false
      t.integer  :change_id,         :null => false
      t.integer  :line_begin,        :null => false
      t.integer  :line_end
      t.text     :content
    end
  end
end