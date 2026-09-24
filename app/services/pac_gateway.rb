class PacGateway
  def initialize(force_failure: false)
    @force_failure = force_failure
  end

  def timbrar(factura:, amount:)
    sleep(0.2)
    return timeout_response if @force_failure

    success_response
  end

  private

  def timeout_response
    { success: false, error: "Timeout" }
  end

  def success_response
    { success: true, uuid_fiscal: SecureRandom.uuid }
  end
end
