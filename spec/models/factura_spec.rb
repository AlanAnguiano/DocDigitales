require 'rails_helper'

RSpec.describe Factura, type: :model do
  describe 'validations' do
    it 'valido con atributos validos' do
      factura = Factura.new(folio: "Test-01", estatus: Factura::STATUS[:pendiente])
      expect(factura).to be_valid
    end

    it "usa estado default 'pendiente' si no se provee" do
      factura = Factura.create!(folio: 'test-02')
      expect(factura.estatus).to eq(Factura::STATUS[:pendiente])
    end

    it 'es invalido sin folio' do
      factura = Factura.new(estatus: Factura::STATUS[:pendiente])
      expect(factura).not_to be_valid
      expect(factura.errors[:folio]).to be_present
    end

    it 'es invalido con estatus invalido' do
      factura = Factura.new(folio: 'test-03', estatus: 'cancelada')
      expect(factura).not_to be_valid
      expect(factura.errors[:estatus]).to be_present
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:timbrados) }
  end
end
