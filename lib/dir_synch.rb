#!/usr/bin/env ruby

require 'flickraw'
require 'find'
require 'yaml'
require 'pp'

DIR                 = '/media/jonas/16E3-135F/bilder'
ALBUM_NAME          = 'Disk Sync'
API_KEY             = 'e257619314df288ffcbe2dcf7531bd2f'
SHARED_SECRET       = '2a220c095401b571'
ACCEPTED_EXTENSIONS = 'jpg|mov|gif|png|bmp|3gp'

# Handles synching of the files in a directory tree to Flickr.
class DirSynch
  def initialize
    FlickRaw.api_key = API_KEY
    FlickRaw.shared_secret = SHARED_SECRET
    rc_file = File.join(ENV['HOME'], '.SynchingFeeling.yml')
    if File.exist?(rc_file)
      data = YAML.load_file(rc_file)
      flickr.access_token = data['AccessToken']
      flickr.access_secret = data['AccessSecret']
    end
    @verbose = ARGV.include?('-v')
  end

  def run
    already_on_flickr = find_files_on_flickr
    file_list = find_files_on_disk
    @target_count = file_list.length
    @start_time = Time.now
    file_list.each_with_index do |path, ix|
      process_file(path, already_on_flickr, ix)
    end
  end

  private

  def find_files_on_flickr
    files = {}
    1.upto(1_000_000) do |page|
      begin
        get_photos(files, page)
      rescue FlickRaw::FailedResponse
        return files # Nothing on that page. We're done.
      end
    end
  end

  def get_photos(files, page)
    flickr.photosets.getPhotos(photoset_id: disk_sync_set.id,
                               page: page).photo.each do |photo|
      files[photo.title] = photo.id
    end
  end

  def find_files_on_disk
    file_list = Find.find(DIR).select { |path| File.file?(path) }.map do |path|
      if path !~ /\.(#{ACCEPTED_EXTENSIONS})$/i
        puts "Can not be uploaded: #{path}" if @verbose
      else
        path
      end
    end
    file_list.compact
  end

  def process_file(path, already_on_flickr, ix)
    title = path[(DIR.length + 1)..-1]
    photo_id = already_on_flickr[title]
    if photo_id
      if up_to_date?(photo_id, path)
        puts "Up-to-date on flickr: #{title}" if @verbose
      else
        try_to('replace', "Replacing #{path}") do
          flickr.replace_photo(path, photo_id: photo_id)
        end
      end
    else
      upload_to_set(path, title)
    end
    print_eta(ix + 1)
  end

  def up_to_date?(photo_id, path)
    date_uploaded = flickr.photos.getInfo(photo_id: photo_id).dateuploaded.to_i
    Time.at(date_uploaded) >= File.mtime(path)
  end

  def upload_to_set(path, title)
    photo_id = try_to('upload', "Uploading #{path}") do
      flickr.upload_photo(path, title: title, tags: 'disksync', is_public: 0)
    end
    return unless photo_id

    try_to('add to album') do
      flickr.photosets.addPhoto(photoset_id: disk_sync_set.id,
                                photo_id: photo_id)
    end
  end

  def try_to(task, msg = nil)
    puts msg if msg
    begin
      yield
    rescue JSON::ParserError, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EPIPE,
           EOFError, Timeout::Error => e
      puts "Failed to #{task} (#{e.class}) - retrying"
      retry
    rescue FlickRaw::FailedResponse => e
      puts "#{e}"
    end
  end

  def disk_sync_set
    @disk_sync_set ||=
      flickr.photosets.getList.find { |set| set.title == ALBUM_NAME }
  end

  def print_eta(file_count)
    elapsed_time = Time.now - @start_time
    time_per_file = elapsed_time / file_count
    remaining_files = @target_count - file_count
    remaining_time = remaining_files * time_per_file
    print "\r" + ' ' * 80
    print "\r#{duration(remaining_time)} remaining to check " \
          "#{remaining_files} files"
  end

  def duration(secs)
    secs  = secs.to_int
    mins  = secs / 60
    hours = mins / 60
    if hours > 0
      "#{hours} h #{mins % 60} min"
    elsif mins > 0
      "#{mins} min #{secs % 60} s"
    elsif secs >= 0
      "#{secs} s"
    end
  end
end

DirSynch.new.run if $PROGRAM_NAME == __FILE__
