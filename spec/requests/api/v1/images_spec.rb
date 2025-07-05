require 'rails_helper'

RSpec.describe 'Api::V1::Images', type: :request do
  describe 'POST /api/v1/images' do
    let(:test_dicom_path) { Rails.root.join('spec/fixtures/images/mri/SE000008/IM000001.dcm') }

    context 'with valid DICOM file' do
      let(:file) { Rack::Test::UploadedFile.new(test_dicom_path, 'application/dicom') }

      it 'uploads the file successfully' do
        expect {
          post '/api/v1/images', params: { image: file }
        }.to change { Dir.glob(Rails.root.join('public/uploads/*')).count }.by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Success')
      end
    end

    context 'with no file' do
      it 'returns an error' do
        post '/api/v1/images', params: {}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('No image provided')
      end
    end

    context 'with invalid file type' do
      let(:txt_file_path) { Rails.root.join('spec/fixtures/file.txt') }
      let(:invalid_file) { Rack::Test::UploadedFile.new(txt_file_path, 'text/plain') }

      it 'returns an error' do
        post '/api/v1/images', params: { image: invalid_file }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid file type. Only DICOM files are accepted.')
      end
    end
  end
end