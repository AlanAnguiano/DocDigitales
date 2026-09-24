require "rails_helper"

RSpec.describe "POST /timbrados", type: :request do
  let(:factura) { Factura.create!(folio: "FolioRequest-01") }
  let(:external_id) { "req-abc-123" }
  let(:payload) do
    {
      external_id: external_id,
      invoice_id: factura.id,
      amount: 1500
    }
  end

  let(:pac_success) do
    instance_double(PacGateway, timbrar: { success: true, uuid_fiscal: "uuid-req-123" })
  end

  let(:pac_failure) do
    instance_double(PacGateway, timbrar: { success: false, error: "Timeout" })
  end

  def post_timbrado(body = payload)
    post "/timbrados", params: body, as: :json
  end

  before do
    allow(PacGateway).to receive(:new).and_return(pac_success)
  end

  it "responde 201 en el primer intento exitoso" do
    post_timbrado

    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include(
      "status" => "timbrada",
      "external_id" => external_id,
      "uuid_fiscal" => "uuid-req-123"
    )
  end

  it "responde 200 con el mismo resultado si se reenvia el external_id" do
    post_timbrado
    post_timbrado

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["uuid_fiscal"]).to eq("uuid-req-123")
    expect(Timbrado.where(external_id: external_id).count).to eq(1)
  end

  it "responde 422 cuando el PAC falla" do
    allow(PacGateway).to receive(:new).and_return(pac_failure)

    post_timbrado

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to include(
      "status" => "fallida",
      "external_id" => external_id,
      "error" => "Timeout"
    )
  end

  it "responde 404 si la factura no existe" do
    post_timbrado(payload.merge(invoice_id: 0))

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body["error"]).to be_present
  end

  it "responde 400 si el payload es invalido" do
    post_timbrado(payload.merge(external_id: nil))

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["error"]).to be_present
  end
end
