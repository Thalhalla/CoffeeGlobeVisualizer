@Stars = ->
    Sim.Object.call(this)
@Stars:: = new Sim.Object()
@Stars::init = (minDistance) ->
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

@Stars.NVERTICES = 667;
@Stars.NMATERIALS = 8;
@Stars.NPARTICLESYSTEMS = 24;

