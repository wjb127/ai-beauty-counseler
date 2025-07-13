# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_13_053214) do
  create_table "button_clicks", force: :cascade do |t|
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "clicked_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clicked_at"], name: "index_button_clicks_on_clicked_at"
    t.index ["ip_address"], name: "index_button_clicks_on_ip_address"
  end

  create_table "pre_orders", force: :cascade do |t|
    t.string "email"
    t.boolean "marketing_consent", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
