class Spikes
    constructor: ->
        Sim.Object.call(this)
    Spikes.prototype = new Sim.Object()

    init: ->
        spikeGroup = new THREE.Object3D()
        @setObject3D(spikeGroup)
        #@addData
        #@createPoints
        @createTestSpike()
        @createGlobe()
        @createClouds()

    createGlobe: ->
        #Create our earth with nice texture
        earthSurfaceMap = THREE.ImageUtils.loadTexture("../images/earth_surface_2048.jpg")
        earthNormalMap = THREE.ImageUtils.loadTexture("../images/earth_normal_2048.jpg")
        earthSpecularMap = THREE.ImageUtils.loadTexture("../images/earth_specular_2048.jpg")
        shader = THREE.ShaderLib["normalmap"]
        shaderMaterial = new THREE.MeshPhongMaterial({
        map: earthSurfaceMap,
        normalMap: earthNormalMap,
        specularMap: earthSpecularMap})
        globeGeometry = new THREE.SphereGeometry(200, 32, 32)
        #globeGeometry.computeTangents()
        globeMesh = new THREE.Mesh( globeGeometry, shaderMaterial )
        #add tilt
        globeMesh.rotation.z = Earth.TILT
        @object3D.add(globeMesh)
        #console.log "createGlobemesh after"
        #console.debug this
        window.globeMesh = globeMesh
        @globeMesh = globeMesh

    createFuck: ->
        #Create our earth with nice texture
        fuckSurfaceMap = THREE.ImageUtils.loadTexture("../images/earth_surface_2048.jpg")
        fuckNormalMap = THREE.ImageUtils.loadTexture("../images/earth_normal_2048.jpg")
        fuckSpecularMap = THREE.ImageUtils.loadTexture("../images/earth_specular_2048.jpg")
        shader = THREE.ShaderLib["normalmap"]
        shaderMaterial = new THREE.MeshPhongMaterial({
        map: fuckSurfaceMap,
        normalMap: fuckNormalMap,
        specularMap: fuckSpecularMap})
        fuckmeGeometry = new THREE.CubeGeometry(300, 320, 320)
        #fuckmeGeometry.computeTangents()
        fuckmeMesh = new THREE.Mesh( fuckmeGeometry, shaderMaterial )
        #add tilt
        fuckmeMesh.rotation.z = Earth.TILT
        @object3D.add(fuckmeMesh)
        #console.log "createfuckmemesh after"
        #console.debug this
        window.fuckmeMesh = fuckmeMesh
        @fuckmeMesh = fuckmeMesh

    addData:  (data, opts) ->
      lat = undefined
      lng = undefined
      size = undefined
      color = undefined
      i = undefined
      step = undefined
      colorFnWrapper = undefined
      colorFn = (x) ->
        @color = new THREE.Color( 0xffffff )
        @color.setHSL (0.6 - (x * 0.5)), 1.0, 0.5
        #console.log JSON.stringify(color)
        @color

      geometry = new THREE.CubeGeometry 0.75, 0.75, 1
      geometry.applyMatrix new THREE.Matrix4().makeTranslation(0,0,-0.5)

      addPoint = (lat, lng, size, color, subgeo) ->
        point = new THREE.Mesh geometry
        phi = (90 - lat) * Math.PI / 180
        theta = (180 - lng) * Math.PI / 180
        point.position.x = 200 * Math.sin(phi) * Math.cos(theta)
        point.position.y = 200 * Math.cos(phi)
        point.position.z = 200 * Math.sin(phi) * Math.sin(theta)
        #console.debug this
        point.lookAt window.globeMesh.position
        point.scale.z = Math.max(size, 0.1) # avoid non-invertible matrix
        point.updateMatrix()
        i = 0
        while i < point.geometry.faces.length
            point.geometry.faces[i].color = color
            #console.log "point"
            i++
        THREE.GeometryUtils.merge subgeo, point

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
          #while i < data.length
          console.log data.length
          while i < 3
            lat = data[i]
            lng = data[i + 1]
            #        size = data[i + 2]
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

      #console.log("globe this")
      #console.debug this
      i = 0
      #while i < data.length
      console.log data.length
      while i < 3
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


    createPoints:  ->
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
          #scene.add @points
          @addObject @points

    update:  ->
        #"I feel the Earth move"
        window.globeMesh.rotation.y += Earth.ROTATION_Y
        #@cloudsMesh.rotation.y += Earth.CLOUDS_ROTATION_Y
        #@fuckmeMesh.rotation.y += Earth.ROTATION_Y
        Sim.Object::update.call(this)


    createClouds:  ->
        cloudsMap = THREE.ImageUtils.loadTexture("../images/earth_clouds_1024.png")
        cloudsMaterial = new THREE.MeshLambertMaterial( { color: 0xffffff, map: cloudsMap, transparent: true} )
        cloudsGeometry = new THREE.SphereGeometry(Earth.CLOUDS_SCALE, 32, 32)
        cloudMesh = new THREE.Mesh( cloudsGeometry, cloudsMaterial )
        cloudMesh.rotation.x = Earth.TILT
        @object3D.add(cloudMesh)
        @cloudsMesh = cloudMesh
    createTestSpike:  ->
        geometry = new THREE.CubeGeometry 0.75, 0.75, 1
        geometry.applyMatrix new THREE.Matrix4().makeTranslation(0,0,-0.5)
        point = new THREE.Mesh geometry
        phi = (90 - 45) * Math.PI / 180
        theta = (180 - 90) * Math.PI / 180
        point.position.x = 200 * Math.sin(phi) * Math.cos(theta)
        point.position.y = 200 * Math.cos(phi)
        point.position.z = 200 * Math.sin(phi) * Math.sin(theta)
        point.lookAt window.globeMesh.position
        point.scale.z = Math.max(500, 0.1) # avoid non-invertible matrix
        console.log "scaleZ", point.scale.z
        point.updateMatrix()
        i = 0
        while i < point.geometry.faces.length
            point.geometry.faces[i].color =  0xff0000
            i++
        #THREE.GeometryUtils.merge subgeo, point
        #Create our earth with nice texture
        fuckSurfaceMap = THREE.ImageUtils.loadTexture("../images/earth_surface_2048.jpg")
        fuckNormalMap = THREE.ImageUtils.loadTexture("../images/earth_normal_2048.jpg")
        fuckSpecularMap = THREE.ImageUtils.loadTexture("../images/earth_specular_2048.jpg")
        #shader = THREE.ShaderLib["normalmap"]
        shaderMaterial = new THREE.MeshPhongMaterial({
        map: fuckSurfaceMap,
        normalMap: fuckNormalMap,
        specularMap: fuckSpecularMap})
        fuckmeGeometry = new THREE.CubeGeometry(300, 320, 320)
        #fuckmeGeometry.computeTangents()
        fuckmeMesh = new THREE.Mesh( fuckmeGeometry, shaderMaterial )
        #add tilt
        fuckmeMesh.rotation.z = Earth.TILT
        @object3D.add(fuckmeMesh)
        #@object3D.add(point)
        #console.log "createfuckmemesh after"
        #console.debug this
        window.fuckmeMesh = fuckmeMesh
        #window.point = point
        #@fuckmeMesh = point
        @fuckmeMesh = fuckmeMesh

Spikes.NVERTICES = 667;
Spikes.NMATERIALS = 8;
Spikes.NPARTICLESYSTEMS = 24;
