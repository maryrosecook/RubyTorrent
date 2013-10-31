require 'fileutils'

class FileHandler
  include FileUtils
  
  def initialize(metainfo, byte_array)
    @metainfo = metainfo
    @byte_array = byte_array
    @temp_name = "temp/" + ('a'..'z').to_a.shuffle.take(10).join
    @file = init_file
  end
  
  def init_file
    make_dir("temp") unless File.directory?("temp")
    File.open(@temp_name, "w+")
    File.open(@temp_name, "r+")
  end
  
  def process_block(block)
    write_block(block)
    record_block(block)
    finish if @byte_array.complete?
  end
  
  def write_block(block)
    puts block.end_byte
    @file.seek(block.start_byte)
    @file.write(block.data)
  end
  
  def record_block(block)
    @byte_array.have_all(block.start_byte, block.end_byte)
  end
  
  def finish
    puts "finishing"
    @file.close
    if @metainfo.is_multi_file?
      split_files
      remove_temp_file
    else
      move_file
    end
  end
  
  def split_files
    dir = "downloads/" + @metainfo.folder
    make_dir(dir) unless File.directory?(dir)
    File.open(@temp_name, "r") do |temp_file|
      @metainfo.files.each do |file_info|
        File.open(dir + "/" + file_info[:name], "w") do |out_file|
          out_file.write(temp_file.read(file_info[:length]))
        end
      end
    end
  end
  
  def move_file
    make_dir("downloads") unless File.directory?("downloads")
    FileUtils.mv(@temp_name, "downloads/" + @metainfo.files[0][:name])
  end
  
  def make_dir(dir)
    Dir.mkdir(dir)
  end
  
  def remove_temp_file
    File.delete(@temp_name)
  end
end
    