# frozen_string_literal: true

require_relative '../spec_helper'
require 'webmock/minitest'

describe 'Test Authentication Routes' do
  include Rack::Test::Methods

  before do
    @req_header = { 'CONTENT_TYPE' => 'application/json' }
    wipe_database
  end

  describe 'Account Authentication' do
    before do
      @account_data = DATA[:accounts][1]
      @account = No2Date::Account.create(@account_data)
    end

    it 'HAPPY: should authenticate valid credentials' do
      credentials = { username: @account_data['username'],
                      password: @account_data['password'] }
      post 'api/v1/auth/authenticate',
           SignedRequest.new(app.config).sign(credentials).to_json,
           @req_header

      auth_account = JSON.parse(last_response.body)['data']
      account = auth_account['attributes']['account']['attributes']
      _(last_response.status).must_equal 200
      _(account['username']).must_equal(@account_data['username'])
      _(account['email']).must_equal(@account_data['email'])
      _(account['id']).must_be_nil
    end

    it 'BAD: should not authenticate invalid password' do
      bad_credentials = { username: @account_data['username'],
                          password: 'fakepassword' }
      post 'api/v1/auth/authenticate',
           SignedRequest.new(app.config).sign(bad_credentials).to_json,
           @req_header

      result = JSON.parse(last_response.body)

      _(last_response.status).must_equal 401
      _(result['message']).wont_be_nil
      _(result['attributes']).must_be_nil
    end
  end

  describe 'SSO Authorization' do
    before do
      puts GOOG_ACCOUNT_RESPONSE[GOOD_GOOG_ACCESS_TOKEN]
      puts GOOG_ACCOUNT_RESPONSE[GOOD_GOOG_ACCESS_TOKEN].to_json

      WebMock.enable!
      WebMock.stub_request(:get, app.config.GOOGLE_ACCOUNT_URL)
             .to_return(body: GOOG_ACCOUNT_RESPONSE[GOOD_GOOG_ACCESS_TOKEN].to_json,
                        status: 200,
                        headers: { 'content-type' => 'application/json' })
    end

    after do
      WebMock.disable!
    end

    # it 'HAPPY AUTH SSO: should authenticate + authorize new valid SSO account' do
    #   goog_access_token = { access_token: GOOD_GOOG_ACCESS_TOKEN }

    #   post 'api/v1/auth/sso',
    #        SignedRequest.new(app.config).sign(goog_access_token).to_json,
    #        @req_header

    #   auth_account = JSON.parse(last_response.body)['data']
    #   account = auth_account['attributes']['account']['attributes']

    #   _(last_response.status).must_equal 200
    #   _(account['username']).must_equal(SSO_ACCOUNT['sso_username'])
    #   _(account['email']).must_equal(SSO_ACCOUNT['email'])
    #   _(account['id']).must_be_nil
    # end

    # it 'HAPPY AUTH SSO: should authorize existing SSO account' do
    #   No2Date::Account.create(
    #     username: SSO_ACCOUNT['sso_username'],
    #     email: SSO_ACCOUNT['email']
    #   )

    #   goog_access_token = { access_token: GOOD_GOOG_ACCESS_TOKEN }
    #   post 'api/v1/auth/sso',
    #        SignedRequest.new(app.config).sign(goog_access_token).to_json,
    #        @req_header

    #   auth_account = JSON.parse(last_response.body)['data']
    #   account = auth_account['attributes']['account']['attributes']

    #   _(last_response.status).must_equal 200
    #   _(account['username']).must_equal(SSO_ACCOUNT['sso_username'])
    #   _(account['email']).must_equal(SSO_ACCOUNT['email'])
    #   _(account['id']).must_be_nil
    # end
  end
end
