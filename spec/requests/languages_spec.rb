require 'swagger_helper'

RSpec.describe 'Languages API', type: :request do

  let!(:english) { Language.find_or_create_by!(name: "English") }
  let!(:german) { Language.find_or_create_by!(name: "German") }
  let!(:spanish) { Language.find_or_create_by!(name: "Spanish") }

  path '/languages' do
    get 'Retrieves all languages' do
      tags 'Languages'
      produces 'application/json'

      response '200', 'list of languages retrieved successfully' do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer, description: 'Unique identifier of the language' },
                   name: { type: :string, description: 'Name of the language (e.g., "English")' }
                 },
                 required: %w[id name]
               },
               example: [
                 { id: 1, name: 'English' },
                 { id: 2, name: 'German' },
                 { id: 3, name: 'Spanish' }
               ]

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response).to be_an(Array)
          # Expect at least the 3 languages we seeded via `let!`
          expect(json_response.length).to be >= 3
          expect(json_response.first).to have_key('id')
          expect(json_response.first).to have_key('name')
        end
      end
    end
  end
end