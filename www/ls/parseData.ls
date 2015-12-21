data = {}
for particle in <[pm10 no2]>
  data[particle] = d3.tsv.parse ig.data[particle], (row) ->
    for field, value of row
      row[field] = parseFloat value
    row
ig.data.parsed = data
