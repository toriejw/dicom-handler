require 'rails_helper'

RSpec.describe 'Api::V1::Images', type: :request do
  describe 'POST /api/v1/images' do
    let(:test_dicom_path) { Rails.root.join('spec/fixtures/images/mri/SE000008/IM000001.dcm') }

    context 'with valid DICOM file' do
      let(:file) { Rack::Test::UploadedFile.new(test_dicom_path, 'application/dicom') }

      it 'uploads the file successfully' do
        files_before = Dir.glob(Rails.root.join('public/uploads/*'))
        dcm_files_before = files_before.select { |f| f.end_with?('.dcm') }
        png_files_before = files_before.select { |f| f.end_with?('.png') }

        post '/api/v1/images', params: { image: file }

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Success')

        files_after = Dir.glob(Rails.root.join('public/uploads/*'))
        dcm_files_after = files_after.select { |f| f.end_with?('.dcm') }
        png_files_after = files_after.select { |f| f.end_with?('.png') }

        # Verify the API call created exactly 1 DCM and 1 PNG file
        expect(dcm_files_after.count - dcm_files_before.count).to eq(1)
        expect(png_files_after.count - png_files_before.count).to eq(1)
      end

      context 'when query params are provided' do
        let(:expected_attributes) {
          {
            '0002,0013' => 'IMS4-6-1-P95',
            '0018,0050' => '3.0',
            '0040,0244' => '20131217'
          }
        }

        it 'returns the requested tag values' do
          post '/api/v1/images?tags[]=0002,0013&tags[]=0018,0050&tags[]=0040,0244', params: { image: file }

          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)['attributes']).to eq(expected_attributes)
        end
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