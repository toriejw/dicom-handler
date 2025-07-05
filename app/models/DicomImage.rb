require 'dicom'
include DICOM

class DicomImage
  attr_accessor :dcm, :png_file_path

  def convert_to_png
    @png_file_path = generate_png_file_path()
    dcm.image.normalize.write(@png_file_path)
  end

  def dcm
    # Given how large these files can be, prevent re-reading the file if it's already been read
    @dcm ||= DObject.read(@dcm_file_path.to_s)
  end

  def read_tags(tags)
    return [] if !tags

    tags.to_h { |tag| [tag, dcm.value(tag)] }
  end

  def upload(file)
    @dcm_file_path = generate_dcm_file_path()

    # Rewind the file in case it was already read - this ensures file is stored uncorrupted
    file.rewind if file.respond_to?(:rewind)

    File.open(@dcm_file_path, 'wb') do |dest_file|
      IO.copy_stream(file, dest_file)
    end
  end

  private

  def generate_dcm_file_path
    file_name = "#{unique_file_name}.dcm"
    Rails.root.join('public', 'uploads', file_name)
  end

  def generate_png_file_path
    file_name = "#{unique_file_name}.png"
    Rails.root.join('public', 'uploads', file_name)
  end

  def unique_file_name
    # Generate a unique file name to prevent collisions and limit chances of scanning attack attempts
    @unique_file_name ||= "#{SecureRandom.uuid}_#{Time.now.to_i}"
  end
end
