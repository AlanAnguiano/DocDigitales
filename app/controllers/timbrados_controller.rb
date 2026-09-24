class TimbradosController < ApplicationController
  def create
    result = TimbradoService.call(
      external_id: timbrado_params[:external_id],
      invoice_id: timbrado_params[:invoice_id],
      amount: timbrado_params[:amount]
    )

    render json: result[:body], status: result[:status]
  end

  private

  def timbrado_params
    params.permit(:external_id, :invoice_id, :amount)
  end
end