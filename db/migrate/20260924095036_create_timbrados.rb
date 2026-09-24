class CreateTimbrados < ActiveRecord::Migration[8.0]
  def change
    create_table :timbrados do |t|
      t.string :external_id, null: false
      t.references :factura, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :status, null: false
      t.string :uuid_fiscal
      t.string :error

      t.timestamps
    end

    add_index :timbrados, :external_id, unique: true
  end
end
