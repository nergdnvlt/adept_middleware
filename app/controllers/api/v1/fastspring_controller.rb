class Api::V1::FastspringController < ApiController
  before_action :account_params, :session_params

  def accounts
    response = conn('accounts', account_payload)
    if response.code == 200
      puts "Account ID: #{response["account"]}"
      render json: { "accountId": response["account"] }, status: 200
    elsif response.code == 400
      puts "Account ID: #{response["account"]}"
      render json: { "accountId": response["error"]["email"].split(' ')[-1].split('/')[-1] }, status: 200
    else
      puts "Error: #{response["error"]}"
      render json: { "message": response["error"] }, status: 400
    end
  end

  def sessions
    response = conn('sessions', session_payload)
    if response.code == 200
      puts "Session ID: #{response["id"]}"
      render json: { "sessionId": response["id"] }, status: 200
    else
      puts "Error: #{response["error"]}"
      render json: { "message": response["error"] }, status: 400
    end
  end

  def conn(uri, payload)
    HTTParty.post(
      "https://api.fastspring.com/#{uri}",
      basic_auth: {
        username: Rails.application.credentials.fastspring[:username],
        password: Rails.application.credentials.fastspring[:password]
      },
      headers: {
        "Content-Type" => "application/json"
      },
      body: payload.to_json
    )
  end

  private

  # Fastspring Account Methods
  def account_params
    @account_params ||= params.require(:fastspring).permit(
      :language,
      :country,
      contact: [
        :first,
        :last,
        :email
      ],
    )
  end

  def account_payload
    {
      contact: {
        first: @account_params[:contact][:first],
        last: @account_params[:contact][:last],
        email: @account_params[:contact][:email]
      },
      country: @account_params[:country],
      language: @account_params[:language]
    }
  end

  # Fastspring Session Methods
  def session_params
    @session_params ||= params.require(:fastspring).permit(
      :accountId,
      :product,
      :discount
    )
  end

  def session_payload
    {
      account: @session_params[:accountId],
      items: [
        {
          product: @session_params[:product],
          pricing: {
            quantityDiscounts: {
              "1": {
                "USD": @session_params[:discount] }
            }
          }
        }
      ]
    }
  end
end
