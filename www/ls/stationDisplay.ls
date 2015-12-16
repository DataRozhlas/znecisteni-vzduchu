container = d3.select ig.containers.base .append \div
  ..attr \id \detail

top = container.append \div

header = top.append \h2
particleNotes = {}
  ..no2 = top.append \p
    ..html "Zobrazeny hodinové průměry koncentrace NO<sub>2</sub>. Zobrazit koncentrace "
    ..append \a
      ..attr \href \#
      ..html "polétavého prachu PM10"
      ..on \click ->
        particleNotes[currentParticle].classed \active no
        ig.displayStation null, "pm10"
        particleNotes[currentParticle].classed \active yes
    ..append \span .html "."
  ..pm10 = top.append \p
    ..html "Zobrazeny hodinové průměry koncentrace PM10. Zobrazit koncentrace "
    ..append \a
      ..attr \href \#
      ..html "NO<sub>2</sub>"
      ..on \click ->
        particleNotes[currentParticle].classed \active no
        ig.displayStation null, "no2"
        particleNotes[currentParticle].classed \active yes
    ..append \span .html "."


width = 784
height = 200
canvas = container.append \canvas
  ..attr \width "#{width}px"
  ..attr \height "#{height}px"
ctx = canvas.node!getContext \2d
ctx.translate 0.5 0.5
yScale = {}
yScale.no2 = d3.scale.linear!
  ..range [0 height]
  ..domain [166 0]
yScale.pm10 = d3.scale.linear!
  ..range [0 height]
  ..domain [200 0]
data = {}
for particle in <[pm10 no2]>
  data[particle] = d3.tsv.parse ig.data[particle], (row) ->
    for field, value of row
      row[field] = parseFloat value
    row

colors = ['#d73027','#fc8d59','#fee08b','#d9ef8b','#91cf60','#1a9850'].reverse!
colorScale = {}
  ..no2 = d3.scale.threshold!
    ..domain [25 50 100 200 400]
    ..range colors
  ..pm10 = d3.scale.threshold!
    ..domain [15 30 50 70 150]
    ..range colors

humanLevels =
  "velmi dobrá"
  "dobrá"
  "uspokojivá"
  "vyhovující"
  "špatná"
  "velmi špatná"

currentParticle = "no2"
particleNotes[currentParticle].classed \active yes
currentStation = null
legend = container.append \ul
  ..attr \id \legend

legend.selectAll \li .data colorScale[currentParticle].domain! .enter!append \li
  ..append \div
    ..attr \class \color
    ..style \background-color (d, i) -> colors[i]
  ..append \span
    ..attr \class \label
days = []
lastDay = null
for {d, m}, index in data.no2
  continue if d is 9 and m is 11
  continue if d is 18 and m is 11
  continue if d is 22 and m is 11
  continue if d is 26 and m is 11
  if lastDay != d
    days.push {d, m, index}
    lastDay = d
container.append \ul
  ..attr \class \x-axis
  ..selectAll \li .data days .enter!append \li
    ..html ->
      o = it.d
      o += "."
      if it.d == 10 and it.m == 11
        o += "<br>listopadu"
      if it.d == 1 and it.m == 12
        o += "<br>prosince"
      o
    ..style \left -> "#{it.index}px"
overlay = container.append \div
  ..attr \id \overlay
  ..append \h2 .html "Kliknutím na měřící stanici si zobrazte historii jejích měření"
iterations = 0
offset = null
computeOffset = ->
  offset := ig.utils.offset canvas.node!
computeOffset!
setInterval computeOffset, 1000
tooltip = new ig.GraphTip container
toDouble = -> if it < 9 then "0#it" else it
canvas
  ..on \mouseout tooltip~hide
  ..on \mousemove ->
      pointedY = y = (d3.event.pageY - offset.top)
      pointedX = d3.event.pageX - offset.left
      row = data[currentParticle][pointedX]
      return unless row
      value = row[currentStation.name]
      message = if isNaN value
        "Neměřeno"
      else
        "#{value} µg #{currentParticle.toUpperCase!}/m³"
      tooltip.display do
        pointedX + 10
        19 + yScale[currentParticle] value
        "#{row.d}. #{row.m}. #{toDouble row.h}:#{toDouble row.i}<br>" + message

ig.displayStation = (station, particle) ->
  overlay.remove! if iterations is 1
  iterations++
  currentParticle := particle if particle
  currentStation  := station if station
  header.html currentStation.name
  ctx.clearRect 0, 0, width, height
  for row, index in data[currentParticle]
    value = row[currentStation.name]
    ctx
      ..beginPath!
      ..strokeStyle = colorScale[currentParticle] value
      ..moveTo index, height
      ..lineTo index, yScale[currentParticle] value
      ..stroke!
  legend.selectAll \li .data colorScale[currentParticle].domain!
    ..style \top -> "#{yScale[currentParticle] it}px"
    ..select \span.label
      ..html (d, i) -> "#{humanLevels[i]} (#d µg/m³)"
