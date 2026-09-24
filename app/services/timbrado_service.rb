class TimbradoService
  attr_reader :external_id, :invoice_id, :amount
  ERROR_MSG = {
    not_found: "La factura no fue encontrada",
    bad_request: "El payload no es válido",
    external_id_blank: "El external_id es requerido",
    invoice_id_blank: "El invoice_id es requerido",
    amount_blank: "El amount es requerido",
    amount_not_numeric: "El amount debe ser un número",
    amount_not_positive: "El amount debe ser un número positivo"
  }.freeze

  def self.call(external_id:, invoice_id:, amount:, pac_client: nil)
    new(external_id:, invoice_id:, amount:, pac_client:).call
  end

  def initialize(external_id:, invoice_id:, amount:, pac_client: nil)
    @external_id = external_id
    @invoice_id = invoice_id
    @amount = amount
    @current_error = nil
    @pac_client = pac_client
  end

  def call
    return bad_request if invalid_payload?
    return not_found if factura.blank?

    return previously_created_response if timbrado.present?

    pac_response = pac_client.timbrar(factura: factura, amount: amount)

    if pac_response[:success]
      create_timbrado(pac_response[:uuid_fiscal])
      factura.update!(estatus: Factura::STATUS[:timbrada])
      success_response
    else
      failed_timbrado(error: pac_response[:error])
      failure_response(status_code: :unprocessable_entity, error: pac_response[:error])
    end
  rescue ActiveRecord::RecordNotUnique
    @timbrado = nil
    previously_created_response
  end

  private

  def create_timbrado(uuid_fiscal)
    @timbrado = Timbrado.create!(
      external_id: @external_id,
      factura_id: factura.id,
      amount: @amount,
      uuid_fiscal: uuid_fiscal,
      status: Timbrado::STATUS[:timbrada]
    )
  end

  def failed_timbrado(error:)
    @timbrado = Timbrado.create!(
      external_id: @external_id,
      factura_id: factura.id,
      amount: @amount,
      uuid_fiscal: nil,
      error: error,
      status: Timbrado::STATUS[:fallida]
    )
  end

  def timbrado
    @timbrado ||= Timbrado.find_by(external_id: @external_id)
  end

  def factura
    @factura ||= Factura.find_by(id: @invoice_id)
  end

  def pac_client
    @pac_client ||= PacGateway.new
  end

  def invalid_payload?
    @current_error =
    if external_id.blank?
      ERROR_MSG[:external_id_blank]
    elsif invoice_id.blank?
      ERROR_MSG[:invoice_id_blank]
    elsif amount.blank?
      ERROR_MSG[:amount_blank]
    elsif !amount_numeric?
      ERROR_MSG[:amount_not_numeric]
    elsif Float(amount) <= 0
      ERROR_MSG[:amount_not_positive]
    end

    @current_error.present?
  end

  def amount_numeric?
    Float(amount)
    true
  rescue ArgumentError, TypeError
    false
  end

  def not_found(error_msg: ERROR_MSG[:not_found])
    {
      body: {
        error: error_msg
      },
      status: :not_found
    }
  end

  def bad_request
    {
      body: {
        error: @current_error
      },
      status: :bad_request
    }
  end

  def previously_created_response
    if timbrado.status == Timbrado::STATUS[:timbrada]
      success_response(status_code: :ok)
    else
      failure_response(status_code: :ok)
    end
  end

  def failure_response(status_code: :ok, error: nil)
    {
      body: {
        status: "fallida",
        external_id: @external_id,
        error: error || timbrado&.error || "No se pudo timbrar la factura"
      },
      status: status_code
    }
  end

  def success_response(status_code: :created)
    {
      body: {
        status: "timbrada",
        external_id: @external_id,
        uuid_fiscal: timbrado.uuid_fiscal
      },
      status: status_code
    }
  end
end
