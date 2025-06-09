# This file contains unit tests for the JsonWebToken module.
# These tests verify the encoding and decoding of JWTs work correctly
# in isolation, ensuring the token generation and validation logic is sound.

require 'rails_helper'
require 'json_web_token'

RSpec.describe JsonWebToken do
  # 'describe' block for the JsonWebToken module.
  # Since it's a module with class methods, we don't specify a 'type'.

  # Define a sample payload for testing.
  let(:user_id) { 123 }
  let(:payload) { { user_id: user_id } }
  # Get the Rails secret key base (used for signing/verifying JWTs).
  let(:secret_key) { Rails.application.secret_key_base }

  # --- Encoding Tests ---
  describe '.encode' do
    it 'encodes a token with the given payload' do
      token = JsonWebToken.encode(payload)
      # Expect the token to be a non-empty string.
      expect(token).to be_a(String)
      expect(token).not_to be_empty
    end

    it 'includes an expiration time in the payload' do
      exp_time = 1.hour.from_now
      token = JsonWebToken.encode(payload, exp_time)
      # Decode the token to check its payload.
      decoded_payload = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })[0]
      expect(decoded_payload['exp']).to eq(exp_time.to_i)
    end

    it 'uses a default expiration time if none is provided' do
      # Expect the token to have an expiration within a reasonable range (e.g., around 24 hours).
      token = JsonWebToken.encode(payload)
      decoded_payload = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })[0]
      expect(decoded_payload['exp']).to be_within(5.seconds).of(24.hours.from_now.to_i)
    end
  end

  # --- Decoding Tests ---
  describe '.decode' do
    context 'with a valid token' do
      let(:valid_token) { JsonWebToken.encode(payload) }

      it 'decodes a valid token and returns payload' do
        decoded = JsonWebToken.decode(valid_token)
        # Expect the decoded payload to be a HashWithIndifferentAccess
        expect(decoded).to be_a(HashWithIndifferentAccess)
        # Expect the user_id to match the original payload.
        expect(decoded[:user_id]).to eq(user_id)
      end
    end

    context 'with an invalid token' do
      it 'returns nil for a token with wrong signature' do
        # Create a token with a different secret key to simulate a wrong signature.
        bad_token = JWT.encode(payload, 'wrong_secret')
        expect(JsonWebToken.decode(bad_token)).to be_nil
      end

      it 'returns nil for an expired token' do
        # Encode a token that expires in the past.
        expired_token = JsonWebToken.encode(payload, -1.hour.from_now)
        expect(JsonWebToken.decode(expired_token)).to be_nil
      end

      it 'returns nil for a malformed token' do
        expect(JsonWebToken.decode('malformed.jwt.token')).to be_nil
      end
    end

    context 'with no token' do
      it 'returns nil when token is nil' do
        expect(JsonWebToken.decode(nil)).to be_nil
      end

      it 'returns nil when token is empty string' do
        expect(JsonWebToken.decode('')).to be_nil
      end
    end
  end
end
