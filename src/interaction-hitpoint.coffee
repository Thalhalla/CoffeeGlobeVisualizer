root = global ? window
renderer = null
scene = null
camera = null
mesh = null

$(document).ready ->
    container = document.getElementById("container")
    app = new InteractionApp()
    app.init({ container: container })
    app.run()

class InteractionApp
    constructor: ->
        Sim.App.call(this)
    #Subclass Sim.App
    InteractionApp.prototype = new Sim.App()

    init: (param) ->
        Sim.App.prototype.init.call(this, param)
        light = new THREE.DirectionalLight( 0xffffff,1)
        light.position.set(0, 0, 1).normalize()
        @scene.add(light)
        @camera.position.set(0, 0, 7)
        #Create the Model and add it to our sim
        model = new Model()
        model.init()
        @addObject(model)
        @model = model
        @lastX
        @lastY
        @mouseDown

    handleMouseDown: (x, y) ->
        @lastX = x
        @lastY = y
        @mouseDown = true

    handleMouseUp: (x, y) ->
        @lastX = x
        @lastY = y
        @mouseDown = false

    handleMouseMove: (x, y) ->
        @lastX = x
        @lastY = y
        @mouseDown = false
        if(@mouseDown)
            dx = x - @lastX
            if (Math.abs(dx) > InteractionApp.MOUSE_MOVE_TOLERANCE)
                @root.rotation.y += (dx * 0.01)
                @model.explosion.rotation.y -= (dx * 0.01)
            @lastX = x

    handleMouseScroll: (delta) ->
        dx = delta
        @camera.position.z -= dx

        #Clamp to some boundary values
        if(@comera.position.z < InteractionApp.MIN_CAMERA_Z)
            @comera.position.z = InteractionApp.MIN_CAMERA_Z
        if(@comera.position.z > InteractionApp.MIN_CAMERA_Z)
            @comera.position.z = InteractionApp.MIN_CAMERA_Z

    update: ->
        TWEEN.update()
        @root.rotation.y += 0.001
        @model.explosion.rotation.y -= 0.001
        Sim.App::update.call(this)

    InteractionApp.MOUSE_MOVE_TOLERANCE = 4
    InteractionApp.MAX_ROTATION_X = Math.PI / 2
    InteractionApp.MIN_CAMERA_Z = 4
    InteractionApp.MAX_CAMERA_Z = 12

class Model
    constructor: ->
        Sim.Object.call(this)
    #Subclass Sim.App
    Model.prototype = new Sim.Object()

    Model.EXPLOSION_DISTANCE = .222;

    init: (param) ->
        group = new THREE.Object3D

        #create our own model
        geometry = new THREE.SphereGeometry(2, 32, 32)
        map = THREE.ImageUtils.loadTexture("../images/earth_surface_2048.jpg")
        material = new THREE.MeshPhongMaterial({map: map})
        mesh = new THREE.Mesh( geometry, material)
        #group.rotation.x = Math.PI / 6
        #group.rotation.y = Math.PI / 5
        group.add(mesh)

        @setObject3D(group)
        @mesh = mesh
        @createHitIndicator()
        @createExplosion()
        @createNormalIndicator()
        @showHitIndicator = false
        @showExplosion = true
        @showNormalIndicator = false

    createHitIndicator: ->
        hitIndicator = new THREE.Object3D
        rad = 0.2
        geometry = new THREE.SphereGeometry(rad)
        material = new THREE.MeshPhongMaterial( { color: 0x00ff00, ambient: 0xaa0000 })
        mesh = new THREE.Mesh( geometry, material )
        hitIndicator.add(mesh)
        @object3D.add(hitIndicator)
        @hitIndicator = hitIndicator
        @hitIndicatorMesh = mesh
        @hitIndicatorMesh.visible = false

    createExplosion: ->
        explosion = new THREE.Object3D
        rad = 0.2
        geometry = new THREE.PlaneGeometry(1, 1, 1)
        map = THREE.ImageUtils.loadTexture("../images/BLASTZORZ13copy.png")
        material = new THREE.MeshPhongMaterial({map: map, transparent:true})
        mesh = new THREE.Mesh( geometry, material )
        explosion.add mesh
        @object3D.add explosion
        explosion.rotation.x = -@object3D.rotation.x
        explosion.rotation.y = -@object3D.rotation.y
        explosion.rotation.z = -@object3D.rotation.z

        @explosion = explosion
        @explosionMap = map
        @explosionMesh = mesh
        @explosionMesh.visible = false

    createNormalIndicator: ->
        normalIndicator = new THREE.Object3D
        rad = 0.1
        geometry = new THREE.CylinderGeometry( rad, rad, 1)
        material = new THREE.MeshPhongMaterial({ color: 0xff0000, ambient: 0xaa0000 })
        mesh = new THREE.Mesh( geometry, material )
        mesh.position.y = 1.5
        normalIndicator.add(mesh)
        @object3D.add(normalIndicator)
        @normalIndicator = normalIndicator
        @normalIndicatorMesh = mesh
        @normalIndicatorMesh.visible = false

    animateExplosion:  (normal) ->
        deltapos = normal.clone().multiplyScalar(Model.EXPLOSION_DISTANCE)
        newpos = @explosion.position.clone().addSelf(deltapos)
        new TWEEN.Tween(@explosion.position).to(
            {x: newpos.x, y: newpos.y, z: newpos.z}
            , 777).easing(TWEEN.Easing.Quadratic.EaseOut).start()
        @explosionMesh.material.opacity = 1
        fadetween = new TWEEN.Tween(@explosionMesh.material)
        .to( {
            opacity : 0
        }, 222)
        
        @explosion.scale.set(0.222, 0.222, 0.222)
        new TWEEN.Tween(@explosion.scale)
        .to( {
            x : .667, y : .667, z : .667
        }, 555)
        .easing(TWEEN.Easing.Quadratic.EaseOut)
        .start()
        .chain(fadetween)

    handleMouseOver: (x, y) ->
        @mesh.material.ambient.setRGB(.2,.2,.2)

    handleMouseOut: (x, y) ->
        @mesh.material.ambient.setRGB(0,0,0)

    handleMouseDown: (x, y, hitPoint, normal) ->
        if @showHitIndicator
          @hitIndicator.position.copy hitPoint
          @hitIndicatorMesh.visible = true
        if @showExplosion
          @explosion.position.copy hitPoint
          @explosionMesh.visible = true
          @animateExplosion normal
        if @showNormalIndicator
          quaternion = Sim.Utils.orientationToQuaternion(normal)
          @normalIndicator.quaternion.copy quaternion
          @normalIndicator.useQuaternion = true
          @normalIndicatorMesh.visible = true

    handleMouseUp: (x, y, hitPoint, normal) ->
        @hitIndicatorMesh.visible = false  if @showHitIndicator
        @normalIndicatorMesh.visible = false  if @showNormalIndicator

    handleMouseMove: (x, y) ->
        #handle mouse movement

