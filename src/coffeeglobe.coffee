root = global ? window
renderer = null
scene = null
camera = null
mesh = null

$(document).ready ->
    container = document.getElementById("container")
    app = new EarthApp()
    app.init({ container: container })
    app.run()

class EarthApp
    constructor: ->
        Sim.App.call(this)

    EarthApp.prototype = new Sim.App()
    init: (param) ->
        #Call Superclass init code to set up scene, renderer, and default camera
        Sim.App::init.call(this, param)
        #Create the earth and add it to our sim
        earth = new Earth()
        #console.log("earthinit")
        earth.init()
        @addObject earth
        sun = new Sun()
        #console.log("suninit")
        sun.init()
        @addObject sun
        # Are the stars out tonight...?
        #console.log("starinit")
        stars = new Stars()
        # Push the stars out past Pluto
        #stars.init EarthApp.SIZE_IN_EARTHS + EarthApp.EARTH_DISTANCE * EarthApp.PLUTO_DISTANCE_IN_EARTHS
        stars.init 5000
        @addObject stars

        # Are the spikes out tonight...?
        #spikes = new Spikes()
        # Push the spikes out past Pluto
        #spikes.init
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
              #globe.addData data[i][1],
                #format: "magnitude"
                #name: data[i][0]
                #animated: true
              #while i < 3
              while i < data.length
                #globe.addData data[i][1],
                earth.addData data[i][1],
                  format: "magnitude"
                  name: data[i][0]
                  animated: true
                i++
              #console.log("createPoints")
              #globe.createPoints()
              dataspikes = earth.createPoints()
              settime(globe, 0)()
              #globe.animate()
              document.body.style.backgroundImage = "none" # remove loading

        xhr.send null
        #earth.createTestSpike()
        #@addObject dataspikes
        #@addObject spikes

EarthApp.SIZE_IN_EARTHS = 2000
EarthApp.MOUSE_MOVE_TOLERANCE = 4
EarthApp.MAX_ROTATION_X = Math.PI / 2
EarthApp.MAX_CAMERA_Z = EarthApp.SIZE_IN_EARTHS * 50
EarthApp.MIN_CAMERA_Z = EarthApp.SIZE_IN_EARTHS * 3
EarthApp.EARTH_DISTANCE = 10000
EarthApp.PLUTO_DISTANCE_IN_EARTHS = 7700.2
EarthApp.EARTH_DISTANCE_SQUARED = 4500000
EarthApp.EXAGGERATED_PLANET_SCALE = 50.55

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
        #@object3D.add(point)
        point

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
        if root.point_baseGeometry is `undefined`
          root.point_baseGeometry = new THREE.Geometry()
          i = 0
          #while i < data.length
          console.log data.length
          while i < 3
            lat = data[i]
            lng = data[i + 1]
            #        size = data[i + 2]
            color = colorFnWrapper(data, i)
            size = 0
            addPoint lat, lng, size, color, root.point_baseGeometry
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
      console.debug data
      while i < 15
        lat = data[i]
        lng = data[i + 1]
        color = colorFnWrapper(data, i)
        size = data[i + 2]
        size = size * 200
        console.log "lat long", lat, lng, size, color
        @object3D.add( addPoint(lat, lng, size, color, subgeo))
        i += step
      if opts.animated
        root.point_baseGeometry.morphTargets.push
          name: opts.name
          vertices: subgeo.vertices

      else
        root.point_baseGeometry = subgeo


    createPoints:  ->
        if root.point_baseGeometry isnt `undefined`
          #console.debug root.point_baseGeometry
          if @is_animated is false
            points = new THREE.Mesh(root.point_baseGeometry, new THREE.MeshBasicMaterial(
              color: 0xffffff
              vertexColors: THREE.FaceColors
              morphTargets: false
            ))
          else
            if root.point_baseGeometry.morphTargets.length < 8
              console.log "t l", root.point_baseGeometry.morphTargets.length
              padding = 8 - root.point_baseGeometry.morphTargets.length
              console.log "padding", padding
              i = 0

              while i <= padding
                console.log "padding", i
                root.point_baseGeometry.morphTargets.push
                  name: "morphPadding" + i
                  vertices: root.point_baseGeometry.vertices

                i++
            points = new THREE.Mesh(root.point_baseGeometry, new THREE.MeshBasicMaterial(
              color: 0xffffff
              vertexColors: THREE.FaceColors
              morphTargets: true
            ))
          #scene.add @points
          #@addObject @points
          console.log "points"
          #console.debug points
          @object3D.add(points)
          @points = points

    update:  ->
        #"I feel the Earth move"
        window.globeMesh.rotation.y += Earth.ROTATION_Y
        @cloudsMesh.rotation.y += Earth.CLOUDS_ROTATION_Y
        #@fuckmeMesh.rotation.y += Earth.ROTATION_Y
        Sim.Object::update.call(this)

    init:  ->
        earthGroup = new THREE.Object3D()
        #Tell the framework about our object
        @setObject3D(earthGroup)
        #Add earth and clouds
        #console.log "createGlobe"
        #console.debug this
        #console.log(JSON.stringify(earthGroup))
        @createGlobe()
        @createClouds()
        #@createTestSpike()

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
        phi = (90 - 15) * Math.PI / 180
        theta = (180 - 10) * Math.PI / 180
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
        #@object3D.add(fuckmeMesh)
        #@object3D.add(point)
        #console.log "createfuckmemesh after"
        #console.debug this
        #window.fuckmeMesh = fuckmeMesh
        #window.point = point
        #@fuckmeMesh = point
        @object3D.add(fuckmeMesh)
        #@fuckm;eMesh = fuckmeMesh
        @object3D.add(point)
        #@point = point


