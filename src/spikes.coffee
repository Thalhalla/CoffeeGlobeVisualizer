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

