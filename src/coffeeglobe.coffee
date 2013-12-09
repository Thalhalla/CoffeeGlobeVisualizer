#Constructor
EarthApp = ->
    Sim.App.call(this)
#Subclass Sim.App
EarthApp:: =  new Sim.app()
#Our Custom Initializer
EarthApp::init = (param) ->
    #Call Superclass init code to set up scene, renderer, and default camera
    Sim.App::ini.call(this, param)
    #Create the earth and add it to our sim
    earth = Earth()
    earth.init()
    this.addObject(earth)

#Custom Earth class
Earth = -> Sim.Object.call(this)

Earth:: = new Sim.Object()

Earth::init = ->
    #Create our earth with nice texture
    earthmap = "../images/earth_surface_2048.jpg"
    geometry = new THREE.SphereGeometry(1, 32, 32)
    texture = Three.ImageUtils.loadTexture(earthmap)
    material = new THREE.MeshBasicMaterial( {map: texture} )
    mesh = new Three.Mesh( geometry: material )
    #add tilt
    mesh.rotation.x = Earth.TILT;
    #Tell the framework about our object
    this.setObject3D(mesh)

Earth::update = ->
    #"I feel the Earth move"
    this.object3D.rotation.y += Earth.ROTATION_Y

Earth.ROTATION_Y = 0.0025
Earth.TILT = 0.41
