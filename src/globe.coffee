###
dat.globe Javascript WebGL Globe Toolkit
http://dataarts.github.com/dat.globe

Copyright 2011 Data Arts Team, Google Creative Lab

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
###
DAT = DAT or {}
DAT.Globe = (container, colorFn) ->
  init = ->
    container.style.color = "#fff"
    container.style.font = "13px/20px Arial, sans-serif"
    shader = undefined
    uniforms = undefined
    material = undefined
    w = container.offsetWidth or window.innerWidth
    h = container.offsetHeight or window.innerHeight
    camera = new THREE.PerspectiveCamera(30, w / h, 1, 10000)
    camera.position.z = distance
    scene = new THREE.Scene()
    geometry = new THREE.SphereGeometry(200, 40, 30)
    shader = Shaders["earth"]
    uniforms = THREE.UniformsUtils.clone(shader.uniforms)
    uniforms["texture"].value = THREE.ImageUtils.loadTexture(imgDir + "world.jpg")
    material = new THREE.ShaderMaterial(
      uniforms: uniforms
      vertexShader: shader.vertexShader
      fragmentShader: shader.fragmentShader
    )
    mesh = new THREE.Mesh(geometry, material)
    mesh.rotation.y = Math.PI
    scene.add mesh
    shader = Shaders["atmosphere"]
    uniforms = THREE.UniformsUtils.clone(shader.uniforms)
    material = new THREE.ShaderMaterial(
      uniforms: uniforms
      vertexShader: shader.vertexShader
      fragmentShader: shader.fragmentShader
      side: THREE.BackSide
      blending: THREE.AdditiveBlending
      transparent: true
    )
    mesh = new THREE.Mesh(geometry, material)
    mesh.scale.set 1.1, 1.1, 1.1
    scene.add mesh
    geometry = new THREE.CubeGeometry(0.75, 0.75, 1)
    geometry.applyMatrix new THREE.Matrix4().makeTranslation(0, 0, -0.5)
    point = new THREE.Mesh(geometry)
    renderer = new THREE.WebGLRenderer(antialias: true)
    renderer.setSize w, h
    renderer.domElement.style.position = "absolute"
    container.appendChild renderer.domElement
    container.addEventListener "mousedown", onMouseDown, false
    container.addEventListener "mousewheel", onMouseWheel, false
    document.addEventListener "keydown", onDocumentKeyDown, false
    window.addEventListener "resize", onWindowResize, false
    container.addEventListener "mouseover", (->
      overRenderer = true
    ), false
    container.addEventListener "mouseout", (->
      overRenderer = false
    ), false
  # other option is 'legend'
  
  #        size = data[i + 2];
  createPoints = ->
    if @_baseGeometry isnt `undefined`
      if @is_animated is false
        @points = new THREE.Mesh(@_baseGeometry, new THREE.MeshBasicMaterial(
          color: 0xffffff
          vertexColors: THREE.FaceColors
          morphTargets: false
        ))
      else
        if @_baseGeometry.morphTargets.length < 8
          console.log "t l", @_baseGeometry.morphTargets.length
          padding = 8 - @_baseGeometry.morphTargets.length
          console.log "padding", padding
          i = 0

          while i <= padding
            console.log "padding", i
            @_baseGeometry.morphTargets.push
              name: "morphPadding" + i
              vertices: @_baseGeometry.vertices

            i++
        @points = new THREE.Mesh(@_baseGeometry, new THREE.MeshBasicMaterial(
          color: 0xffffff
          vertexColors: THREE.FaceColors
          morphTargets: true
        ))
      scene.add @points
  addPoint = (lat, lng, size, color, subgeo) ->
    phi = (90 - lat) * Math.PI / 180
    theta = (180 - lng) * Math.PI / 180
    point.position.x = 200 * Math.sin(phi) * Math.cos(theta)
    point.position.y = 200 * Math.cos(phi)
    point.position.z = 200 * Math.sin(phi) * Math.sin(theta)
    point.lookAt mesh.position
    point.scale.z = Math.max(size, 0.1) # avoid non-invertible matrix
    point.updateMatrix()
    i = 0

    while i < point.geometry.faces.length
      point.geometry.faces[i].color = color
      i++
    THREE.GeometryUtils.merge subgeo, point
  onMouseDown = (event) ->
    event.preventDefault()
    container.addEventListener "mousemove", onMouseMove, false
    container.addEventListener "mouseup", onMouseUp, false
    container.addEventListener "mouseout", onMouseOut, false
    mouseOnDown.x = -event.clientX
    mouseOnDown.y = event.clientY
    targetOnDown.x = target.x
    targetOnDown.y = target.y
    container.style.cursor = "move"
    
    #testing intersection code
    vector = new THREE.Vector3((event.clientX / window.innerWidth) * 2 - 1, -(event.clientY / window.innerHeight) * 2 + 1, 0.5)
    projector.unprojectVector vector, camera
    raycaster = new THREE.Raycaster(camera.position, vector.sub(camera.position).normalize())
    intersects = raycaster.intersectObjects(objects)
    if intersects.length > 0
      intersects[0].object.material.color.setHex Math.random() * 0xffffff
      particle = new THREE.Sprite(particleMaterial)
      particle.position = intersects[0].point
      particle.scale.x = particle.scale.y = 8
      scene.add particle
  onMouseMove = (event) ->
    mouse.x = -event.clientX
    mouse.y = event.clientY
    zoomDamp = distance / 1000
    target.x = targetOnDown.x + (mouse.x - mouseOnDown.x) * 0.005 * zoomDamp
    target.y = targetOnDown.y + (mouse.y - mouseOnDown.y) * 0.005 * zoomDamp
    target.y = (if target.y > PI_HALF then PI_HALF else target.y)
    target.y = (if target.y < -PI_HALF then -PI_HALF else target.y)
  onMouseUp = (event) ->
    container.removeEventListener "mousemove", onMouseMove, false
    container.removeEventListener "mouseup", onMouseUp, false
    container.removeEventListener "mouseout", onMouseOut, false
    container.style.cursor = "auto"
  onMouseOut = (event) ->
    container.removeEventListener "mousemove", onMouseMove, false
    container.removeEventListener "mouseup", onMouseUp, false
    container.removeEventListener "mouseout", onMouseOut, false
  onMouseWheel = (event) ->
    event.preventDefault()
    zoom event.wheelDeltaY * 0.3  if overRenderer
    false
  onDocumentKeyDown = (event) ->
    switch event.keyCode
      when 38
        zoom 100
        event.preventDefault()
      when 40
        zoom -100
        event.preventDefault()
  onWindowResize = (event) ->
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize window.innerWidth, window.innerHeight
  zoom = (delta) ->
    distanceTarget -= delta
    distanceTarget = (if distanceTarget > 1000 then 1000 else distanceTarget)
    distanceTarget = (if distanceTarget < 350 then 350 else distanceTarget)
  animate = ->
    requestAnimationFrame animate
    render()
  render = ->
    zoom curZoomSpeed
    rotation.x += (target.x - rotation.x) * 0.1
    rotation.y += (target.y - rotation.y) * 0.1
    distance += (distanceTarget - distance) * 0.3
    camera.position.x = distance * Math.sin(rotation.x) * Math.cos(rotation.y)
    camera.position.y = distance * Math.sin(rotation.y)
    camera.position.z = distance * Math.cos(rotation.x) * Math.cos(rotation.y)
    camera.lookAt mesh.position
    renderer.render scene, camera
  colorFn = colorFn or (x) ->
    c = new THREE.Color()
    c.setHSL (0.6 - (x * 0.5)), 1.0, 0.5
    c

  Shaders =
    earth:
      uniforms:
        texture:
          type: "t"
          value: null

      vertexShader: ["varying vec3 vNormal;", "varying vec2 vUv;", "void main() {", "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );", "vNormal = normalize( normalMatrix * normal );", "vUv = uv;", "}"].join("\n")
      fragmentShader: ["uniform sampler2D texture;", "varying vec3 vNormal;", "varying vec2 vUv;", "void main() {", "vec3 diffuse = texture2D( texture, vUv ).xyz;", "float intensity = 1.05 - dot( vNormal, vec3( 0.0, 0.0, 1.0 ) );", "vec3 atmosphere = vec3( 1.0, 1.0, 1.0 ) * pow( intensity, 3.0 );", "gl_FragColor = vec4( diffuse + atmosphere, 1.0 );", "}"].join("\n")

    atmosphere:
      uniforms: {}
      vertexShader: ["varying vec3 vNormal;", "void main() {", "vNormal = normalize( normalMatrix * normal );", "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );", "}"].join("\n")
      fragmentShader: ["varying vec3 vNormal;", "void main() {", "float intensity = pow( 0.8 - dot( vNormal, vec3( 0, 0, 1.0 ) ), 12.0 );", "gl_FragColor = vec4( 1.0, 1.0, 1.0, 1.0 ) * intensity;", "}"].join("\n")

  camera = undefined
  scene = undefined
  renderer = undefined
  w = undefined
  h = undefined
  mesh = undefined
  atmosphere = undefined
  point = undefined
  overRenderer = undefined
  imgDir = "/globe/"
  curZoomSpeed = 0
  zoomSpeed = 50
  mouse =
    x: 0
    y: 0

  mouseOnDown =
    x: 0
    y: 0

  rotation =
    x: 0
    y: 0

  target =
    x: Math.PI * 3 / 2
    y: Math.PI / 6.0

  targetOnDown =
    x: 0
    y: 0

  distance = 100000
  distanceTarget = 100000
  padding = 40
  PI_HALF = Math.PI / 2
  addData = (data, opts) ->
    lat = undefined
    lng = undefined
    size = undefined
    color = undefined
    i = undefined
    step = undefined
    colorFnWrapper = undefined
    opts.animated = opts.animated or false
    @is_animated = opts.animated
    opts.format = opts.format or "magnitude"
    console.log opts.format
    if opts.format is "magnitude"
      step = 3
      colorFnWrapper = (data, i) ->
        colorFn data[i + 2]
    else if opts.format is "legend"
      step = 4
      colorFnWrapper = (data, i) ->
        colorFn data[i + 3]
    else
      throw ("error: format not supported: " + opts.format)
    if opts.animated
      if @_baseGeometry is `undefined`
        @_baseGeometry = new THREE.Geometry()
        i = 0
        while i < data.length
          lat = data[i]
          lng = data[i + 1]
          color = colorFnWrapper(data, i)
          size = 0
          addPoint lat, lng, size, color, @_baseGeometry
          i += step
      if @_morphTargetId is `undefined`
        @_morphTargetId = 0
      else
        @_morphTargetId += 1
      opts.name = opts.name or "morphTarget" + @_morphTargetId
    subgeo = new THREE.Geometry()
    i = 0
    while i < data.length
      lat = data[i]
      lng = data[i + 1]
      color = colorFnWrapper(data, i)
      size = data[i + 2]
      size = size * 200
      addPoint lat, lng, size, color, subgeo
      i += step
    if opts.animated
      @_baseGeometry.morphTargets.push
        name: opts.name
        vertices: subgeo.vertices

    else
      @_baseGeometry = subgeo

  init()
  @animate = animate
  @__defineGetter__ "time", ->
    @_time or 0

  @__defineSetter__ "time", (t) ->
    validMorphs = []
    morphDict = @points.morphTargetDictionary
    for k of morphDict
      validMorphs.push morphDict[k]  if k.indexOf("morphPadding") < 0
    validMorphs.sort()
    l = validMorphs.length - 1
    scaledt = t * l + 1
    index = Math.floor(scaledt)
    i = 0
    while i < validMorphs.length
      @points.morphTargetInfluences[validMorphs[i]] = 0
      i++
    lastIndex = index - 1
    leftover = scaledt - index
    @points.morphTargetInfluences[lastIndex] = 1 - leftover  if lastIndex >= 0
    @points.morphTargetInfluences[index] = leftover
    @_time = t

  @addData = addData
  @createPoints = createPoints
  @renderer = renderer
  @scene = scene
  this

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
  xhr.open "GET", "/globe/population909500.json", true
  xhr.onreadystatechange = (e) ->
    if xhr.readyState is 4
      if xhr.status is 200
        data = JSON.parse(xhr.responseText)
        window.data = data
        i = 0
        while i < data.length
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
