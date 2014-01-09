unless Detector.webgl
  Detector.addGetWebGLMessage()
else
  years = ["1990", "1995", "2000"]
  container = document.getElementById("container")
  globe = new DAT.Globe(container)
  console.log globe
  i = undefined
  tweens = []
  settime = (globe, t) ->
    ->
      new TWEEN.Tween(globe).to(
        time: t / years.length
      , 500).easing(TWEEN.Easing.Cubic.EaseOut).start()
      y = document.getElementById("year" + years[t])
      return  if y.getAttribute("class") is "year active"
      yy = document.getElementsByClassName("year")
      i = 0
      while i < yy.length
        yy[i].setAttribute "class", "year"
        i++
      y.setAttribute "class", "year active"

  i = 0

  while i < years.length
    y = document.getElementById("year" + years[i])
    y.addEventListener "mouseover", settime(globe, i), false
    i++
  xhr = undefined
  TWEEN.start()
  xhr = new XMLHttpRequest()
  xhr.open "GET", "data/population909501.json", true
  xhr.onreadystatechange = (e) ->
    if xhr.readyState is 4
      if xhr.status is 200
        data = [["1990", [0, 1, 2]], ["1995", [0, 1, 2]], ["2000", [0, 1, 2]]]
        console.log JSON.stringify(data[1][0])
        data1 = JSON.parse(xhr.responseText)
        countzero = 0
        i = 0
        while i < data1.hits.hits.length
          console.log "data 0", data[1][0]
          console.log "data 1", data1.hits.hits[i]._source.lat
          data[0][1][countzero] = data1.hits.hits[i]._source.lat
          data[1][1][countzero] = data1.hits.hits[i]._source.lat
          data[2][1][countzero++] = data1.hits.hits[i]._source.lat
          data[0][1][countzero] = data1.hits.hits[i]._source.lon
          data[1][1][countzero] = data1.hits.hits[i]._source.lon
          data[2][1][countzero++] = data1.hits.hits[i]._source.lon
          data[0][1][countzero] = data1.hits.hits[i]._source.duration * .000001
          data[1][1][countzero] = data1.hits.hits[i]._source.duration * .0000001
          data[2][1][countzero++] = data1.hits.hits[i]._source.duration * .00001
          i++
        window.data = data
        console.log JSON.stringify(data)
        i = 0
        while i < data.length
          console.log "data 1", data[i][1]
          globe.addData data[i][1],
            format: "magnitude"
            name: data[i][0]
            animated: true

          i++
        globe.createPoints()
        settime(globe, 0)()
        globe.animate()
        document.body.style.backgroundImage = "none" # remove loading

  xhr.send null
