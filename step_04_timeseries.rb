#!/usr/bin/env ruby
require 'date'
require 'net/http'
require 'json'
require 'uri'
require './lib/utils.rb'
require 'Date'

# Config
METADATA_OUTPUT      = File.dirname(__FILE__) + "/output/metadata-output.txt"
TIMESERIES_OUTPUT    = File.dirname(__FILE__) + "/output/timeseries-output.txt"

metadata = Utils::load_metadata()
first_day = metadata.sort_by { |row| row[:date] }.first[:date]
last_day = metadata.sort_by { |row| row[:date] }.last[:date]

time_series = []

first_day.upto(last_day) do |date|
  watches_on_date = metadata.select {|row| row[:date] == date }
  minutes_watched = watches_on_date.map {|row| row[:runtime].to_i}.reduce(0, :+)
  series_watch_count = watches_on_date.select {|row| row[:type] == "series" }.size
  movies_watch_count = watches_on_date.select {|row| row[:type] == "movie" }.size

  time_series.push({
    :date => date.to_s,
    :minutes_watched => minutes_watched,
    :hours_watched => (minutes_watched.to_f / 60.0).round(2),
    :total_watches => watches_on_date.size,
    :series_watch_count => series_watch_count,
    :movies_watch_count => movies_watch_count
  })
end

puts time_series

# Rewrite the file including the new meta informatio
File.open(TIMESERIES_OUTPUT, "w") do |file|
  file.puts "Date;Minutes Watched;Hours Watched;Total Watch Count;Series Watch Count;Movie Watch Count"
  time_series.each do |row|
   file.puts "#{row[:date]};#{row[:minutes_watched]};#{row[:hours_watched]};#{row[:total_watches]};#{row[:series_watch_count]};#{row[:movies_watch_count]};"
  end
end
