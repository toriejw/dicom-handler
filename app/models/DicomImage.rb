require 'dicom'
include DICOM

class DicomImage
  attr_accessor :file_path, :dcm

  def dcm
    @dcm || DObject.read(@file_path.to_s)
  end

  def read_tags(tags)
    return [] if !tags

    tags.to_h { |tag| [tag, dcm.value(tag)] }
  end

  def upload(file)
    @file_path = generate_file_path(file.original_filename)

    # Rewind the file in case it was already read - this ensures file is stored uncorrupted
    file.rewind if file.respond_to?(:rewind)

    File.open(@file_path, 'wb') do |dest_file|
      IO.copy_stream(file, dest_file)
    end
  end

  private

  def generate_file_path(original_filename)
    # Generate a unique file name to prevent collisions and limit chances of scanning attack attempts
    unique_name = "#{SecureRandom.uuid}_#{Time.now.to_i}_#{File.extname(original_filename)}"

    Rails.root.join('public', 'uploads', unique_name)
  end
end