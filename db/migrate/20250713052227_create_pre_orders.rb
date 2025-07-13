class CreatePreOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :pre_orders do |t|
      t.string :email
      t.boolean :marketing_consent, default: false

      t.timestamps
    end
  end
end
