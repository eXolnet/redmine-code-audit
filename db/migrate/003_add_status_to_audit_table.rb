class CreateAudits < ActiveRecord::Migration
  def self.up
    add_column :audits, :status, :string, :default => "", :null => false, :after => :details
  end

  def self.down
    remove_column :audits, :status
  end
end