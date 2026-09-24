class CreateFacturas < ActiveRecord::Migration[8.0]
  def change
    create_table :facturas do |t|
      t.string :folio
      t.string :estatus, null: false, default: "pendiente"

      t.timestamps
    end
  end
end
