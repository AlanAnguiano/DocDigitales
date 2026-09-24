# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


facturas = [
  { folio: "F-000001", estatus: Factura::STATUS[:pendiente] },
  { folio: "F-000002", estatus: Factura::STATUS[:pendiente] },
  { folio: "F-000003", estatus: Factura::STATUS[:timbrada] },
  { folio: "F-000004", estatus: Factura::STATUS[:pendiente] },
  { folio: "F-000005", estatus: Factura::STATUS[:timbrada] }
]

facturas.each do |factura|
  Factura.find_or_create_by!(folio: factura[:folio]) do |f|
    f.estatus = factura[:estatus]
  end
end

puts "Se han creado #{Factura.count} facturas"
puts "resumen de facturas creadas: #{Factura.pluck(:id, :folio, :estatus).inspect}"
