require "rails_helper"

RSpec.describe PacGateway do
  let(:factura) { Factura.create!(folio: "Folio-PacGat-01") }

  before do
    allow_any_instance_of(described_class).to receive(:sleep)
  end

  describe "#timbrar" do
    it "responde exito con uuid_fiscal" do
      result = described_class.new.timbrar(factura: factura, amount: 100)

      expect(result[:success]).to eq(true)
      expect(result[:uuid_fiscal]).to be_present
    end

    it "responde fallo cuando force_failure es true" do
      result = described_class.new(force_failure: true).timbrar(factura: factura, amount: 100)

      expect(result).to eq(success: false, error: "Timeout")
    end
  end
end
