"""
config:
  width: px
  height: px
  padding: {top, right, bottom, left}
  data:
    * points:
        * x [0 ... 1]
          y [0 ... 1]
          labelX
          labelY
"""
class ig.LineChart
  (@parentElement, @config) ->
    {@data, @padding} = @config
    @prepareData!
    @prepareScales!
    @initElements!
    @draw!

  draw: ->
    @drawAxes!
    @drawLines!
    @drawInteraction!

  drawInteraction: ->
    @drawVoronoi!
    @drawInteractionLines!

  drawVoronoi: ->
    points = []
    for line in @data
      for point in line.points
        points.push point
    generator = d3.geom.voronoi!
      ..x ~> @scaleX it.x
      ..y ~> @scaleY it.y
      ..clipExtent [[0, 0], [@width, @height]]
    voronois = generator points
      .filter -> it

    g = @interactionG.append \g
      ..attr \class \voronoi
    paths = g.selectAll \path .data voronois .enter!append \path
      ..attr \d -> "M#{it.join "L"}Z"
      ..on \mouseover ~> @highlight it.point
      ..on \touchstart ~> @highlight it.point
      ..on \mouseout ~> @downlight it.point
    @interactionVoronoi = {g, paths, generator}

  drawInteractionLines: ->
    g = @highlightLinesG.append \g
      ..attr \class \lines
    x = g.append \line
      ..attr \class \x
    y = g.append \line
      ..attr \class \y
    @interactionLines = {g, x, y}

  highlight: (point) ->
    x = @scaleX point.x
    y = @scaleY point.y
    @updateInteractionLines x, y
    @svg.classed \active yes
    for element in [@lines.points, @axisX.tickG, @axisY.tickG]
      element.classed \active -> it is point

  downlight: ->
    @svg.classed \active no
    @svg.selectAll \.active .classed \active no

  updateInteractionLines: (x, y) ->
    @interactionLines.g
      .attr \transform "translate(#{x},#{y})"
    @interactionLines.x
      .attr \x1 -1 * x
    @interactionLines.y
      .attr \y2 @height - y

  drawLines: ->
    g = @drawing.append \g
      ..attr \class \lines
    svgLine = @getSvgLine!
    lineG = g.selectAll \g .data @data .enter!append \g
      ..attr \class \line
    line = lineG.append \path
      ..attr \d ~> svgLine it.points
    pointsG = lineG.append \g
      ..attr \class \points
    points = pointsG.selectAll \circle .data (.points) .enter!append \circle
      ..attr \transform ~> "translate(#{@scaleX it.x},#{@scaleY it.y})"
      ..attr \r 4

    @lines = {g, lineG, line, pointsG, points}

  getSvgLine: ->
    d3.svg.line!
      ..x ~> @scaleX it.x
      ..y ~> @scaleY it.y

  drawAxes: ->
    @drawXAxis!
    @drawYAxis!

  drawXAxis: ->
    g = @axesG.append \g
      ..attr \class "axis x"
      ..attr \transform "translate(#{@padding.left}, #{@padding.top + @height})"
    domainLine = g.append \line
      ..attr \class \domain
      ..attr \x1 @width
    extentsG = g.append \g
      ..attr \class \extents
    extentG = extentsG.selectAll \g.extent .data @data .enter!append \g
      ..attr \class \extent
    extentLine = extentG.append \line
      ..attr \class \extent
      ..attr \x1 ~> @scaleX it.extent.x.0
      ..attr \x2 ~> @scaleX it.extent.x.1
    ticksG = extentG.append \g
      ..attr \class \ticks
    tickG = ticksG.selectAll \g.tick .data (.points) .enter!append \g
      ..attr \class \tick
      ..attr \transform ~> "translate(#{@scaleX it.x}, 0)"
    tickLines = tickG.append \line
      ..attr \y1 3
      ..attr \class \tick
    tickTexts = tickG.append \text
      ..attr \text-anchor \middle
      ..attr \dy 20
      ..text (.labelX)

    @axisX = {g, domainLine, extentsG, extentG, extentLine, ticksG, tickG, tickLines, tickTexts}

  drawYAxis: ->
    g = @axesG.append \g
      ..attr \class "axis y"
      ..attr \transform "translate(#{@padding.left}, #{@padding.top})"
    domainLine = g.append \line
      ..attr \class \domain
      ..attr \y1 @height
    extentsG = g.append \g
      ..attr \class \extents
    extentG = extentsG.selectAll \g.extent .data @data .enter!append \g
      ..attr \class \extent
    extentLine = extentG.append \line
      ..attr \class \extent
      ..attr \y1 ~> @scaleY it.extent.y.0
      ..attr \y2 ~> @scaleY it.extent.y.1
    ticksG = extentG.append \g
      ..attr \class \ticks
    linePointsSortedByY = (line) ->
      line.points
        .slice!
        .sort (a, b) -> a.y - b.y
    tickG = ticksG.selectAll \g.tick .data linePointsSortedByY .enter!append \g
      ..attr \class \tick
      ..attr \transform ~> "translate(0, #{@scaleY it.y})"
    tickLines = tickG.append \line
      ..attr \x1 -3
      ..attr \class \tick
    tickTexts = tickG.append \text
      ..attr \text-anchor \end
      ..attr \dy 4
      ..attr \dx -10
      ..text (.labelY)

    @axisY = {g, domainLine, extentsG, extentG, extentLine, ticksG, tickG, tickLines, tickTexts}

  prepareData: ->
    for line in @data
      line.extent =
        x: d3.extent line.points.map (.x)
        y: d3.extent line.points.map (.y)
      for point in line.points
        point.line = line

  prepareScales: ->
    {width:@fullWidth, height:@fullHeight} = @config
    @width = @fullWidth - @padding.left - @padding.right
    @height = @fullHeight - @padding.top - @padding.bottom
    @scaleX = d3.scale.linear!
      ..range [0 @width]
    @scaleY = d3.scale.linear!
      ..range [0 @height]

  initElements: ->
    @element = @parentElement.append \div
    @width = @fullWidth - @padding.left - @padding.right
    @height = @fullHeight - @padding.top - @padding.bottom
    @svg = @element.append \svg
      ..attr {width:@fullWidth, height:@fullHeight}
    @axesG = @svg.append \g
      ..attr \class \axes
    @highlightLinesG = @svg.append \g
      ..attr \class \highlight-lines
      ..attr \transform "translate(#{@padding.left},#{@padding.top})"
    @drawing = @svg.append \g
      ..attr \class \drawing
      ..attr \transform "translate(#{@padding.left},#{@padding.top})"
    @interactionG = @svg.append \g
      ..attr \transform "translate(#{@padding.left},#{@padding.top})"
      ..attr \class \interaction
