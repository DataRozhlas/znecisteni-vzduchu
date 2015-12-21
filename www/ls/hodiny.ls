return unless window.location.hash == \#hodiny
toDouble = -> if it < 10 then "0#it" else it
yScale = d3.scale.linear!
  ..domain [68 0]
xScale = d3.scale.linear!
  ..domain [0 24]
stations = for name, coords of ig.data.coords
  continue unless coords.0
  hours = [0 to 23].map (hour) ->
    sum = 0
    count = 0
    values = []
    {hour, sum, count, values}
  for line in ig.data.parsed.no2
    if !isNaN line[name]
      hours[line.h]
        ..sum += line[name]
        ..count += 1
        ..values.push line[name]
  hours.push do
    hour: 24
    sum: hours[0].sum
    count: hours[0].count
    values: hours[0].values
  hours .= filter (.count)
  {name, hours}
stations .= filter (.hours.length)
container = d3.select ig.containers.base
graph = container.append \div
  ..attr \id \graph
header = container.append \h2
  ..attr \id \station-header
drawStation = (station) ->
  graph.html ''
  header.html "Hodinové průměry koncentrace NO<sub>2</sub> na stanici #{station.name}"
  points = for point in station.hours
    average = (point.sum / point.count)
    x      = xScale point.hour
    y      = yScale average
    labelX = "#{toDouble point.hour}"
    labelY = "#{ig.utils.formatNumber average, 1} µg/m³"
    {x, y, labelX, labelY}

  config =
    width: 1000
    height: 500
    padding: {top: 10, right: 30, bottom: 20, left: 85}
    data: [{points}]
  new ig.LineChart graph, config

drawStation stations.0
selector = container.append \select
  ..attr \id \station-selector
  ..selectAll \option .data stations .enter!append \option
    ..html (.name)
    ..attr \value (d, i) -> i
  ..on \change -> drawStation stations[(parseInt @value)]
