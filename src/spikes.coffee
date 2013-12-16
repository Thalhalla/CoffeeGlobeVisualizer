@Spikes = ->
    Sim.Object.call(this)
@Spikes:: = new Sim.Object()
@Spikes::init = (minDistance) ->
    @Spikes

@Spikes.NVERTICES = 667;
@Spikes.NMATERIALS = 8;
@Spikes.NPARTICLESYSTEMS = 24;

@Spikes.addData = (data, opts) ->
  lat = undefined
  lng = undefined
  size = undefined
  color = undefined
  i = undefined
  step = undefined
  colorFnWrapper = undefined
  opts.animated = opts.animated or false
  @is_animated = opts.animated
  opts.format = opts.format or "magnitude" # other option is 'legend'
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
        
        #        size = data[i + 2];
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

@Spikes.createPoints = ->
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

@Spikes.addPoint = (lat, lng, size, color, subgeo) ->
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
