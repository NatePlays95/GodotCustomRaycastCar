# GodotCustomRaycastCar
WIP. My attempt to replace VehicleBody with my own custom physics model.

Heavily inspired by this video from Toyful Games: youtube.com/watch?v=CdPYlj5uZeI
Car assets are not mine, and temporary.
Current test map is by Jreo at: jreo.itch.io

##Tips for use
If checking "Apply Forces at Contact Point" for more accurate physics, keep your vehicle at low speeds as it will roll easily.
Godot can't manage center of mass that well, so do know the center of mass of a RigidBody is its origin. Keep your wheels close to it, and the rest of the car's CollisionShape above it.
Values for spring stiffness and damping can be a bit large if going by SI unit standards. For a ~1000kg car, you want 12k+ stiffness and 1k+ damping.

##Why did I make this
In sum: Godot's VehicleBody has a series of bugs deemed "low priority" and I also don't know how to fix in the source code, so I tried to replicate it from scratch.
As a bonus, I could morph this into a hovercraft or futuristic racing vehicle model with few tweaks.
--also makes me very proud :3--
