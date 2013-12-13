@Spikes = ->
    Sim.Object.call(this)
@Spikes:: = new Sim.Object()
@Spikes::init = (minDistance) ->
    starsGroup = new THREE.Object3D()
    starsGeometry = new THREE.Geometry()
    i = 0
    while i < Spikes.NVERTICES
        vector = new THREE.Vector3((Math.random() * 2 - 1) * minDistance, (Math.random() * 2 - 1) * minDistance, (Math.random() * 2 - 1) * minDistance)
        vector = vector.setLength(minDistance)  if vector.length() < minDistance
        starsGeometry.vertices.push new THREE.Vertex(vector)
        i++
    # Create a range of sizes and colors for the stars
    starsMaterials = []
    i = 0
    while i < Spikes.NMATERIALS
        starsMaterials.push new THREE.ParticleBasicMaterial(
            color: 0x101010 * (i + 1)
            size: i % 2 + 1
            sizeAttenuation: false
        )
        i++

    # Create several particle systems spread around in a circle, cover the sky
    i = 0
    while i < Spikes.NPARTICLESYSTEMS
        stars = new THREE.ParticleSystem(starsGeometry, starsMaterials[i % Spikes.NMATERIALS])
        stars.rotation.y = i / (Math.PI * 2)
        starsGroup.add stars
        i++
    # Tell the framework about our object
    @setObject3D starsGroup

@Spikes.NVERTICES = 667;
@Spikes.NMATERIALS = 8;
@Spikes.NPARTICLESYSTEMS = 24;

@Spikes::addData = (data, opts) ->
    opts.animated = opts.animated || false
    @is_animated = opts.animated
    opst.format = opts.format || 'magnitude'
    console.log(opts.format)
    if (opts.format === 'magnitude')
        step = 3;
        colorFnWrapper = (date, i)
            colorFn(data[i+2])
    else if (opts.format === 'legend')
        step = 4;
        colorFnWrapper = (date, i)
            colorFn(data[i+3])
    else 
        throw('error: format not supported: '+opts.format)

    if (opts.animated)
        if (@_baseGeometry === undefined)
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