Earth.ROTATION_Y = 0.0025
Earth.TILT = 0.41
Earth.CLOUDS_SCALE = 1.005 * 200
Earth.SPIKE_SCALE = 1.005 * 300
Earth.CLOUDS_ROTATION_Y = Earth.ROTATION_Y * 0.95

class Sun
    constructor: ->
        Sim.Object.call(this)
    Sun.prototype = new Sim.Object()
    init: ->
        #Create a point light to show off the Earth -set the light out back 
        #and to the left a bit
        light = new THREE.PointLight( 0xffffff, 2, 100)
        light.position.set(-10, 0, 20)
        #Tell the framework about our object
        this.setObject3D(light)

class Stars
    constructor: ->
        Sim.Object.call(this)
    Stars.prototype = new Sim.Object()
    init: (minDistance) ->
        starsGroup = new THREE.Object3D()
        starsGeometry = new THREE.Geometry()
        i = 0
        while i < Stars.NVERTICES
            vector = new THREE.Vector3((Math.random() * 2 - 1) * minDistance, (Math.random() * 2 - 1) * minDistance, (Math.random() * 2 - 1) * minDistance)
            vector = vector.setLength(minDistance)  if vector.length() < minDistance
            starsGeometry.vertices.push vector
            i++
        # Create a range of sizes and colors for the stars
        starsMaterials = []
        i = 0
        while i < Stars.NMATERIALS
            starsMaterials.push new THREE.ParticleBasicMaterial(
                color: 0x101010 * (i + 1)
                size: i % 2 + 1
                #size: i * 2 + 1
                sizeAttenuation: false
            )
            i++

        # Create several particle systems spread around in a circle, cover the sky
        i = 0
        while i < Stars.NPARTICLESYSTEMS
            stars = new THREE.ParticleSystem(starsGeometry, starsMaterials[i % Stars.NMATERIALS])
            stars.rotation.y = i / (Math.PI * 2)
            starsGroup.add stars
            i++
        # Tell the framework about our object
        @setObject3D starsGroup

Stars.NVERTICES = 667;
Stars.NMATERIALS = 8;
Stars.NPARTICLESYSTEMS = 24;
