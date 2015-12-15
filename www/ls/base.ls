L.Icon.Default.imagePath = "https://samizdat.cz/tools/leaflet/images/"
container = d3.select ig.containers.base
mapElement = container.append \div
  ..attr \id \map
map = L.map do
  * mapElement.node!
  * minZoom: 6,
    maxZoom: 14,
    zoom: 7,
    center: [49.78, 15.5]
    maxBounds: [[48.3,11.6], [51.3,19.1]]

baseLayer = L.tileLayer do
  * "https://samizdat.cz/tiles/ton_b1/{z}/{x}/{y}.png"
  * zIndex: 1
    opacity: 1
    attribution: 'mapová data &copy; přispěvatelé <a target="_blank" href="http://osm.org">OpenStreetMap</a>, obrazový podkres <a target="_blank" href="http://stamen.com">Stamen</a>, <a target="_blank" href="https://samizdat.cz">Samizdat</a>'

labelLayer = L.tileLayer do
  * "https://samizdat.cz/tiles/ton_l2/{z}/{x}/{y}.png"
  * zIndex: 3
    opacity: 0.75

map
  ..addLayer baseLayer
  ..addLayer labelLayer

stations = for name, coords of ig.data.coords
  latLng = L.latLng coords
  continue unless coords.0
  {name, coords, latLng}

stations.forEach (station) ->
  marker = L.marker station.latLng
    ..addTo map
    ..on \click ->
       displayStation station
