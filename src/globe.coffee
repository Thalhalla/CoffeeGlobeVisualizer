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
  
  #target = { x: Math.PI*3/2, y: Math.PI / 6.0 },
  init = ->
    container.style.color = "#fff"
    container.style.font = "13px/20px Arial, sans-serif"
    shader = undefined
    uniforms = undefined
    material = undefined
    w = container.offsetWidth or window.innerWidth
    h = container.offsetHeight or window.innerHeight
    camera = new THREE.Camera(30, w / h, 1, 10000)
    camera.position.z = distance
    vector = new THREE.Vector3()
    scene = new THREE.Scene()
    sceneAtmosphere = new THREE.Scene()
    geometry = new THREE.Sphere(200, 40, 30)
    shader = Shaders["earth"]
    uniforms = THREE.UniformsUtils.clone(shader.uniforms)
    uniforms["texture"].texture = THREE.ImageUtils.loadTexture(imgDir + "world" + ".jpg")
    material = new THREE.MeshShaderMaterial(
      uniforms: uniforms
      vertexShader: shader.vertexShader
      fragmentShader: shader.fragmentShader
    )
    mesh = new THREE.Mesh(geometry, material)
    mesh.matrixAutoUpdate = false
    scene.addObject mesh
    shader = Shaders["atmosphere"]
    uniforms = THREE.UniformsUtils.clone(shader.uniforms)
    material = new THREE.MeshShaderMaterial(
      uniforms: uniforms
      vertexShader: shader.vertexShader
      fragmentShader: shader.fragmentShader
    )
    mesh = new THREE.Mesh(geometry, material)
    mesh.scale.x = mesh.scale.y = mesh.scale.z = 1.1
    mesh.flipSided = true
    mesh.matrixAutoUpdate = false
    mesh.updateMatrix()
    sceneAtmosphere.addObject mesh
    geometry = new THREE.Cube(0.06, 0.06, 1, 1, 1, 1, null, false,
      px: true
      nx: true
      py: true
      ny: true
      pz: false
      nz: true
    )
    i = 0

    while i < geometry.vertices.length
      vertex = geometry.vertices[i]
      vertex.position.z += 0.5
      i++
    point = new THREE.Mesh(geometry)
    renderer = new THREE.WebGLRenderer(antialias: true)
    renderer.autoClear = false
    renderer.setClearColorHex 0x000000, 0.0
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
  
  #size = size*200;
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
          name: "points"
        ))
      scene.addObject @points
  addPoint = (lat, lng, size, color, subgeo) ->
    phi = (90 - lat) * Math.PI / 180
    theta = (180 - lng) * Math.PI / 180
    point.position.x = 200 * Math.sin(phi) * Math.cos(theta)
    point.position.y = 200 * Math.cos(phi)
    point.position.z = 200 * Math.sin(phi) * Math.sin(theta)
    point.lookAt mesh.position
    point.scale.z = -size
    point.updateMatrix()
    i = undefined
    i = 0
    while i < point.geometry.faces.length
      point.geometry.faces[i].color = color
      i++
    GeometryUtils.merge subgeo, point
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
    console.log "resize"
    camera.aspect = window.innerWidth / window.innerHeight
    camera.updateProjectionMatrix()
    renderer.setSize window.innerWidth, window.innerHeight
  zoom = (delta) ->
    distanceTarget -= delta
    distanceTarget = (if distanceTarget > 1000 then 1000 else distanceTarget)
    distanceTarget = (if distanceTarget < 200 then 200 else distanceTarget)
  animate = ->
    requestAnimationFrame animate
    render()
  render = ->
    zoom curZoomSpeed
    rotation.x += (target.x - rotation.x) * 0.05
    rotation.y += (target.y - rotation.y) * 0.05
    distance += (distanceTarget - distance) * 0.1
    camera.position.x = distance * Math.sin(rotation.x) * Math.cos(rotation.y)
    camera.position.y = distance * Math.sin(rotation.y)
    camera.position.z = distance * Math.cos(rotation.x) * Math.cos(rotation.y)
    camera.target.position.x += (3000 - camera.target.position.x) * 0.005
    vector.copy camera.position
    renderer.clear()
    renderer.render scene, camera
    renderer.render sceneAtmosphere, camera
  
  #workaround for three.js bug
  removeObject = (scene, object) ->
    o = undefined
    ol = undefined
    zobject = undefined
    if object instanceof THREE.Mesh
      o = scene.__webglObjects.length - 1
      while o >= 0
        zobject = scene.__webglObjects[o].object
        if object is zobject
          scene.__webglObjects.splice o, 1
          return
        o--
  colorFn = colorFn or (x) ->
    c = new THREE.Color()
    c.setHSV (0.6 - (x * 0.5)), 1.0, 1.0
    c

  colorPartidos = (x) ->
    c = new THREE.Color()
    c.setHex x
    c

  Shaders =
    earth:
      uniforms:
        texture:
          type: "t"
          value: 0
          texture: null

      vertexShader: ["varying vec3 vNormal;", "varying vec2 vUv;", "void main() {", "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );", "vNormal = normalize( normalMatrix * normal );", "vUv = uv;", "}"].join("\n")
      fragmentShader: ["uniform sampler2D texture;", "varying vec3 vNormal;", "varying vec2 vUv;", "void main() {", "vec3 diffuse = texture2D( texture, vUv ).xyz;", "float intensity = 1.05 - dot( vNormal, vec3( 0.0, 0.0, 1.0 ) );", "vec3 atmosphere = vec3( 1.0, 1.0, 1.0 ) * pow( intensity, 3.0 );", "gl_FragColor = vec4( diffuse + atmosphere, 1.0 );", "}"].join("\n")

    atmosphere:
      uniforms: {}
      vertexShader: ["varying vec3 vNormal;", "void main() {", "vNormal = normalize( normalMatrix * normal );", "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );", "}"].join("\n")
      fragmentShader: ["varying vec3 vNormal;", "void main() {", "float intensity = pow( 0.8 - dot( vNormal, vec3( 0, 0, 1.0 ) ), 12.0 );", "gl_FragColor = vec4( 1.0, 1.0, 1.0, 1.0 ) * intensity;", "}"].join("\n")

  camera = undefined
  scene = undefined
  sceneAtmosphere = undefined
  renderer = undefined
  w = undefined
  h = undefined
  vector = undefined
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
    x: 4.7
    y: 0.6

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
    else if opts.format is "partidos"
      step = 4
      colorFnWrapper = (data, i) ->
        colorPartidos data[i + 3]
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
  @setTarget = (rot, distance) ->
    target.x = rot[0]
    target.y = rot[1]
    distanceTarget = distance

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

  @resetData = ->
    if @points isnt `undefined`
      @scene.removeObject @points
      removeObject @scene, @points
      removeObject @scene, @points

  @addData = addData
  @createPoints = createPoints
  @renderer = renderer
  @scene = scene
  this
