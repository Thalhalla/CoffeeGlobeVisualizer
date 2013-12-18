#Constructor
@EarthApp = ->
    Sim.App.call(this)
#Subclass Sim.App
@EarthApp:: =  new Sim.App()
#Our Custom Initializer
@EarthApp::init = (param) ->
    #Call Superclass init code to set up scene, renderer, and default camera
    Sim.App::init.call(this, param)
    #Create the earth and add it to our sim
    earth = new Earth()
    console.log("earthinit")
    earth.init()
    @addObject earth
    sun = new Sun()
    sun.init()
    @addObject sun
    # Are the stars out tonight...?
    stars = new Stars()

    # Push the stars out past Pluto
    stars.init EarthApp.SIZE_IN_EARTHS + EarthApp.EARTH_DISTANCE * EarthApp.PLUTO_DISTANCE_IN_EARTHS
    @addObject stars

    # Are the spikes out tonight...?
    #spikes = new Spikes()

    # Push the spikes out past Pluto
    #spikes.init EarthApp.SIZE_IN_EARTHS + EarthApp.EARTH_DISTANCE * EarthApp.PLUTO_DISTANCE_IN_EARTHS
    #@addObject spikes

    years = ["1990", "1995", "2000"]
    container = document.getElementById("container")
    #globe = new DAT.Globe(container)
    globe = earth
    #console.log globe
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
      #y.addEventListener "mouseover", settime(globe, i), false
      i++
    xhr = undefined
    #TWEEN.start()
    xhr = new XMLHttpRequest()
    xhr.open "GET", "../globe/population909500.json", true
    xhr.onreadystatechange = (e) ->
      if xhr.readyState is 4
        if xhr.status is 200
          data = JSON.parse(xhr.responseText)
          window.data = data
          i = 0
          while i < data.length
            #globe.addData data[i][1],
              #format: "magnitude"
              #name: data[i][0]
              #animated: true

            i++
          console.log("createPoints")
          globe.createPoints()
          settime(globe, 0)()
          #globe.animate()
          document.body.style.backgroundImage = "none" # remove loading

    xhr.send null

EarthApp.SIZE_IN_EARTHS = 10;
EarthApp.MOUSE_MOVE_TOLERANCE = 4;
EarthApp.MAX_ROTATION_X = Math.PI / 2;
EarthApp.MAX_CAMERA_Z = EarthApp.SIZE_IN_EARTHS * 50;
EarthApp.MIN_CAMERA_Z = EarthApp.SIZE_IN_EARTHS * 3;
EarthApp.EARTH_DISTANCE = 50;
EarthApp.PLUTO_DISTANCE_IN_EARTHS = 77.2;
EarthApp.EARTH_DISTANCE_SQUARED = 45000;
EarthApp.EXAGGERATED_PLANET_SCALE = 5.55;

#Custom Earth class
#@Earth = -> Sim.Object.call(this)

#@Earth:: = new Sim.Object()
class Earth
    constructor: ->
    Sim.Object.call(this)

    Earth.prototype = new Sim.Object()

    createGlobe: ->
        #Create our earth with nice texture
        earthSurfaceMap = THREE.ImageUtils.loadTexture("../images/earth_surface_2048.jpg")
        earthNormalMap = THREE.ImageUtils.loadTexture("../images/earth_normal_2048.jpg")
        earthSpecularMap = THREE.ImageUtils.loadTexture("../images/earth_specular_2048.jpg")
        shader = THREE.ShaderLib["normalmap"]
        #uniforms = THREE.UniformsUtils.clone( shader.uniforms )
        #uniforms[ "tNormal" ].texture = normalMap
        #uniforms[ "tDiffuse" ].texture = surfaceMap
        #uniforms[ "tSpecular" ].texture = specularMap
        #uniforms["enableDiffuse"].value = true
        #uniforms["enableSpecular"].value = true
        #shaderMaterial = new THREE.ShaderMaterial({
            #fragmentShader: shader.fragmentShader,
            #vertexShader: shader.vertexShader,
            #uniforms: uniforms,
            #lights: true
        #})
        shaderMaterial = new THREE.MeshPhongMaterial({
        map: earthSurfaceMap,
        normalMap: earthNormalMap,
        specularMap: earthSpecularMap});
        globeGeometry = new THREE.SphereGeometry(1, 32, 32)
        #globeGeometry.computeTangents()
        globeMesh = new THREE.Mesh( globeGeometry, shaderMaterial )
        #add tilt
        globeMesh.rotation.z = Earth.TILT
        @object3D.add(globeMesh)
        #@globeMesh = globeMesh
        console.log "createGlobemesh after"
        console.debug this
        window.globeMesh = globeMesh
        @globeMesh = globeMesh

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
        @color.setHSL((0.6 - (x * 0.5)), 1.0, 0.5)
        console.log(JSON.stringify(color))
        #color.setHSL (0.6 - (x * 0.5)), 1.0, 0.5
        @color

      geometry = new THREE.CubeGeometry(0.75, 0.75, 1);
      geometry.applyMatrix(new THREE.Matrix4().makeTranslation(0,0,-0.5));
      point = new THREE.Mesh(geometry);

      addPoint = (lat, lng, size, color, subgeo) ->
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

      while i < point.geometry.faces.length
        point.geometry.faces[i].color = color
        i++
      THREE.GeometryUtils.merge subgeo, point

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
          scene.add @points

    update:  ->
        #"I feel the Earth move"
        window.globeMesh.rotation.y += Earth.ROTATION_Y
        @cloudsMesh.rotation.y += Earth.CLOUDS_ROTATION_Y
        Sim.Object::update.call(this)

    init:  ->
        earthGroup = new THREE.Object3D()
        #Tell the framework about our object
        @setObject3D(earthGroup)
        #Add earth and clouds
        console.log "createGlobe"
        #console.debug this
        #console.log(JSON.stringify(earthGroup))
        @createGlobe()
        @createClouds()

    createClouds:  ->
        cloudsMap = THREE.ImageUtils.loadTexture("../images/earth_clouds_1024.png")
        cloudsMaterial = new THREE.MeshLambertMaterial( { color: 0xffffff, map: cloudsMap, transparent: true} )
        cloudsGeometry = new THREE.SphereGeometry(Earth.CLOUDS_SCALE, 32, 32)
        cloudMesh = new THREE.Mesh( cloudsGeometry, cloudsMaterial )
        cloudMesh.rotation.x = Earth.TILT
        @object3D.add(cloudMesh)
        @cloudsMesh = cloudMesh


Earth.ROTATION_Y = 0.0025
Earth.TILT = 0.41
Earth.CLOUDS_SCALE = 1.005
Earth.CLOUDS_ROTATION_Y = Earth.ROTATION_Y * 0.95
#Sun Class
@Sun = -> Sim.Object.call(this)
@Sun:: = new Sim.Object()
@Sun::init = ->
    #Create a point light to show off the Earth -set the light out back 
    #and to the left a bit
    light = new THREE.PointLight( 0xffffff, 2, 100)
    light.position.set(-10, 0, 20)
    #Tell the framework about our object
    this.setObject3D(light)
