require "rails_helper"

RSpec.describe TimbradoService do
  let(:factura) { Factura.create!(folio: "F-SERVICE-01") }
  let(:external_id) { "req-abc-123" }
  let(:amount) { 1500 }

  let(:pac_success) do
    instance_double(PacGateway, timbrar: { success: true, uuid_fiscal: "uuid-fijo-123" })
  end

  let(:pac_failure) do
    instance_double(PacGateway, timbrar: { success: false, error: "Timeout" })
  end

  def call_service(pac_client:, external_id: self.external_id, invoice_id: factura.id, amount: self.amount)
    described_class.call(
      external_id: external_id,
      invoice_id: invoice_id,
      amount: amount,
      pac_client: pac_client
    )
  end

  describe ".call" do
    context "cuando el payload es invalido" do
      it "responde 400 si falta external_id" do
        result = call_service(pac_client: pac_success, external_id: nil)

        expect(result[:status]).to eq(:bad_request)
        expect(result[:body][:error]).to eq(TimbradoService::ERROR_MSG[:external_id_blank])
      end

      it "responde 400 si amount no es numerico" do
        result = call_service(pac_client: pac_success, amount: "abc")

        expect(result[:status]).to eq(:bad_request)
        expect(result[:body][:error]).to eq(TimbradoService::ERROR_MSG[:amount_not_numeric])
      end
    end

    context "cuando la factura no existe" do
      it "responde 404" do
        result = call_service(pac_client: pac_success, invoice_id: 0)

        expect(result[:status]).to eq(:not_found)
        expect(result[:body][:error]).to eq(TimbradoService::ERROR_MSG[:not_found])
      end
    end

    context "cuando el PAC responde success" do
      it "crea el timbrado, actualiza la factura y responde 201" do
        result = call_service(pac_client: pac_success)

        expect(result[:status]).to eq(:created)
        expect(result[:body]).to include(
          status: "timbrada",
          external_id: external_id,
          uuid_fiscal: "uuid-fijo-123"
        )

        timbrado = Timbrado.find_by!(external_id: external_id)
        expect(timbrado.status).to eq("timbrada")
        expect(factura.reload.estatus).to eq("timbrada")
      end
    end

    context "cuando el PAC responde fallo" do
      it "persiste fallida y responde 422" do
        result = call_service(pac_client: pac_failure)

        expect(result[:status]).to eq(:unprocessable_entity)
        expect(result[:body]).to include(
          status: "fallida",
          external_id: external_id,
          error: "Timeout"
        )

        timbrado = Timbrado.find_by!(external_id: external_id)
        expect(timbrado.status).to eq("fallida")
        expect(factura.reload.estatus).to eq("pendiente")
      end
    end

    context "cuando se reenvia el mismo external_id" do
      it "devuelve el mismo resultado exitoso con 200 y no vuelve a llamar al PAC" do
        call_service(pac_client: pac_success)

        pac_replay = instance_double(PacGateway)
        expect(pac_replay).not_to receive(:timbrar)

        result = call_service(pac_client: pac_replay)

        expect(result[:status]).to eq(:ok)
        expect(result[:body][:uuid_fiscal]).to eq("uuid-fijo-123")
        expect(Timbrado.where(external_id: external_id).count).to eq(1)
      end

      it "devuelve el mismo fallo con 200" do
        call_service(pac_client: pac_failure)

        result = call_service(pac_client: pac_success)

        expect(result[:status]).to eq(:ok)
        expect(result[:body]).to include(status: "fallida", error: "Timeout")
        expect(Timbrado.where(external_id: external_id).count).to eq(1)
      end
    end
  end
end
