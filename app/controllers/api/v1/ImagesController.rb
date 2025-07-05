class Api::V1::ImagesController < ApplicationController
  # This is a security feature enabled by default in Rails
  # for CSRF protection. Because we are not using auth, we can skip it.
  skip_before_action :verify_authenticity_token

  def create
    begin
      validate_file()
      upload_image()
      convert_to_png()

      render json: {
        message: 'Success',
        attributes: @image.read_tags(image_params[:tags]),
      }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def convert_to_png
    @image.convert_to_png()
  end

  def image_params
    params.permit(:image, tags: [])
  end

  def upload_image
    @image = DicomImage.new
    @image.upload(params[:image])
  end

  def validate_file
    # Normally in Rails we'd use strong parameters, but strong params convert files to strings,
    # so in this case we need to add our own validation
    unless params[:image].present?
      raise 'No image provided'
    end

    unless valid_file_type?(params[:image])
      raise 'Invalid file type. Only DICOM files are accepted.'
    end
  end

  def valid_file_type?(file)
    return false unless file.respond_to?(:content_type) && file.respond_to?(:original_filename)

    allowed_types = [ 'application/dicom' ]
    allowed_extensions = ['.dcm']

    allowed_types.include?(file.content_type) ||
      allowed_extensions.any? { |extension| file.original_filename.downcase.end_with?(extension) }
  end
end