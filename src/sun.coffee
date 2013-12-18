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
