class Timbrado < ApplicationRecord
  belongs_to :factura

  STATUS = {
    timbrada: "timbrada",
    fallida: "fallida"
  }.freeze

  validates :external_id, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: true
  validates :status, presence: true, inclusion: { in: STATUS.values }
  validates :uuid_fiscal, presence: true, if: -> { status == STATUS[:timbrada] }
  validates :error, presence: true, if: -> { status == STATUS[:fallida] }
end