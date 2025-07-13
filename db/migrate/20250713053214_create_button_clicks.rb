class CreateButtonClicks < ActiveRecord::Migration[8.0]
  def change
    create_table :button_clicks do |t|
      t.string :ip_address
      t.string :user_agent
      t.datetime :clicked_at, null: false

      t.timestamps
    end
    
    add_index :button_clicks, :clicked_at
    add_index :button_clicks, :ip_address
  end
end
