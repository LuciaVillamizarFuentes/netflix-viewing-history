#!/usr/bin/env ruby
require 'date'
require 'net/http'
require 'json'
require 'uri'

# Config
METADATA_OUTPUT      = File.dirname(__FILE__) + "/output/metadata-output.txt"
NETFLIX_RAW_OUTPUT   = File.dirname(__FILE__) + "/output/netflix-history-raw.txt"
SLEEP_TIME           = 2

def get_movie_meta(data)
  title = URI.escape(data[:title].split(":").first)
  uri = URI("http://www.omdbapi.com/?t=#{title}&y=&plot=short&r=json")
  response = Net::HTTP.get(uri)
  json = JSON.parse(response, :symbolize_names => true)

  if json[:Response] == "True"
    { :year         => json[:Year],
      :rated        => json[:Rated],
      :released     => json[:Released],
      :runtime      => json[:Runtime].chomp(" min"),
      :genre        => json[:Genre],
      :director     => json[:Director],
      :actors       => json[:Actors],
      :rating       => json[:imdbRating],
      :type         => json[:Type],
      :series_title => data[:title].split(":").first,
      :imdb_id      => json[:imdbID],
      :triage       => "false"
    }
  else
    { :triage       => "true" }
  end
end

def get_raw_data()
  raw_data = []
  File.open(NETFLIX_RAW_OUTPUT, "r").each_with_index do |line, index|
    next if index == 0
    row = line.chomp("\n")
    data = row.split(/\;/)
    raw_data.push({ :raw => row, :title => data[1],:url => "https://www.netflix.com#{data[2]}" })
  end
  raw_data
end

raw_data = get_raw_data()
series_data = []
existing_series = []

raw_data.each_with_index do |row, index|
  puts " "
  puts "-"
  puts " "

  potential_series_title = row[:title].split(":").first

  existing_series = series_data.find {|r| r[:series_title] == potential_series_title}

  if existing_series
    puts "Cache Hit: Use series data"
    # use its data and skip
    raw_data[index] = row.merge(existing_series)
    puts raw_data[index]
  else
    # it doesnt exist, go get it
    puts "Cache Miss: Get new data"
    scraped_data = get_movie_meta(row)

    # put the data into a series data array for future use
    series_data << scraped_data

    # inject the scraped data into the original raw data source
    raw_data[index] = row.merge(scraped_data)
    puts raw_data[index]

    sleep(SLEEP_TIME)
  end
end

# Rewrite the file including the new meta informatio
File.open(METADATA_OUTPUT, "w") do |file|
  file.puts "Date;Title;URL;Source;Type;Runtime;Year;Rated;Released;Genre;Director;Actors;Rating;IMDB ID;Series Title;Triage"
  raw_data.each do |row|
   file.puts "#{row[:raw]};Netflix;#{row[:type]};#{row[:runtime]};#{row[:year]};#{row[:rated]};#{row[:released]};#{row[:genre]};#{row[:director]};#{row[:actors]};#{row[:rating]};#{row[:imdb_id]};#{row[:series_title]};#{row[:triage]}"
  end
end
