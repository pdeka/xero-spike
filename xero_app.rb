# This is an example app that provides a dashboard to make some example
# calls to the Xero API actions after authorising the app via OAuth 2.0.

require 'sinatra'
require 'sinatra/reloader' if development?
require 'xero-ruby'
require 'securerandom'
require 'dotenv/load'
require 'jwt'
require 'pp'
require 'rest-client'

set :session_secret, "328479283uf923fu8932fu923uf9832f23f232"
use Rack::Session::Pool
set :haml, :format => :html5

# Setup the credentials we use to connect to the XeroAPI
CREDENTIALS = {
  client_id: ENV['CLIENT_ID'],
  client_secret: ENV['CLIENT_SECRET'],
  redirect_uri: ENV['REDIRECT_URI'],
  scopes: ENV['SCOPES']
}

# We initialise an instance of the Xero API Client here so we can make calls
# to the API later. Memoization `||=`` will return a previously initialized client.
helpers do
  def xero_client
    @xero_client ||= XeroRuby::ApiClient.new(credentials: CREDENTIALS)
  end
end

# Before every request, we need to check that we have
# a session.
# If we don't, then redirect to the index page to prompt
# the user to go through the OAuth 2.0 authorization flow.
before do
  puts "Token::::::: #{session[:token_set]}"
  pass if request.path_info == '/callback'
  if (request.path_info != '/' && session[:token_set].nil?)
    redirect to('/')
  end
end

# On the homepage, we need to define a few variables that are used by the
# 'home.haml' layout file in the 'views/' directory.
get '/' do
  @token_set = session[:token_set]
  @auth_url = xero_client.authorization_url

  if @token_set && @token_set['access_token']
    @access_token = JWT.decode @token_set['access_token'], nil, false
  end
  if @token_set && @token_set['id_token']
    @id_token =JWT.decode @token_set['id_token'], nil, false
  end

  haml :home
end

# This endpoint is used to handle the redirect from the
# Xero OAuth 2.0 authorisation process
get '/callback' do
  puts "XERO CLIENT:::: #{xero_client.inspect}"
  puts "XERO PARAMS:::: #{params.inspect}"
  @token_set = xero_client.get_token_set_from_callback(params)
  puts "XERO TOKEN:::: #{@token_set.inspect}"

  session[:token_set] = @token_set
  redirect to('/')
end

# This endpoint redirects the user to connect another
# Xero organisation.
get '/add-connection' do
  @auth_url = xero_client.authorization_url
  redirect to(@auth_url)
end

# This endpoint is here specifically to refresh the token at will.
# In a production setting this will most likely happen as part of a background job,
# not something the user has to click.
get '/refresh-token' do
  @token_set = xero_client.refresh_token_set(session[:token_set])
  session[:token_set] = @token_set

  # Set some variables for the 'refresh_token.haml' view.
  if @token_set && @token_set['access_token']
    @access_token = JWT.decode @token_set['access_token'], nil, false
  end
  if @token_set && @token_set['id_token']
    @id_token =JWT.decode @token_set['id_token'], nil, false
  end

  haml :refresh_token
end

# This endpoint allows the user to explicitly disconnect the app from
# their Xero organisation.
# Note: At this point in time, it assumes that you have a single organisation
# connected.
get '/disconnect' do
  xero_client.set_token_set(session[:token_set])
  # This will disconnect the first organisation that appears in the xero_client.connections array.
  xero_client.disconnect(xero_client.connections[0]['id'])
  @connections = xero_client.connections
  haml :disconnect
end

# This endpoint will list the Xero organisations that your app is authorized to access.
get '/connections' do
  xero_client.set_token_set(session[:token_set])
  @connections = xero_client.connections
  haml :connections
end

# This endpoint shows invoice data via the 'invoices.haml' view.
get '/invoices' do
  xero_client.set_token_set(session[:token_set])
  @invoices = xero_client.accounting_api.get_invoices(xero_client.connections[0]['tenantId']).invoices
  haml :invoices
end

# This endpoint returns the object of the first organisation that appears
# in the xero_client.connections array.
get '/organisation' do
  # xero_client.set_token_set(session[:token_set])
  # puts "TENANT ID::::::::: #{xero_client.connections[0]['tenantId']}"
  # begin
  #   @organisations = xero_client.accounting_api.get_organisations(xero_client.connections[0]['tenantId']).organisations
  # rescue StandardError => e
  #   puts "ERROR::::::: #{e.message}"
  #   puts "TRACE::::::: #{e.backtrace.inspect}"
  # end

  response = RestClient::Request.execute(
    method: :get,
    url: 'https://api.xero.com/api.xro/2.0/Organisation',
    payload: payload, headers: { 'Content-Type' => 'text/xml', 'Authorization' => "Bearer #{session[:token_set]}" })
  response = JSON.parse(response)
  puts "RESPONSE::::#{response.inspect}"
  @organisations = []

  haml :organisations
end

get '/reports' do
  xero_client.set_token_set(session[:token_set])
  @reports = xero_client.accounting_api.get_report_ba_sor_gst_list(xero_client.connections[0]['tenantId']).reports
  haml :reports
end

get '/transactions' do
  xero_client.set_token_set(session[:token_set])

  xero_tenant_id = xero_client.connections[0]['tenantId']
  if_modified_since = "2020-02-06T12:17:43.202-08:00"
  where = 'Status==#{XeroRuby::Accounting::BankTransaction::AUTHORISED}'
  order = 'Type ASC'
  page = 1
  unitdp = 4

  @transactions = xero_client.accounting_api.get_bank_transactions(xero_tenant_id, if_modified_since, where, order, page, unitdp)
  haml :transactions
end
