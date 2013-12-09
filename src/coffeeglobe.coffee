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
    earth.init()
    this.addObject(earth)
    sun = new Sun()
    sun.init()
    this.addObject(sun)

#Custom Earth class
@Earth = -> Sim.Object.call(this)

@Earth:: = new Sim.Object()

@Earth::init = ->
    earthGroup = new THREE.Object3D()
    #Tell the framework about our object
    this.setObject3D(earthGroup)
    #Add earth and clouds
    this.createGlobe()
    this.createClouds()

@Earth::createGlobe = ->
    #Create our earth with nice texture
    surfaceMap = THREE.ImageUtils.loadTexture("../images/earth_surface_2048.jpg")
    normalMap = THREE.ImageUtils.loadTexture("../images/earth_normal_2048.jpg")
    specularMap = THREE.ImageUtils.loadTexture("../images/earth_specular_2048.jpg")
    shader = THREE.ShaderUtils.lib["normal"]
    uniforms = THREE.UniformsUtils.clone( shader.uniforms )
    uniforms[ "tNormal" ].texture = normalMap
    uniforms[ "tDiffuse" ].texture = surfaceMap
    uniforms[ "tSpecular" ].texture = specularMap
    uniforms["enableDiffuse"].value = true
    uniforms["enableSpecular"].value = true
    shaderMaterial = new THREE.ShaderMaterial({
        fragmentShader: shader.fragmentShader,
        vertexShader: shader.vertexShader,
        uniforms: uniforms,
        lights: true
    })
    globeGeometry = new THREE.SphereGeometry(1, 32, 32)
    globeGeometry.computeTangents()
    globeMesh = new THREE.Mesh( globeGeometry, shaderMaterial )
    #add tilt
    globeMesh.rotation.z = Earth.TILT
    @object3D.add(globeMesh)
    @globeMesh = globeMesh

@Earth::createClouds = ->
    cloudsMap = THREE.ImageUtils.loadTexture("../images/earth_clouds_1024.png")
    cloudsMaterial = new THREE.MeshLambertMaterial( { color: 0xffffff, map: cloudsMap, transparent: true} )
    cloudsGeometry = new THREE.SphereGeometry(Earth.CLOUDS_SCALE, 32, 32)
    cloudMesh = new THREE.Mesh( cloudsGeometry, cloudsMaterial )
    cloudMesh.rotation.x = Earth.TILT
    @object3D.add(cloudMesh)
    @cloudsMesh = cloudMesh

@Earth::update = ->
    #"I feel the Earth move"
    @globeMesh.rotation.y += Earth.ROTATION_Y
    @cloudsMesh.rotation.y += Earth.CLOUDS_ROTATION_Y
    Sim.Object::update.call(this)

@Earth.ROTATION_Y = 0.0025
@Earth.TILT = 0.41
@Earth.CLOUDS_SCALE = 1.005
@Earth.CLOUDS_ROTATION_Y = @Earth.ROTATION_Y * 0.95

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
