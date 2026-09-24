class Factura < ApplicationRecord
  STATUS = {
    pending: "pendiente",
    timbrada: "timbrada",
  }.freeze

  has_many :timbrados, dependent: :destroy

  validates :folio, presence: true
  validates :estatus, presence: true, inclusion: { in: STATUS.values }
end
