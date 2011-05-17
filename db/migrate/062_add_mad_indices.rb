class AddMadIndices < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction {
      add_index :claim_votes, [:claim_id, :current]
      add_index :claim_votes, [:claim_id, :user_id, :current]
      add_index :claims, :state
      add_index :claims, :urlslug
      add_index :comments, :claim_id
      add_index :contacts, :user_id
      add_index :contacts, :contact_id
      add_index :cred1_scores, [:user_id, :tag_id]
      add_index :cred1_scores, :user_id
      add_index :cred2_scores, [:user_id, :tag_id]
      add_index :cred2_scores, :user_id
      add_index :creds, :source_id
      add_index :creds, :sink_id
      add_index :email_response_codes, :email
      add_index :flaggings, :claim_id
      add_index :flaggings, :user_id
      add_index :imagings, :image_id
      add_index :imagings, [:imagable_id, :imagable_type]
      add_index :invitations, :recipient_id
      add_index :invitations, :sender_id
      add_index :looks, [:object_id, :object_type]
      add_index :looks, :user_id
      add_index :max_scores, :tag_id
      add_index :mentioned_identifiers, :claim_id
      add_index :mentioned_identifiers, :identifier_id
      add_index :open_id_associations, :handle
      add_index :open_id_nonces, :nonce
      add_index :taggings, [:taggable_id, :taggable_type]
      add_index :taggings, [:tag_id, :taggable_type]
      add_index :tags, :name
      add_index :users, :state
      add_index :users, :nickname
    }
  end

  def self.down
    ActiveRecord::Base.transaction {
      remove_index :claim_votes, [:claim_id, :current]
      remove_index :claim_votes, [:claim_id, :user_id, :current]
      remove_index :claims, :state
      remove_index :claims, :urlslug
      remove_index :comments, :claim_id
      remove_index :contacts, :user_id
      remove_index :contacts, :contact_id
      remove_index :cred1_scores, [:user_id, :tag_id]
      remove_index :cred1_scores, :user_id
      remove_index :cred2_scores, [:user_id, :tag_id]
      remove_index :cred2_scores, :user_id
      remove_index :creds, :source_id
      remove_index :creds, :sink_id
      remove_index :email_response_codes, :email
      remove_index :flaggings, :claim_id
      remove_index :flaggings, :user_id
      remove_index :imagings, :image_id
      remove_index :imagings, [:imagable_id, :imagable_type]
      remove_index :invitations, :recipient_id
      remove_index :invitations, :sender_id
      remove_index :looks, [:object_id, :object_type]
      remove_index :looks, :user_id
      remove_index :max_scores, :tag_id
      remove_index :mentioned_identifiers, :claim_id
      remove_index :mentioned_identifiers, :identifier_id
      remove_index :open_id_associations, :handle
      remove_index :open_id_nonces, :nonce
      remove_index :taggings, [:taggable_id, :taggable_type]
      remove_index :taggings, [:tag_id, :taggable_type]
      remove_index :tags, :name
      remove_index :users, :state
      remove_index :users, :nickname
    }
  end
end
