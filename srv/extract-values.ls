require! fs
dir = "#__dirname/../data/scraped/"
files = fs.readdirSync dir
# files.length = 1
out = []
stations = <[d m y h i]>
stationCoords = {}
lastHour = null
compontentCode = "PM10"
for file in files
  data = JSON.parse fs.readFileSync "#dir/#file"
  # [region] = data.States.0.Regions
  # [_, station] = region.Stations
  dateString = data.Actualized
    .replace " SEČ" ""
  [d, m, y, h, i] = dateString.split /[^0-9]/ .map (parseInt _, 10)
  date = new Date!
    ..setTime 0
    ..setDate d
    ..setMonth m - 1
    ..setFullYear y
    ..setHours h
    ..setMinutes i
  hour = date.getHours!
  continue if hour is lastHour
  lastHour = hour
  line = [d, m, y, h, i]
  for region in data.States.0.Regions
    for station in region.Stations
      # time = date.getTime!
      # d = new Date date.replace " SEČ" ""
      continue unless station.Components
      index = stations.indexOf station.Name
      if index == -1
        index = (stations.push station.Name) - 1
        # stationCoords[station.Name] = [station.Lat, station.Lon]
      for compontent in  station.Components
        if compontent.Code == compontentCode and compontent.Int == "1h" and compontent.Ix > 0
          # console.log compontent
          # out.push do
          #   [dateString, time, compontent.Val.replace '.' ','].join "\t"
            # [hour , compontent.Val.replace '.' ','].join "\t"
          line[index] = compontent.Val
          break
  out.push line.join "\t"
out.unshift stations.join "\t"
fs.writeFileSync "#__dirname/../data/#{compontentCode}.tsv", out.join "\n"

# fs.writeFileSync "#__dirname/../data/coords.json", JSON.stringify stationCoords
