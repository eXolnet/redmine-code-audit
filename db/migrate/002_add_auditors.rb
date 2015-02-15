class AddAuditors < ActiveRecord::Migration
  def change
    create_table :audit_auditors do |t|
      t.integer  :audit_id,          :null => false
      t.integer  :user_id,           :null => false
    end
  end
end