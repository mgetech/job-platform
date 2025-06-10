require 'rails_helper'

RSpec.describe Language, type: :model do
  # --- Associations ---
  describe 'associations' do
    it { should have_many(:job_languages) }
    it { should have_many(:jobs).through(:job_languages) }
  end

  # --- Validations ---
  describe 'validations' do
    it 'is valid with a unique name' do
      language = Language.new(name: "New Language")
      expect(language).to be_valid
    end

    it 'is invalid without a name' do
      language = Language.new(name: nil)
      expect(language).not_to be_valid
      expect(language.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with a duplicate name' do
      Language.create!(name: "Existing Language")
      language = Language.new(name: "Existing Language")
      expect(language).not_to be_valid
      expect(language.errors[:name]).to include("has already been taken")
    end
  end
end
