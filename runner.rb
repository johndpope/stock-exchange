#!/usr/bin/env ruby

require './point'
require './csv_parser'
require './analiser'
require './chart'
require 'pry'

START_POINT = 0
END_POINT = 500

filename = 'sx5e_index.csv'
points = CsvParser.parse(filename)

points = points[START_POINT..END_POINT]

analiser = Analiser.new(points)
analiser.run

#Chart.new.line.labels(['a','b','c']).data('Ian',[1,5,20]).create('bob.png')
chart = Chart.new(type: :line, size: 1000)
#chart.labels(points.map { |p| p.date.to_s })
#chart.labels((1..points.length).map(&:to_s))

  # px_open
  # px_last
  # px_low
  # rsi_14d
%i{
  mov_avg_20d
  mov_avg_50d
  px_high
}.each do |p|
  chart.data(p, points.map(&p))
end
chart.data('up', points.map { |p| p.uptrend? ? p.mov_avg_20d : nil })
analiser.best_trends.each_with_index do |t,i|
  chart.data("trend-#{i}", t)
end

chart.write('bob.png')
`open bob.png`
