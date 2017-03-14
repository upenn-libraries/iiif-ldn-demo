require 'json'

class Notifications

  attr_reader :json_file
  attr_reader :all

  def initialize json_file
    @json_file = json_file
  end

  def all
    JSON.parse(open(json_file).read)
  end

  def add_notification data
    # update a counter using write lock
    # don't use "w" because it truncates the file before lock.
    File.open json_file, File::RDWR|File::CREAT, 0644  { |f|
      f.flock(File::LOCK_EX)
      notes = JSON.parse f.read
      f.rewind
      f.truncate f.pos
      notes << data
      f.write JSON.dump(notes)
      f.flush
    }
  end
end