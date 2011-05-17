class CreateEmailResponseCodes < ActiveRecord::Migration
  def self.up
    create_table :email_response_codes do |t|
      t.column :code, :integer
      t.column :email, :string
      t.column :created_at, :datetime
    end
    add_index :email_response_codes, :code
  end

  def self.down
    drop_table :email_response_codes
  end
end
