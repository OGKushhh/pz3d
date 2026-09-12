Docs
MoG language
The DSL reference — every kind, attribute, and expression form, with examples.

mogen reads .mog source files, lowers them to an intermediate scene graph, and exports glTF 2.0 GLB. This document is the authoritative reference for the surface language: every node kind, every attribute, and the little bits of grammar that sit between them. For a conceptual overview of the whole pipeline, see ROADMAP.md; for a worked catalog of reusable modules, see modules.md.

Grammar at a glance
Values and expressions
Common attributes
Placement shortcuts
Scene structure
Primitives
Materials
Decals
Connectors
Attach: rigid alignment of two connector frames
Conform: moulding a primitive onto a target surface
Replicators: mirror, array, stack, grid
CSG: union / difference / intersect
Solid groups: solid
Modules: module and use
Imports: import
Animation: joint, clip, templates
Skeletons and skinning: skeleton, bone, skin=, bind=
Lights: light
Full example
#Grammar at a glance
A .mog file is a sequence of nodes. Every node shares the same shape:

kind ["optional name"] [(attr=value, ...)] [{ child_nodes... }]
kind is an identifier like box, cylinder, group, scene, material, joint, …
name is a quoted string. Some kinds require it (material, module, joint, clip, connector); most geometry kinds treat it as optional — when omitted the node's name defaults to its kind.
attr_list is a comma-separated key=value sequence in parentheses.
block is a brace-delimited list of child nodes.
Comments run from // to the end of the line. Whitespace between tokens is insignificant. The top of the file may contain import, material, module, joint, and clip declarations; scene { ... } holds the geometry itself.

#File metadata: meta
An optional top-of-file block recording author-facing metadata about the asset. Place at most once, before material / scene / module.

meta (
  name = "wooden_chair",
  version = "1.2.0",
  description = "A simple four-legged dining chair.",
  tags = ["furniture", "chair", "wood"],
)
attr	type	source	notes
name	string	author	human-readable asset name
version	string	author	author-controlled (semver-style is conventional but not enforced)
mogen_version	string	toolchain	auto-stamped from the running mogen version on every save (mogen generate/modify/animate/repair/textures and Studio Save). Don't write it yourself.
description	string	author	one-line summary
tags	list of string	author	free-form labels
The block is purely informational — it's not consumed by the geometry pipeline. It survives lowering on SceneGraph::meta so tooling (Studio, exporters) can read it without re-parsing. Old files without a meta block keep building; on the next save the toolchain inserts a fresh meta (mogen_version = "...") line.

Diagnostic codes for meta:

E0310 — meta cannot have a { … } body block.
E0311 — meta cannot take a quoted name (meta "x" (...)); use name= instead.
E0312 — duplicate meta block.
E0313 — meta only allowed at the top level.
W0107 — file's mogen_version doesn't match the running toolchain (will be re-stamped on next save).
#Global settings
Top-level directives that tune the build itself rather than describing geometry. They sit at the file level (alongside material / module) and are consumed during lowering.

directive	value	effect
lod_scale (value=N)	number, default 1.0	multiplies primitive default segments / rings / samples. 0.5 halves them, 2.0 doubles them. icosphere subdivisions step by round(log2(N)) instead, since each step quadruples its triangle count. Per-primitive values (segments=24, rings=16, …) are absolute and are not scaled.
lod_scale (value=0.5)

scene {
  sphere "head" (radius=0.5)         // 12 rings, 12 segments (default 16/24 halved)
  sphere "lod0" (radius=0.5, segments=48, rings=32)  // explicit values keep 48/32
}
The studio's "LOD scale" slider (under the build summary) edits this directive in place — drag it down to iterate quickly on big scenes, then drag back to 1.0 for export. The slider clears the directive when it returns to 1.0 so saved files stay clean by default.

#Values and expressions
Every value on the right side of an attribute is one of:

form	example	notes
number	0.5, -90, 1	parsed as f32
vec3	[1.0, 0.5, 0.0]	three expressions, comma-separated
list	[0, 90], [1, 2, 3, 4]	arbitrary arity
string	"wood"	used for names and references
ident	wood, y	no quotes; used for axes and enum-like values
expression	$height * 0.5, $r + 0.1, ($a - $b) / 2	arithmetic over $param refs
Inside module bodies, any expression may reference a declared parameter as $name. Expressions support + - * / with conventional precedence and parentheses. An expression is evaluated at module-expansion time — by the time the scene graph is built, every $name has been replaced with a concrete number.

#Common attributes
These apply to every geometry node (box, cylinder, …) and to group:

attribute	value	effect
pos	vec3	translation in the parent's frame; default [0, 0, 0]
rot	vec3 (Euler XYZ in degrees) or a list	rotation applied after translation; default identity
scale	scalar or vec3	uniform/per-axis scale; default 1
mat	string or ident	references a declared material by name
role	string or ident	semantic label; written into the GLB extras block
tags	comma-separated string	free-form labels; also in extras
Transforms compose from child → parent along the scene hierarchy, exactly as in glTF.

#Placement shortcuts
Every node accepts a family of ergonomic shortcuts on top of the classic pos/rot/size vec3s. They exist for one reason: an LLM should never need to do arithmetic that the DSL can do for it. Mix and match freely.

#Per-component shortcuts
shortcut	replaces / overrides	notes
x=, y=, z=	individual components of pos	missing axes default to pos's value, or 0
rx=, ry=, rz=	individual components of rot (degrees)	same fallback; great for single-axis spins
w=, h=, d=	individual components of size (X, Y, Z)	for 2D primitives, w/d are used on plane/curved_plane (XZ) and w/h on quad (XY)
box (y=1.5, size=1)            // equivalent to pos=[0, 1.5, 0], size=[1,1,1]
box (size=[2, 2, 0.1], h=3)    // h overrides the middle component — width=2, height=3, depth=0.1
cylinder (rx=90, radius=0.2, height=1)   // lay a cylinder on its side
#Scalar size (cube shorthand)
Any primitive that takes size=[…] also accepts size=<number>, which expands to a uniform vec3. box (size=0.5) is a half-metre cube.

#from / to — axis-aligned box by corners
On any primitive that uses size, from=[x1,y1,z1] + to=[x2,y2,z2] sets size to |to − from| and pos to their midpoint. No "shift by half" math:

box (from=[-2, 0, -1.5], to=[2, 2.8, -1.4], mat="wall")
// equivalent to: box (pos=[0, 1.4, -1.45], size=[4.0, 2.8, 0.1])
#anchor — place by face, not centre
Every primitive's pos controls where its anchor point lands, not where its centre lands. The default anchor is center; anchor=bottom puts the primitive's bottom face at pos, which is usually what "sit on the ground" means. Values are underscore-joined tokens drawn from center, top, bottom, left, right, front, back:

box (y=0,  size=[1, 2, 1], anchor=bottom)           // bottom face on y=0
box (xyz, size=2,           anchor=bottom_left_front) // corner at the origin
Internally the anchor shifts the mesh vertices so the chosen point is at the local origin. The six default face connectors (top, bottom, left, …) move with the shift, so attach/connector math stays correct.

#Relative placement: above, below, left_of, right_of, in_front_of, behind
Set one of these to the name of a prior sibling in the same parent; the node is translated so its matching face is flush against the sibling's opposite face, optionally plus gap. At most one may be set per node.

group "chests" {
  box "chest_lo" (size=[0.8, 0.6, 0.5])
  box "chest_hi" (above="chest_lo", gap=0.02, size=[0.8, 0.6, 0.5])
}
Resolution happens after the target's subtree is fully lowered, so nested geometry is included in the AABB. Lookup is scoped to siblings in the same parent, so replicated subtrees (array, grid) don't collide with identically named nodes elsewhere.

#Deformation modifiers
Every primitive accepts a small set of common modifier attrs that perturb the generated mesh between primitive construction and anchor placement. The point is variety without authoring extra geometry — bent beams, weathered rocks, melted candles, jelly blobs — using one or two extra attrs.

attribute	value	effect
bend_x, bend_y, bend_z	degrees	arc-length-preserving bend around the named axis. Length axis is the perpendicular one (Y for bend_x/bend_z, X for bend_y).
twist_y	degrees	helical twist around Y, from 0 at y_min to the full angle at y_max.
taper	ratio (1.0 = unchanged, 0.5 = half-width at top)	linear shrink along Y.
droop	amount (0..1 of length)	quadratic gravity-style sag along -Y; the base stays put, the top sinks by amount * height.
noise	0..1	coherent value-noise displacement along the vertex normal. Yields blobby "rock" texture.
jitter	0..1	per-vertex random displacement along the normal. Higher-frequency than noise, looks "jagged".
faceted	0/1	rebuild the mesh with three unique vertices per triangle and face-flat normals; reads as low-poly.
seed	integer	RNG seed for the stochastic modifiers (noise, jitter); same seed always reproduces the same shape.
Common combinations:

// Asteroid / rock — coherent bumps + per-vertex jitter + flat shading.
icosphere "rock"   (radius=0.4, noise=0.30, jitter=0.15, faceted=1, seed=7)
// Bent timber / pipe — single-axis bend with light surface noise.
cylinder  "post"   (radius=0.05, height=2.0, bend_z=12, noise=0.04)
// Melted wax / jelly — gravity-sagged top with soft surface texture.
cylinder  "candle" (radius=0.18, height=0.7, droop=0.4, noise=0.05)
// Twisted, tapered beam — combine deterministic deformations freely.
box       "beam"   (size=[0.2, 0.2, 3], twist_y=20, taper=0.7)
Stochastic modifiers are deterministic for a given seed so rebuilds are reproducible. Two unnamed primitives with noise=0.3 and no seed share the same seed default (1) and therefore the same surface — set distinct seeds when you want sibling rocks to differ.

Default tessellation auto-bumps (×2 segments / +1 icosphere subdivision) when a smooth deformer (bend_*, twist_y, noise, droop) is present so a bent cylinder doesn't read as faceted. Author's explicit segments=, rings=, subdivisions= always override.

Modifiers are not applied to mesh (loaded glb) primitives — their joints, UVs, and skinning contract are wider than what the deform pass preserves.

See examples/asteroid_field.mog for a runnable showcase.

#Scene structure: scene, group
scene {
  group "chair" (pos=[0, 0, 0]) {
    box "seat" (pos=[0, 0.5, 0], size=[1.0, 0.1, 1.0])
  }
}
scene is the root container. Exactly one per file is expected in practice; top-level nodes outside any scene are also lowered and become extra roots.
group is a transform-only container — no geometry of its own, used to compose children and receive pos/rot/scale.
solid behaves like group in the scene tree, but its same-material leaf children are CSG-unioned into a single mesh at export time. See Solid groups below.
#Primitives
All primitives accept the common attributes above (pos, rot, scale, mat, role, tags) plus the kind-specific attributes below.

kind	required attrs	other attrs
box	size=[x,y,z]	—
plane	size=[x,_,z] (Y ignored)	—
quad	size=[w,h] or vec3 (w,h,_)	—
cylinder	radius, height	segments (default 24)
cone	radius, height	segments (default 24)
sphere	radius	rings (16), segments (24)
capsule	radius, height	rings (8), segments (24)
torus	major, minor	major_segments (24), minor_segments (12)
prism	size=[x,y,z]	triangular prism along +Z
pyramid	radius, height, sides	N-sided pyramid base
disc	radius	segments (24)
icosphere	radius	subdivisions (2)
rounded_box	size=[x,y,z], radius	segments per corner (4)
wedge	size=[x,y,z]	right-triangle prism — flat bottom on -Y, hypotenuse climbing toward +Y/+Z. Useful for ramps, roof pitches, doorstops
frustum	bottom=[w,d], top=[w,d], height	truncated rectangular pyramid (defaults bottom=[1,1], top=[0.5,0.5], height=1)
tube	outer, inner, height	hollow cylinder (pipe / ring); segments (24)
hemisphere	radius	half-sphere, flat side on -Y; rings (8), segments (24)
half_cylinder	radius, height	D-profile half-cylinder, flat side facing -Z; segments (24)
torus_arc	major, minor	partial torus; arc (degrees, default 90) sweeps around +Y; major_segments (24), minor_segments (12). Useful for arches and handles
ellipsoid	size=[x,y,z]	rings (16), segments (24); independent radii per axis
superellipsoid	size=[x,y,z]	ew, ns (1 = sphere, > 1 boxy, < 1 pinched), rings (16), segments (24)
curved_plane	size=[x,z] or vec3	bend_u, bend_v (degrees; arc angle along X/Z), segments_u/segments_v (12)
lathe	profile=[[r,y], …]	segments (24), cap_ends (1 = capped); profile authored bottom-to-top in (radius, y) pairs
spline_tube	points=[[x,y,z], …]	radius (scalar) or radii=[…] (per-point), segments (12), samples (8), cap_ends (1)
spline_ribbon	points=[[x,y,z], …]	width (scalar) or widths=[…] (per-point), samples (8), twist (degrees, default 0); flat strip along a Catmull–Rom curve
leaf_card	size=[w,h]	cards (default 2); alpha-cutout foliage card cluster — one quad plus cards-1 rotated copies sharing the same XY plane. Pair with a mat="…" whose alpha_mode="mask" and double_sided=1
mesh	src="path.glb"	load and embed an external glTF binary as a single mesh. Path is relative to the calling .mog. Materials, skinning, and animations on the source GLB are dropped — set them in the DSL instead
branch	—	procedural tree / vine / antler. See Branch below
slab	size=[x,y,z]	box alias; default anchor bottom (sits on ground)
post	size=[x,y,z]	box alias; default anchor bottom (pillar/leg)
panel	size=[x,y,z]	box alias; default anchor back (flat panel flush to a surface)
wall	size=[x,y,z]	holes=[[x,y,w,h], …] — rectangular cutouts through the Z axis
plane and quad are both flat single-quad meshes; plane is XZ-aligned, quad is XY-aligned (useful for UI-style panels).

superellipsoid is the workhorse for smooth organic bodies (eggs, pears, bullet shapes) and stylised soft boxes — pick ew/ns together for a symmetric shape, or split them for asymmetric profiles like an apple (ew=1.2, ns=0.8).

curved_plane, lathe, spline_tube, and spline_ribbon accept nested list literals: points=[[0, 0, 0], [1, 0.5, 0]], profile=[[0.2, 0], [0.5, 0.4]]. Inner lists must be constant (no $param) — parameterise the whole node via a module wrapper instead. spline_tube and spline_ribbon both run a Catmull–Rom curve through their control points and use a parallel-transport frame so the cross section doesn't flip at inflection points; spline_ribbon adds a twist that ramps a roll around the path tangent.

tube, hemisphere, half_cylinder, and torus_arc are the open / hollow / partial counterparts of the canonical round primitives. They give you ring tops, bowls, columns with a flat back, arches, and handles without an extra CSG step.

leaf_card is the workhorse for foliage and feathers: it builds a small cluster of crossed quads that sit on top of an alpha-cutout texture, so an entire bush or pine sprig reads as one mesh.

slab, post, and panel are box aliases that exist only to change the default anchor — their geometry is identical to box. Use them to make "this sits on the ground" or "this is a wall-hung panel" the one-line thing it should be, without anchor=… on every row. You can still override anchor= explicitly if you need something different.

wall is a box with rectangular cutouts along Z. Each hole is a 4-element sublist [cx, cy, w, h] in the wall's local frame (X/Y are the face plane; the Z thickness axis is cut all the way through). Cutouts are applied via CSG difference at lowering time and the result is welded/cleaned, so a single wall node becomes one watertight mesh — no nested difference idiom needed:

wall "barracks" (size=[3, 3, 0.1], holes=[
  [-0.75, -0.4, 0.9, 2.0],   // door
  [ 0.9,  0.3, 0.8, 0.8],    // window
])
#Branch
branch is a self-contained procedural tree builder. One node expands into a recursive cluster of spline_tube segments tapering from a thick trunk down to twigs, with optional leaf_card clusters at the tips. The result reads as one editable wrapper in the scene graph; the inner segments are stamped non-editable because their geometry is a deterministic function of seed=.

attribute	default	effect
form	"decurrent"	growth habit preset — see below. Sets sensible defaults for all attrs in this table; user attrs still win
length	1.0	trunk length (m)
radius	0.05	trunk base radius (m)
depth	4	recursion depth (number of branching levels)
splits	2	child branches per parent at each split
length_falloff	0.7	per-level length multiplier
radius_falloff	0.6	per-level radius multiplier
branch_angle	35	angle (degrees) child branches lean off the parent tangent
roll	137.5	roll (degrees) between successive children — the golden angle by default, breaks bilateral symmetry
tropism	0.0	bias toward +Y per segment (positive = upright trees, negative = drooping)
bend	10	random bend (degrees) added to each segment frame
leader_bias	0.0	0.0–1.0 strength of central-leader behaviour. At 1.0 child 0 of every fork continues straight up at full length/radius (pine-like silhouette); at 0.0 all forks are equal (default broadleaf habit)
multi_stem	1	number of trunks emerging from the base. Only honoured by form="shrub"; ignored otherwise
segments	8	radial segments per spline_tube
samples	4	samples per spline segment
seed	1	RNG seed; same seed = identical tree
jitter	0.2	0.0–1.0 random perturbation amount on lengths/angles
leaves	1	emit leaf_card clusters at terminal tips (0 to disable)
leaf_size	0.35	leaf-card height (m)
leaf_aspect	1.0	leaf width / height ratio. <1 for needle/willow leaves, >1 for wide flat leaves
leaf_cards	2	crossed cards per leaf cluster (or fronds in the palm rosette)
leaf_mat	—	material name for leaves; defaults to inherited mat=
form values:

value	habit	distinctive defaults
"decurrent"	broadleaf tree (default — oak, maple)	equal forks, square leaves
"excurrent"	conifer (pine, spruce)	strong central leader, near-horizontal side branches, narrow needle leaves
"weeping"	willow	long branches with strong negative tropism (drooping), long narrow leaves
"shrub"	bush	several short trunks at the base (multi_stem=4 by default), no leader
"palm"	palm	single straight trunk with a fan of frond-shaped cards at the tip; no recursive branching
Wrap a branch in a group and apply scale= / rot= to compose forests, antlers, vines, or root systems out of the same generator. Pair it with the stdlib branch and leaf modules for hand-tuned shapes.

Default values mean that cylinder "leg" with no attrs is a 1 m unit-radius cylinder centered on the origin. Every primitive is authored in its local frame and then positioned via pos/rot/scale.

#Materials
material "wood"  (color=[0.55, 0.35, 0.18], metallic=0.0, roughness=0.8)
material "glass" (color=[0.9, 0.95, 1.0], alpha=0.3, roughness=0.05, transmission=0.9)
material "neon"  (color=[1, 0.2, 1], emissive=[1, 0.2, 1], emissive_strength=8.0)
material "leaf"  (color=[0.25, 0.6, 0.2], alpha_mode="mask", alpha_cutoff=0.5)
Declared at the top of the file or inside scene { ... }. Attributes:

color — vec3 [r, g, b] in linear space; alpha defaults to 1.0.
alpha — optional alpha override for transparency. Setting alpha < 1 without an explicit alpha_mode auto-selects "blend".
metallic — 0.0–1.0, default 0.0.
roughness — 0.0–1.0, default 0.9.
normal_strength — slope multiplier baked into the derived normal map by mogen textures. Larger = more pronounced bumps. Range ~0..8, default 1.5. Has no effect if normal_texture is authored directly.
occlusion_strength — 0.0–1.0 ceiling on how dark the derived AO map can get. 0 emits flat white (no darkening), 1 lets cavities reach black. Default 0.7. Has no effect if occlusion_texture is authored directly.
alpha_mode — "opaque" (default), "blend" (translucent), or "mask" (1-bit cutout, e.g. foliage).
alpha_cutoff — threshold for alpha_mode="mask", default 0.5.
emissive — vec3 glow colour added on top of PBR shading. Use this for screens, embers, lava. Default [0, 0, 0].
emissive_strength — HDR multiplier on emissive (KHR_materials_emissive_strength). Values > 1.0 drive bloom and produce the saturated, "fluorescent paint" look. Default 1.0.
transmission — 0.0–1.0 fraction of light that passes through the surface (KHR_materials_transmission). 0 is opaque PBR, 1 is perfectly clear glass. Orthogonal to alpha_mode — use this for glass and water, alpha/alpha_mode for gels, tints, and smoke.
double_sided — 0 (default) or 1. When 1, the renderer draws both faces of the triangle (glTF doubleSided). Use for leaves, fins, flags, cloth, and any thin curved_plane/plane/disc/quad whose underside can be seen. This is the correct fix for tilted or bent single-sided geometry — mirroring a bent curved_plane along its bend axis does not produce a double-sided surface; it produces two sheets curling away from each other.
uv_mode — "tile" (default) or "fit". Controls how textures map onto the geometry. "tile" emits world-space UVs so 1 world unit = 1 texture tile (scaled by uv_scale). Texel density is identical across every primitive that uses the material — the right choice for repeating surfaces like stone walls, wood planks, fabric, ground, and roof shingles. "fit" falls back to per-face [0, 1]² UVs so every face of the primitive shows the full image once — the right choice when the texture is the picture: signs, paintings, decals, stained-glass panes, anything whose image must land at a specific place on a specific face. Pick "fit" for image-as-texture; leave the default for material-as-texture.
uv_scale — 1.0 (default), a scalar (uv_scale=2), or a vec2 (uv_scale=[2, 1]). In tile mode this is "tiles per world unit": 2 doubles the tiling density (smaller bricks), 0.5 halves it (bigger bricks). In fit mode it multiplies the [0, 1] coords — > 1 repeats the image inside a face, < 1 zooms into a sub-region. Per-axis vec2 form lets you stretch a texture asymmetrically (planks on a floor, bands on a column).
base_color_texture — string path to an .png/.jpg file on disk, resolved relative to the .mog file. Multiplied against color. sRGB.
metallic_roughness_texture — packed metal/rough map (glTF convention: green = roughness, blue = metallic). Linear.
normal_texture — tangent-space normal map. Linear.
occlusion_texture — ambient occlusion (red channel). Linear.
emissive_texture — emissive colour map, multiplied against emissive. sRGB.
prompt — optional free-form description of the surface, used by mogen textures as the subject hint when generating an albedo image. Lets you steer the model away from the auto-derived "material name + colour" framing — useful when the material name is generic (fabric_main) or when the default phrasing trips Gemini's recitation filter. Example: prompt="navy nylon ripstop weave". The texture pipeline rephrases this on retry if the image generator rejects the request for recitation, so a literal brand-adjacent phrasing won't permanently jam a build.
shader — "standard" (default) or "water". Selects a per-material shader override in MoGen Studio's preview only — the exported .glb always uses standard PBR, since glTF 2.0 cannot carry custom shader code. "water" swaps the live preview for animated ripples + fresnel-driven body/sky mix + sun glints. The water branch reads the standard material knobs:
color is the absorbed body tint when looking straight down ([0.12, 0.55, 0.62] reads as a lagoon, [0.02, 0.05, 0.15] as deep ocean).
uv_scale controls ripple density: 1.0 ≈ pool-scale chop, raise it for choppier small ponds, lower it for lazy ocean swells.
roughness ties together chop, sky-reflection blur, sun-glint sharpness, and foam. 0.05 is glassy mirror, 0.4 is a calm pool, 0.9 (the default) is ocean-style ripples, 1.0 adds whitecaps.
metallic lerps the Fresnel base from clean dielectric water (0) toward liquid metal at 1 — mercury / molten silver, where the body tint becomes the reflection colour at all angles.
transmission makes the body absorption recede so the sky reflection and what's behind the surface dominate. Combine with alpha_mode="blend" to actually see the pool floor through the water.
emissive / emissive_strength light the water from within (lava, magic potion, bioluminescent surf).
normal_strength multiplies the wave-slope (default 1.5); raising it deepens the ripples without retuning chop.
normal_texture and base_color_texture are blended into the procedural waves and body tint respectively so authors can paint in high-frequency detail or shallow/deep variation.
Example:

material "oak" (
  color=[1, 1, 1],
  roughness=0.8,
  base_color_texture="textures/oak_albedo.png",
  normal_texture="textures/oak_normal.png"
)

material "lake" (color=[0.05, 0.32, 0.45], shader="water")
Texture files are embedded in the output GLB, so the resulting .glb is self-contained and can be moved without the source images. Missing files are a hard error at export.

Reference a material on any geometry or group via mat="wood". The lookup is by exact string match; unknown names are a hard error at lowering.

#Decals
A decal is a transparent image (logo, label, sticker, scribble, seal, handwritten note) projected onto a surface. It lowers to a thin double-sided quad floating slightly off the parent surface, with an auto-synthesized alpha_mode="blend" material whose albedo is an RGBA PNG.

decal "logo" (
  pos = [0, 0.1, 0.101],
  size = [0.25, 0.12],
  prompt = "embroidered MoGen logo, white thread on dark fabric"
)
Attributes:

size — [w, h] in local units. Default [0.5, 0.5]. The decal is a flat XY quad whose normal points along its local +Z; rotate the decal with rot= / rx/ry/rz to point its face wherever you need.
prompt — image description handed to Gemini when running mogen textures. Asks for an RGBA PNG with a fully transparent background; the resolved file path is spliced back into the source as image="…" for reproducibility.
image — explicit path to an existing RGBA PNG (relative to the .mog file). Wins over prompt=; skips the LLM call entirely.
tint — vec3 [r, g, b] multiplied against the decal's albedo. Default [1, 1, 1] (no tint).
roughness — 0.0–1.0. Default 0.6.
offset — +Z gap from the surface, in local units, to avoid z-fighting against the underlying mesh. Default 0.001 reads flush at typical scales; raise on coarse geometry.
#Curved surfaces: on= / at=
For flat surfaces, place the decal as a child of the surface and let pos= handle alignment. For curved surfaces, write the decal once with on= and at= and the lowering pass synthesizes a conform patch behind the scenes — the decal's vertices are bent onto the target's surface so it actually hugs the curvature.

ellipsoid "bag" (size=[1.0, 0.5, 0.5], mat="leather") {
  connector "front_spot" (at=[0.0, 0.0, 0.25], dir=[0, 0, 1])
}
decal "bag_logo" (
  size = [0.18, 0.10],
  on   = "bag",
  at   = "front_spot",
  prompt = "embroidered MoGen wordmark, cream thread on dark leather"
)
on — name of the target node to conform onto. Triggers the shortcut.
at — required when on= is set; names the connector on the target that acts as the patch anchor.
up — optional x|y|z; which local axis points along the surface normal. Defaults to z (the decal quad's face direction).
lift — optional outward offset along the surface normal, applied during conform. Layered on top of the per-mesh offset= value, so use lift= on coarse target geometry where you need extra separation. Defaults to 0.
When on= is used the decal is reparented under the target. Its pos= is dropped (positioning comes from at=, not user transforms), but rot= and scale= are baked into the artwork before projection — so rot=[0, 0, 90] spins the logo 90° in the tangent plane (the useful "rotate the artwork around the surface normal" case), and scale=[2, 1, 1] makes it twice as wide. Off-plane rotations like rot=[90, 0, 0] tilt the artwork off the surface; the conform kernel reproduces them faithfully but the result is rarely what authors want — reach for rz= / rot=[0, 0, deg] for the common "spin the logo" case.

If neither prompt= nor image= is set, the decal's name is used as the prompt. That makes the compact form decal "embroidered logo, white thread" (size=[0.2, 0.1], pos=[0, 0.1, 0.101]) valid — handy when you want to keep the description and the node identity in one place.

A few rules that aren't optional:

mat= is rejected on decals — they own their material outright. Use tint=/roughness= to influence shading.
Each decal gets its own auto-named material (__decal_<name>) and is never merged into adjacent same-material siblings by the export-time merge pass.
The mogen textures pipeline asks Gemini for transparent-background RGBA directly. There is no chroma-key step: the alpha_mode="mask" foliage path is for foliage, not decals.
at=, up=, and lift= are inert without on= — the validator rejects them so a typo doesn't silently disappear.
Example: a logo on the front of a shirt, plus an authored handwriting overlay on a paper card.

material "shirt" (color=[0.1, 0.2, 0.6])
material "paper" (color=[0.96, 0.94, 0.88], roughness=0.95)

scene {
  box "shirt" (size=[0.6, 0.8, 0.2], mat="shirt")
  decal "shirt_logo" (
    pos = [0, 0.1, 0.101],
    size = [0.25, 0.12],
    prompt = "embroidered MoGen logo, white thread on dark fabric"
  )

  panel "card" (size=[0.4, 0.3, 0.01], mat="paper", right_of="shirt", gap=0.2)
  decal "note" (
    pos = [0.6, 0.0, 0.0061],
    size = [0.30, 0.20],
    rot = [0, 0, 0],
    image = "textures/notes/handwritten_thanks.png"
  )
}
#Connectors
Connectors are oriented frames that a node exposes so other nodes can attach to it. They do not produce geometry.

box "seat" (pos=[0, 0.5, 0], size=[1.0, 0.1, 1.0]) {
  connector "top"    (at=[0,  0.05, 0], dir=[0,  1, 0], tag=seat_top)
  connector "bottom" (at=[0, -0.05, 0], dir=[0, -1, 0], tag=seat_bottom)
}
Attributes:

attribute	value	default
at	vec3	[0, 0, 0]
dir	vec3 (any nonzero)	[0, 1, 0]
tag	string or ident	empty
radius	number	— (unset)
Internally a connector is stored as a position plus a quaternion that rotates canonical +Y onto dir. tag groups compatible attach points (e.g. every leg top shares tag=leg_top) so downstream fitting logic can pair them.

When a node is the child of an attach, its pos / rot are still honoured as a local offset on top of the alignment — pos shifts the anchor in the parent's frame and rot rotates the aligned node around its anchor — so a Studio gizmo drag persists across rebuilds.

#Attach: rigid alignment of two connector frames
attach is the rigid counterpart to conform: it sets a child node's transform so its plug connector lines up exactly with a socket connector on a parent, then reparents the child under the parent. No deformation, no per-vertex work — just a clean alignment with optional roll.

scene {
  cylinder "trunk"  (radius=0.2, height=1.0) {
    connector "top" (at=[0, 0.5, 0], dir=[0, 1, 0], tag=trunk_top)
  }
  sphere   "canopy" (radius=0.5) {
    connector "stem" (at=[0, -0.5, 0], dir=[0, -1, 0], tag=canopy_stem)
  }
  attach (parent="trunk", child="canopy", socket="top", plug="stem")
}
attribute	required	default	effect
parent	yes	—	name of the node carrying the socket connector
child	yes	—	name of the node carrying the plug connector
socket	no	"top"	connector name on parent
plug	no	"bottom"	connector name on child
offset	no	0.0	gap (m) along the socket's outward direction; positive lifts the child away from the parent
twist	no	0.0	roll (degrees) around the socket's axis after alignment
After lowering, the child is reparented under the parent and its local TRS is recomputed so the two connector frames are coincident (+offset along the socket normal, plus twist around it). Any pos= / rot= declared on the child stays as an additive local offset on top of the alignment — that's what lets a Studio gizmo drag survive a rebuild.

attach also runs per-instance inside array and mirror replicators: when you write the attach inside the body of an array (count=4), each of the four expanded copies resolves its own pair of connectors, so a single declaration glues every copy.

#Conform: moulding a primitive onto a target surface
conform deforms a child primitive's vertex positions so it lies on a target mesh's surface. It has two modes:

Path mode (from= / to=) — stretches a strip or tube between two connectors on the target. The canonical case is a zip on a curved sports bag; covers labels wrapped around bottles, gold trim along a shield's edge, hoses lying on a chassis, ribbons spiralling around a vase, stitched seams.
Patch mode (at=) — lays a flat / disc-shaped child down at a single anchor connector and bends it to follow surface curvature locally. The canonical case is a round pocket on the side of the bag; covers brand decals, plates, lids, eye spots, leather patches.
Conform is the deforming counterpart to attach: where attach sets a rigid transform aligning two connector frames, conform mutates the child's mesh. Pick the mode by which attrs you provide — mixing at= with from=/to= is an error, and so is omitting both.

// Path mode — strip stretched along a curve.
conform (target="bag", child="zip", from="zip_a", to="zip_b",
         along=x, lift=0.005)

// Patch mode — disc anchored at a single point.
conform (target="bag", child="pocket", at="pocket_spot", lift=0.002)
#Shared attributes
attribute	required	default	effect
target	yes	—	name of the surface mesh node to mould onto
child	yes	—	name of the primitive whose vertices get deformed
lift	no	0.0	outward offset along the surface normal (m) — typically a fraction of a millimetre to avoid z-fighting
reparent	no	1	reparent child under target after conform; pass 0 to keep its original parent
#Path mode — from= / to=
Each child vertex's coordinate on the along axis becomes a position along the surface path; the perpendicular axes lie tangent / normal to the surface at each sample.

attribute	required	default	effect
from	yes	—	connector name on target — start of the path
to	yes	—	connector name on target — end of the path
along	no	x (flat strips) / y (tubes)	which child-local axis is the path axis
width	no	inferred from along	child-local axis perpendicular to path, tangent to surface
height	no	inferred from along	child-local "thickness" axis (along surface normal)
samples	no	64	path subdivisions (clamped to ≥ 2). Increase for high-curvature surfaces
twist	no	0	total roll (degrees) around the path tangent across the strip
Compatible primitives (path mode):

Flat strips: box, plane, quad, curved_plane, slab, post, panel, wall, spline_ribbon
Tubes: cylinder, capsule, tube, spline_tube (cross-section ring rotates with the surface frame)
Imported meshes via mesh "..." (src="..."): accepted, but along= is required
#Patch mode — at=
Each child vertex is independently snapped to its closest point on the target surface; the child's up axis becomes the surface-outward direction at every vertex. This makes flat decals (a disc, a quad) bend to follow curvature locally without forcing the author to pick a path or supply two endpoints.

attribute	required	default	effect
at	yes	—	connector name on target — patch centre
up	no	y (most flat primitives) / z (quad, leaf_card)	which child-local axis aligns with the surface outward normal
Compatible primitives (patch mode):

Flat decals: disc, plane, quad, curved_plane, leaf_card
Box-likes used as thin patches: box, slab, panel, wall — give them a small extent on the up axis
Round primitives with a flat side: cylinder, hemisphere, half_cylinder (a thin cylinder makes a perfect round disc)
Imported meshes: accepted, but up= is required
#Rejected primitives
Closed shapes with no canonical surface axis (sphere, ellipsoid, icosphere, torus, torus_arc, superellipsoid, pyramid, cone, frustum, lathe, prism, rounded_box, wedge) and CSG result nodes (union/difference/intersect) are rejected in both modes. The error message names the kind and points to the other mode if it would have worked there (e.g. disc rejected in path mode → suggests patch mode).

#Tessellation
The deformation reads each child vertex's coordinate on the along axis as its position along the path. A bare box only has two distinct values per axis (the eight corners), so an un-subdivided box can't bend — every interior path frame is skipped and the strip stays straight no matter how curved the target surface is.

conform therefore inserts planar cuts perpendicular to along whenever the child's tessellation is coarser than samples / 4 segments (clamped to 8–64). Author-controlled subdivision still wins: pass a primitive that's already dense (curved_plane (segments_u=48), cylinder (segments=64), spline_ribbon (samples=64)) and the auto-subdivision is a no-op.

#Examples
// Zip on a sports bag.
material "leather" (color=[0.18, 0.16, 0.14], roughness=0.85)
material "rubber"  (color=[0.08, 0.08, 0.08], roughness=0.7)

scene {
  ellipsoid "bag" (size=[1.0, 0.5, 0.5], mat="leather") {
    connector "zip_a" (at=[-0.4, 0.20, 0.22], dir=[0, 0, 1])
    connector "zip_b" (at=[ 0.4, 0.20, 0.22], dir=[0, 0, 1])
  }
  box "zip" (size=[0.8, 0.012, 0.04], mat="rubber")
  conform (target="bag", child="zip", from="zip_a", to="zip_b",
           along=x, lift=0.005)
}
// Wine-bottle label wrapped around a cylindrical bottle.
scene {
  cylinder "bottle" (radius=0.04, height=0.3, mat="glass") {
    connector "label_l" (at=[-0.04, 0.12, 0],  dir=[-1, 0, 0])
    connector "label_r" (at=[ 0.04, 0.12, 0],  dir=[ 1, 0, 0])
  }
  curved_plane "label" (size=[0.25, 0.06], segments_u=48, mat="paper")
  conform (target="bottle", child="label", from="label_l", to="label_r",
           along=x, lift=0.0005)
}
// Hose draped along a chassis: tube child, along=y matches cylinder's long axis.
scene {
  superellipsoid "chassis" (size=[1.6, 0.4, 0.7], ew=2.0, ns=2.0, mat="metal") {
    connector "port_a" (at=[-0.7, 0.20, 0.30], dir=[0, 1, 0])
    connector "port_b" (at=[ 0.7, 0.20, 0.30], dir=[0, 1, 0])
  }
  cylinder "hose" (radius=0.03, height=1.4, mat="rubber")
  conform (target="chassis", child="hose", from="port_a", to="port_b",
           along=y, samples=96, lift=0.005)
}
// Patch mode — round pocket decals on the sides of a sports bag.
scene {
  superellipsoid "body" (size=[0.6, 0.3, 0.3], ew=1.5, ns=1.2, mat="fabric") {
    connector "left_spot"  (at=[-0.3, 0, 0], dir=[-1, 0, 0])
    connector "right_spot" (at=[ 0.3, 0, 0], dir=[ 1, 0, 0])
  }
  disc "pocket_l" (radius=0.08, segments=32, mat="accent")
  disc "pocket_r" (radius=0.08, segments=32, mat="accent")
  conform (target="body", child="pocket_l", at="left_spot",  lift=0.002)
  conform (target="body", child="pocket_r", at="right_spot", lift=0.002)
}
#Pass ordering and reparenting
Conform runs after attach and before skin binding, so an attached child can also be conformed and bind-pose world matrices reflect the deformed geometry.

By default (reparent=1) the child is moved under the target with an identity local transform — its deformed vertices already live in the target's local frame, so this keeps the scene tree clean. Any user pos= / rot= declared on the child is intentionally discarded once the conform fires. Pass reparent=0 to keep the child's original parent; the deformed mesh is transformed back into the child's local frame and the child's location in the hierarchy is untouched.

#Path generation
The path is built by chord-and-snap: each sample's chord-interpolated point is projected onto the target surface via closest-point query. This is not a true geodesic, but for the typical conform use cases (smoothly curving surfaces between two connectors), it is visually indistinguishable. Crank samples= up for high-curvature paths.

twist ramps a roll around the path tangent linearly from 0 at the first sample to twist degrees at the last — useful for spiralling ribbons or bandages where the strip rotates around the path as it walks.

#Reserved (not yet implemented)
The validator accepts but lowering rejects, with a clear message: direction (projection mode — decal splat from a direction), curve (only "geodesic_lerp" is supported in v1), and via (multi-segment paths).

#Replicators: mirror, array, stack, grid
Wrapper nodes that create one parent group and either replicate or lay out their children. All four accept the usual transform attributes so the whole cluster can be positioned as a unit.

#mirror
mirror "pair" (axis=x) {
  sphere "ball" (pos=[0.5, 0.5, 0], radius=0.25)
}
axis is x, y, or z (ident or string). The body is emitted twice — once unchanged and once with the named axis negated. Use it for left/right symmetry where only one side is authored by hand.

#array
array "legs" (count=4, around=y) {
  group "offset" (pos=[0.45, 0, 0.45]) {
    cylinder "leg" (radius=0.05, height=0.5)
  }
}
Attributes:

count — number of copies (integer); default 1.
around — x / y / z ident; the rotation axis. Default y.
start_angle — degrees offset of the first copy; default 0.
The children are cloned count times; the i-th copy is rotated by start_angle + 360° * i / count around around. Combine with an offset group (as above) to place the first copy off the rotation axis; the array then fans it into a ring.

#stack
Lay children out along one axis, using each child's computed AABB as its "slot". No half-size math, no accumulated offsets to maintain by hand.

stack "cake" (axis=y, gap=0.02) {
  slab "tier_a" (size=[1.4, 0.25, 1.4])
  slab "tier_b" (size=[1.0, 0.20, 1.0])
  slab "tier_c" (size=[0.6, 0.15, 0.6])
}
Attributes:

attribute	value	default	effect
axis	x, y, z	y	stacking direction
gap	number	0	spacing between consecutive children
align	center, start, end	center	alignment on the two perpendicular axes
pack	start, center, end	start	where the whole stack sits along axis: start keeps the first child at origin; center centres the stack; end puts the last child's far face at origin
Each child keeps its own declared pos/x/y/z as an additive offset inside its slot — stack computes the slot position, your pos nudges within it.

#grid
N-dimensional replicator. Creates count[0] × count[1] × count[2] copies of the body, each offset by step[0..3] * [i, j, k]:

grid "tiles" (count=[5, 1, 3], step=[0.6, 0, 0.6], center=1) {
  slab "tile" (size=[0.55, 0.05, 0.55])
}
Attributes:

attribute	value	default
count	vec3, list, or scalar	[1, 1, 1]
step	vec3, list, or scalar	[0, 0, 0]
center	0 / 1	0 — when 1, the grid is centred on the wrapper origin
A scalar count/step applies to X only (useful for 1D rows); a 2-element list applies to X/Z (floor patterns). For 3D, pass a vec3.

#CSG: union / difference / intersect
CSG ops fold their children into a single mesh that hangs off the op node itself — the operand children do not become separate scene nodes.

difference "wall_with_door" (mat="concrete") {
  box "wall"    (size=[4.0, 3.0, 0.2])
  box "doorway" (pos=[0, -0.5, 0], size=[0.9, 2.0, 0.5])
}
union — N ≥ 1 operands; the union of all. Accepts an optional smooth=<radius> attribute that swaps the boolean union for a smooth minimum (smin) blend with that radius. Used by the humanoid stdlib modules to fillet limb-to-torso seams; values of a few centimetres are typical at human scale. smooth=0 (the default) is identical to the hard boolean.
difference — the first operand minus every subsequent operand.
intersect — N ≥ 2 operands; the shared volume.
Operand transforms are baked into the vertices at evaluation time, so each operand lives in the parent's frame regardless of its local pos/rot. Connectors and material children declared directly on the CSG node still apply; any on operand children are ignored.

The output is cleaned (vertex welding, degenerate-tri cull, normal recompute) to give the exporter a watertight mesh.

#Solid groups: solid
solid { … } is a group-like container that defers CSG union to export time. Its same-material, non-skinned leaf children are merged into a single mesh, so overlapping or touching primitives of the same material read as one hollow shape — interior faces where pieces meet get eliminated.

solid "shell" (mat="stone", cleanup="coplanar") {
  box "floor"   (pos=[0, 0.1, 0],   size=[6.2, 0.2, 4.2])
  box "north"   (pos=[0, 1.7, 2.0], size=[6.0, 3.0, 0.2])
  box "south"   (pos=[0, 1.7,-2.0], size=[6.0, 3.0, 0.2])
  box "east"    (pos=[ 3.0, 1.7, 0], size=[0.2, 3.0, 4.0])
  box "west"    (pos=[-3.0, 1.7, 0], size=[0.2, 3.0, 4.0])
}
Children lower as normal scene nodes — you can still attach to them, put modules inside, author connectors, and so on. The merge is export-time, scoped to that subtree. The in-memory scene graph the editor sees keeps every child as a distinct, editable node.
Only same-material leaf siblings merge together. Different-material children (mat="glass" next to mat="stone") stay as separate nodes so textures and PBR factors are preserved.
Skinned meshes, joint-referenced nodes, and groups are never merged; they pass through unchanged.
#cleanup="coplanar"
When set, the merged output gets one extra pass that drops triangle pairs which share a plane and have opposite-facing normals. This catches the case CSG union can't resolve on its own: two boxes that touch along a face without overlapping — e.g. perpendicular walls meeting at a corner. Without the cleanup, both sides of the seam survive; with it, they cancel.

Values: "coplanar" (enable) or "none" (default).

#Modules: module and use
Modules are parametric sub-graphs. A declaration lives at the top level of the file:

module "leg" (height=0.5, radius=0.05) {
  cylinder "leg" (pos=[0, $height * 0.5, 0],
                  radius=$radius, height=$height, mat="wood") {
    connector "top" (at=[0, $height * 0.5, 0], dir=[0, 1, 0], tag=leg_top)
  }
}
Parameters:

Each parameter has a scalar default (number or expression). vec3, list, string, or ident defaults are rejected — $param substitution is numeric.
Parameters are referenced inside the body as $name. They participate in pos, rot, scale, radius, height, etc., and inside nested vec3 expressions like [0, $h * 0.5, 0].
Invoke a module with use:

scene {
  group "chair" {
    use "leg" (height=0.6, radius=0.04)
    array "legs" (count=4, around=y) {
      group "offset" (pos=[0.45, 0, 0.45]) {
        use "leg" (height=0.5, radius=0.05)
      }
    }
  }
}
Rules:

use takes the module's declared name. Unknown names fail with a clear error.
Omitted arguments fall back to declared defaults. Unknown argument names are a hard error (catches typos).
Modules may call other modules. Recursion is detected and rejected.
Expansion is lexically scoped — $param references outside a module body are rejected.
#Imports: import
Pull module declarations, material declarations, and the entire scene { … } of another .mog file into the current file. Two use cases:

Module libraries — share parameterised modules across files:

import "shared/legs.mog"

scene {
  use "leg" (h=0.6)
}
Scene composition — assemble a scene out of object .mog files. Each imported file's top-level scene { … } becomes an implicit module named after the file stem, so import "chair.mog" lets you use "chair" ():

import "objects/chair.mog"
import "objects/table.mog"

scene {
  use "chair" (pos=[ 1, 0, 0])
  use "table" (pos=[ 0, 0, 0])
  use "chair" (pos=[-1, 0, 0], rot=[0, 180, 0])
}
use accepts the same translation/rotation/scale shortcuts as every other node kind — pos, rot, scale, x / y / z, rx / ry / rz, and from / to — and applies them as an implicit wrapping group around the expanded body. Equivalent to group (pos=…) { use "x" () } but without the ceremony. If the module declares a parameter with one of those names (e.g. a scalar pos param), the caller's value binds to the parameter instead.

import is a top-level directive — declare it alongside material and module, before or after them. It takes a quoted file path and an optional (as=<ident>) to override the synthesised module name (handy when two files share a stem, since stem collisions are a hard error).

Path resolution:

Relative paths are joined onto the importing file's directory. So import "shared/legs.mog" from /proj/scenes/chair.mog reads /proj/scenes/shared/legs.mog.
Absolute paths are used verbatim.
Paths are canonicalised before deduplication, so import "lib.mog" and import "./lib.mog" resolve to the same file and load only once.
What gets lifted from an imported file:

module declarations — added to the importer's module registry.
material declarations (top-level or inside the imported scene { … }) — added to the importer's material registry. Texture paths are rooted at the defining file's directory: material "wood" (base_color_texture = "textures/wood.png") inside objects/chair.mog resolves to objects/textures/wood.png regardless of where the composing scene lives.
Top-level scene { … } — synthesised as module "<stem>" () { … }. Use (as=<ident>) on the import to give it a different name.
Rules:

Imports are transitive: an imported file can import another file, and every transitively-imported module / material / synthesised scene is visible to the original importer.
Cycles (A imports B imports A) are detected and rejected with the full chain in the error message.
Importing the same file twice — directly or via a chain — is a no-op.
Module name shadowing follows precedence: stdlib < imports < user declarations. A user module "leg" { … } in the importing file overrides any leg pulled in by import; an imported leg overrides the stdlib's leg.
Synthesised scene-as-module collisions are a hard error. If two imports both default to chair (one in a/chair.mog, one in b/chair.mog), rename one with (as=chair_a).
Material name collisions across imports are a hard error. Re-declare the material in the importing file to shadow it.
An imported file may contain only import, module, material, and a single top-level scene { … }. Other top-level forms (joints, clips, skeletons) aren't composable yet and are rejected.
Failures surface as errors at mogen check / mogen build time, pointing at the offending import.

#Animation: joint, clip, templates
Animation lowers to glTF node-transform tracks. Every clip animates one or more scene nodes (or joints, which are scene-node aliases with a typed DOF) — there is no separate animation graph or state machine. Clips are top-level declarations alongside material/module/joint. Skinning is additive: see Skeletons and skinning below for the skeleton/bone/skin= half of the story.

#Joints
A joint names an articulation, picks a DOF type, and points at the scene node that rotates/translates when the joint moves.

joint "door_hinge" (type=hinge, axis=[0, 1, 0], limits=[0, 100], pivot="door")
attribute	value	notes
type	hinge, slider, ball, rotor	DOF kind
pivot	string — a node name	required
axis	vec3	default [0, 1, 0]
limits	[lo, hi] list	optional; degrees (rotary) or meters (slider)
#Authored clips
clip "open" (seconds=1.0) {
  track "door_hinge" (from=0, to=90)
}
clip holds a single duration and an ordered list of track children.
track targets a joint (by name) or a scene node directly. When targeting a node, add prop="translation"|"rotation"|"scale" to pick the channel (pos / rot are accepted aliases).
from / to are scalars. For rotation they're degrees around the joint's axis (or the track's axis= when targeting a plain node); for translation they're distance along the axis; for scale they're the uniform factor. Two keyframes are emitted at 0 and seconds and linearly interpolated.
For multi-keyframe authored curves, pass keys=[[t, v], …] instead of from/to. Times must be strictly ascending and span any subset of [0, seconds] — the exporter emits one glTF keyframe per pair and interpolates linearly between them. This is what the stdlib walk / run / jump clips use to drive bones with hand-tuned curves.
#Procedural templates
One-line declarations that expand into a full clip. They all take a target="name" pointing at a joint or a scene node.

template	extra attrs	effect
spin	axis, rpm (60)	continuous rotation
open_close	axis, angle (90), seconds (1.0)	0° → angle → 0° swing
wave	axis, amplitude (15°), hz (1.0)	sinusoidal wobble
flap	axis, amplitude (30°), hz (2.0)	faster wobble, bigger amplitude
idle	amplitude (0.02 m), hz (0.5)	tiny translation breathe
When the target is a joint, its axis is used by default; when it's a node, pass axis explicitly.

spin "rotor_spin" (target="rotor", axis=[0, 0, 1], rpm=30)
open_close "door_swing" (target="door_hinge", angle=90, seconds=1.2)
#Skeletons and skinning: skeleton, bone, skin=, bind=
A skeleton is a hierarchy of named bone nodes that drives skinning weights on procedural meshes. Bones are ordinary scene nodes (kind="bone"); the skeleton block produces a Skin whose joints list captures every descendant bone in depth-first order. Bind-pose inverse matrices are computed automatically from the bones' world transforms at lower time, so the author never writes a Mat4.

scene {
  skeleton "rig" {
    bone "hip"      (pos=[0, 0.95, 0], envelope=0.25) {
      bone "spine"  (pos=[0, 0.30, 0], envelope=0.25) {
        bone "neck" (pos=[0, 0.30, 0], envelope=0.10)
      }
      bone "thigh_l" (pos=[ 0.10, -0.05, 0], envelope=0.25)
      bone "thigh_r" (pos=[-0.10, -0.05, 0], envelope=0.25)
    }
  }

  capsule "torso" (pos=[0, 1.25, 0], radius=0.18, height=0.6,
                   mat="cloth", skin="rig")
  sphere  "head"  (pos=[0, 1.7,  0], radius=0.12, mat="skin",
                   skin="rig", bind="neck")
}
#skeleton and bone
skeleton "name" { … } declares the rig. Inside, every child must be a bone. Bones may nest arbitrarily — each bone becomes a scene node parented under the previous one, so its pos/rot/scale are parent-relative.
bone "name" (pos=…, rot=…, scale=…, envelope=…) declares a joint. envelope= (default 0.75) controls how far the bone's influence reaches when the auto-skinner assigns weights to nearby vertices — smaller envelopes are tighter, larger envelopes blend more across joints. Adjacent bones should overlap in envelope so vertices near a shared joint receive weight from both sides.
Skeletons are top-level or scene-level declarations. They place themselves in the scene tree (so they animate alongside other nodes), but they don't carry geometry of their own.

#Binding meshes: skin="rig"
Any mesh-bearing node (primitive or import) with skin="<skel name>" becomes a skinned mesh: the lowering pass walks the skeleton, computes per-vertex weights against the four nearest bones (capped by each bone's envelope), and writes them into the GLB as JOINTS_0 / WEIGHTS_0 accessors. Group-like containers (group, solid, stack, grid, array, mirror, module, use) propagate skin= to every mesh descendant, so wrapping a sub-tree in group (skin="rig") { … } skins the whole thing in one line.

#Rigid pinning: bind="bone_name"
Add bind="bone" alongside skin= to pin every vertex of that mesh rigidly to a single bone — weight 1.0, no envelope blend. Used for accessories that should track a joint without deforming: heads (bound to the neck), helmets, backpacks, hand-held props. bind propagates from a group to its descendants the same way skin= does, so a face cluster parented under a group (bind="neck") follows the head as one rigid piece.

#Animating bones
Bones are scene nodes, so the regular clip { track … } machinery drives them: track "thigh_l" (prop=rotation, axis=[1, 0, 0], keys=[…]). The stdlib humanoid_walk / humanoid_run / humanoid_idle / humanoid_jump modules expand into clips of exactly this shape, targeting the bones declared by humanoid_full. There is no separate "animation rig" — if you can drive a node, you can drive a bone.

CSG operands (union/difference/intersect children) are fused into the parent's mesh during lowering, so a stray skin= on an operand never survives. Put skin= on the CSG node itself (or on a wrapping group) instead.

#Lights: light
mogen exports lights via the standard glTF KHR_lights_punctual extension. A light is a transform-only scene node — it carries pos / rot like any other node, has no mesh, and never accepts children. Direction is implicit: the light points along its local -Z axis.

light "sun"  (kind=directional, dir=[-0.4, -1, -0.3], color=[1, 0.95, 0.85], intensity=3)
light "lamp" (kind=point, pos=[0, 2, 0], color=[1, 0.9, 0.7], intensity=10, range=8)
light "spot" (kind=spot,  pos=[0, 3, 0], dir=[0, -1, 0], intensity=20,
              range=10, inner_cone=20, outer_cone=35)
attribute	value	notes
kind	directional, point, spot	required
color	vec3	linear-space RGB; default [1, 1, 1]
intensity	number	candela for point/spot, lux for directional; default 1.0
range	number	distance cutoff for point/spot; rejected on directional
dir	vec3	optional shortcut: rotates the node so -Z points along dir (overrides rot=)
inner_cone	number	spot only; degrees, default 0
outer_cone	number	spot only; degrees, default 45
Lights ignore mat, anchor, from/to, and the relative-placement shortcuts (above/below/…) — only transforms (pos, rot, scale, x/y/z, rx/ry/rz), role, and tags apply.

mogen does not emit an ambient term: the glTF core spec has no ambient light, and Godot derives ambient from a WorldEnvironment node downstream. For low-intensity fill, use a dim directional light (e.g. intensity=0.5, dir=[0, -1, 0]) or set up an environment in your engine.

#Colliders
Annotate any geometry, group, solid, or use with collider="aabb" to mark it as a collision volume:

slab "floor"     (size=[18.4, 0.1, 10.4], mat="wood", collider="aabb")
slab "wall_back" (size=[18.4, 3, 0.2], z=-5.1, mat="plaster", collider="aabb")
use  "desk"      (pos=[0, 0, 0.4], collider="aabb")
The bounding box is derived at compile time from the node's subtree mesh extents in node-local space, after attach / conform / skin binding have finished — so a collider on use "desk" encloses the whole desk, and a collider on a conform-deformed plank reflects the bent vertices, not the straight ones.

"aabb" is the only accepted value in v1; anything else raises a build error. A collider on a node whose subtree carries no mesh is silently dropped (the attribute lives on, but the box is omitted from the output).

The export writes one entry per collider'd node into glTF node.extras.collider:

json"extras": {
  "collider": {
    "type": "aabb",
    "min": [-9.2, -0.05, -5.2],
    "max": [ 9.2,  0.05,  5.2]
  }
}
mogen does not run a physics simulation — this is metadata for the downstream importer to convert into a CollisionShape3D (or equivalent). MoGen Studio renders an off-by-default wireframe gizmo at each collider'd node; toggle it from View → Show Colliders or the viewport context menu.

#Shadow casting
Every node casts shadows by default. Add cast_shadow=0 to opt a node — and its entire subtree — out of the realtime shadow pre-pass and the exported shadow hint:

plane "ground" (size=20, mat="grass", cast_shadow=0)
group "filler" (cast_shadow=0) {
  box (size=[1, 1, 1])     # inherits cast_shadow=0
  use  "rocks"             # inherits too
}
The flag propagates monotonically: an ancestor's cast_shadow=0 overrides a descendant default. Setting it on a child while a parent already disabled it is a no-op (the descendant stays opted out).

The export writes extras.cast_shadow=false only on opted-out nodes; the typical "casts shadow" case omits the key entirely so the JSON chunk stays lean. Downstream importers that don't recognise the key fall back to the glTF default (casts shadow), matching the spec.

The right-sidebar inspector exposes the toggle as a checkbox under Shadow.

#Full example
A door in a wall, with a swinging-open animation, built end-to-end:

material "wood"     (color=[0.55, 0.35, 0.18], roughness=0.8)
material "concrete" (color=[0.78, 0.78, 0.78], roughness=0.85)

scene {
  difference "wall_with_door" (mat="concrete", role="wall") {
    box "wall"       (size=[4.0, 3.0, 0.2])
    box "door_gap"   (pos=[0, -0.5, 0], size=[0.9, 2.0, 0.5])
  }

  // Hinge at the left edge: offset the panel by half-width inside the group.
  group "door" (pos=[-0.45, 1.0, 0]) {
    box "panel" (pos=[0.45, 0, 0], size=[0.9, 2.0, 0.04], mat="wood")
  }
}

joint "door_hinge" (type=hinge, axis=[0, 1, 0], limits=[0, 100], pivot="door")
clip "open" (seconds=1.2) {
  track "door_hinge" (from=0, to=90)
}
Compile with mogen build examples/<file>.mog -o out.glb and open in any glTF-2.0 viewer or game engine.

#Diagnostics and tooling
mogen check <file>.mog validates without building. Pass --json for machine-readable diagnostics (the format the LLM repair loop consumes).
mogen dump-scene <file>.mog --json prints the lowered graph for debugging.
mogen inspect <file>.glb reads back a GLB and prints its top-level structure.
See ROADMAP.md §8 for the full diagnostic catalog.

----------------------------------------------------
CLI
`mogen` subcommands: build, check, generate, modify, animate, repair, textures, moghub, and more.

mogen is a single static binary. Every entry point is a subcommand — mogen <subcommand> …. Run mogen --help for the auto-generated short form, or mogen <subcommand> --help for per-command flags.

This page is the long-form reference. For the language those commands operate on, see dsl.md. For the desktop GUI that wraps the same pipeline, see studio.md.

Common flags and conventions
auth — sign in to Google OAuth + MoGHub
build — compile DSL to GLB
parse — dump the AST
check — validate a DSL file
dump-scene — print the lowered scene graph
inspect — summarise a GLB
generate — Gemini-driven scene generation
modify — Gemini-driven edit of an existing .mog
animate — Gemini edit limited to animation declarations
repair — auto-fix validation errors with Gemini
textures — generate PBR textures with Gemini Flash Image
bench — run a prompt suite and report success rate
moghub — browse, download, and publish to the MoGHub community
mcp — run mogen as a stdio MCP server
Environment variables
Exit codes
#Common flags and conventions
A few flag patterns repeat across every LLM-driven subcommand (generate, modify, animate, repair, textures, bench):

flag	meaning
--api-key <KEY>	Override GEMINI_API_KEY for this invocation.
--model <NAME>	Gemini model id. Default gemini-pro-latest for text. For textures, the default depends on credentials: gemini-3-pro-image-preview when authenticated via OAuth (paid plan), otherwise gemini-2.5-flash-image. Pass gemini-3.1-flash-image-preview (or any other image model) to override.
--temperature <N>	Sampling temperature. Library default is 0.3 when omitted.
--thinking <low|medium|high|xhigh>	Cap server-side reasoning. low = 512 tokens, medium = 2048, high = 8192 (default), xhigh = 24576 (slowest, most careful).
--budget_tokens <N>	Abort if total prompt + response token count exceeds this limit.
--max-repair-iters <N>	Repair attempts after the first try. Default 2.
--cached-content <NAME>	Reuse an existing cachedContents/... resource for the system instruction (skips re-uploading the grammar/stdlib reference).
--no-cache	Disable the automatic system-instruction cache. By default mogen creates and reuses a cachedContents resource per-binary so repeated calls skip re-upload.
--seed <U64>	Seed embedded in the DSL header for reproducibility. Defaults to the seed parsed from an existing .mog's header, or a random one if absent.
--dry-run	Skip GLB compilation and disk writes — print the generated/edited DSL only.
The seed, the thinking budget, and the original prompt are stamped into the top-level meta(...) block of every generated .mog:

mogmeta (
  mogen_version = "0.1.1",
  seed = "1777210527637284168",
  thinking = "high",
  prompt = "A simple four-legged chair.",
)
#auth
Sign in / out for every credential mogen persists under ~/.mogen/. The command is target-aware: mogen auth <target> <verb> where <target> is one of gemini-cli, antigravity, or moghub. The top-level mogen auth status (no target) prints a one-line summary for every target at a glance.

shmogen auth status                          # one-line summary per target
mogen auth gemini-cli  {login,status,logout}
mogen auth antigravity {login,status,logout}
mogen auth moghub      {login,status,logout}
target	what it authenticates	on-disk file
gemini-cli	Google OAuth for text gen via Cloud Code Assist	~/.mogen/google_auth.json
antigravity	Google OAuth for image gen via Cloud Code Assist	~/.mogen/antigravity_auth.json
moghub	MoGHub session UUID for community publishing + browsing	~/.mogen/moghub_auth.json
All three login flows use a loopback browser handshake — gemini-cli and antigravity go through Google's OAuth consent screen on a fixed loopback port (51121); moghub opens <server>/api/auth/desktop/start and waits for the redirect back. On Unix the resulting files are written with mode 0600.

flag	applies to	meaning
--force	every target's login	re-authenticate even if a valid token is already on disk.
--no-browser	gemini-cli, antigravity	print the authorize URL instead of opening a browser (useful over SSH).
--timeout <SECS>	gemini-cli, antigravity	how long to wait for the OAuth callback. Clamped to [10, 3600]. Default 300.
--server <URL>	moghub	sign in against a self-hosted MoGHub instance. The URL round-trips into the on-disk session.
--verbose	every target's status	extra detail — token-store path, OAuth scopes, the chosen cloudcode-pa endpoint, and (for moghub) a live whoami round-trip.
shmogen auth gemini-cli login                         # zero-config, opens browser
mogen auth antigravity login                        # required for OAuth-driven `mogen textures`
mogen auth moghub login --server https://staging.moghub.org

mogen auth status --verbose                         # show every target with full detail
mogen auth gemini-cli logout                        # scope sign-out per target
mogen generate / modify / animate / repair automatically use the gemini-cli OAuth bundle whenever GEMINI_API_KEY is unset; mogen textures prefers the antigravity bundle when present (set MOGEN_IMAGE_PROVIDER=antigravity to force it). The MoGHub session file is shared with Studio, so signing in once via the CLI surfaces the session in the desktop's Community window and vice versa.

logout walks every legacy path (~/.cache/mogen/, %LOCALAPPDATA%\mogen\) so a half-cleaned upgrade can't silently re-authenticate. None of the logout commands call the upstream revoke endpoint — refresh tokens stay valid server-side until the user explicitly revokes consent at https://myaccount.google.com or signs out of MoGHub on the web.

#build
Compile a DSL file to a GLB.

shmogen build <input.mog> [--out <output.glb>]
flag	meaning
--out, -o	Output GLB path. Defaults to <input>.glb alongside the source file.
Pipeline. build runs the canonical front-to-back pipeline:

Parse the DSL (pest grammar).
AST validation — referential and typing errors with source spans.
Lower to SceneGraph — module expansion, placement shortcuts, attach solver, animation/skinning lowering.
Graph validation — topological invariants (skeleton ancestry, weight sums, …).
Export GLB — PBR materials, embedded textures, animation channels, optional skin data, optional sibling-mesh merge.
generate, modify, animate, repair, and textures all converge on this command at the end of their flows. If you've already authored a .mog, build is what you run.

shmogen build examples/chair.mog --out chair.glb
#parse
Parse a DSL file and print the AST. Useful when debugging grammar errors or checking how a tricky source string lowers.

shmogen parse <input.mog>
No GLB is produced. Lowering and validation are skipped.

#check
Validate a DSL file. Exits non-zero on any error.

shmogen check <input.mog> [--json]
flag	meaning
--json	Emit diagnostics as line-delimited JSON instead of human-readable carets.
Validation is dual: AST-level (typing, references, unknown attributes) and graph-level (topology, weights, skeleton roots). The two phases produce a unified diagnostic list. Human mode renders via codespan-reporting; JSON mode emits one diagnostic per line in the format the LLM repair loop consumes.

shmogen check examples/chair.mog                          # human-readable
mogen check examples/chair.mog --json | jq .            # machine-readable
#dump-scene
Lower a DSL file and print the resulting scene graph. Useful for inspecting what an LLM actually emitted, or for diffing two .mog files post-lowering.

shmogen dump-scene <input.mog> [--json]
flag	meaning
--json	Emit the graph as JSON instead of an indented summary.
#inspect
Read a GLB and print its top-level structure: scenes, meshes, materials, animations, skins, extensions, embedded image sizes.

shmogen inspect <output.glb>
The same machinery that powers MoGen Studio's "GLB summary" panel; useful for verifying what actually landed in a release artifact.

#generate
Generate a .mog from a natural-language prompt via Gemini, validate it, repair JSON diagnostics in a loop, then compile it to a GLB.

shmogen generate "<prompt>" [--out <out.glb>] [--dsl-out <out.mog>] [common LLM flags]
flag	meaning
--out, -o	Output GLB path. Ignored with --dry-run.
--dsl-out	Where to stash the generated DSL. Defaults to the sibling of --out with a .mog extension. Required with --dry-run if you want to keep the DSL on disk.
--seed	Embedded seed; randomised if omitted.
--model	Gemini model id. Default gemini-pro-latest.
--dry-run	Print the generated DSL but skip compilation and GLB output.
Plus all common LLM flags above.	
Repair loop. If the generated DSL fails validation, generate re-feeds the JSON diagnostics back to Gemini up to --max-repair-iters times. On the final failure it prints the unfixed diagnostics and exits non-zero, leaving the broken .mog on disk for inspection.

shmogen generate "a wooden stool" --out stool.glb
mogen generate "a clockwork dragon" --thinking xhigh --out dragon.glb
mogen generate "a cube" --thinking low --dry-run                  # no API cost beyond one fast call
#modify
Apply a natural-language edit to an existing .mog, then revalidate and recompile. The model receives the full DSL and your prompt; the response replaces the file in place (or writes to --dsl-out).

shmogen modify <input.mog> "<prompt>" [common LLM flags]
flag	meaning
--out, -o	Output GLB path. Defaults to <input>.glb.
--dsl-out	Where to write the modified DSL. Defaults to modifying input in place.
--seed	Defaults to the seed in the input's header, else random.
Plus all common LLM flags.	
The seed embedded in the input header is preserved across edits unless you override it explicitly. That makes modify reproducible for a given prompt + seed pair.

shmogen modify examples/chair.mog "make the legs taller"
mogen modify examples/chair.mog "add armrests" --dsl-out chair_armed.mog --dry-run
#animate
Same shape as modify, but the LLM is restricted to animation top-level declarations — joint, clip / track, and the procedural templates (spin, open_close, wave, flap, idle). Geometry, materials, and hierarchy are guaranteed not to change.

shmogen animate <input.mog> "<prompt>" [common LLM flags]
shmogen animate examples/drone.mog "spin every rotor at 120 rpm"
mogen animate examples/door.mog "make the door swing open over 1.2 seconds"
The flag set matches modify (--out, --dsl-out, --seed, and the common LLM flags). Use this when you want the model focused on motion and not tempted to reshape the scene.

#repair
Run the validator against an existing .mog and ask Gemini to fix every diagnostic — with the source excerpt, caret, and fix hint passed in. If the file already validates, repair is a no-op success.

shmogen repair <input.mog> [--no-build] [common LLM flags]
flag	meaning
--out, -o	Output GLB path. Defaults to <input>.glb.
--dsl-out	Where to write the repaired DSL. Defaults to in-place.
--no-build	Stop after rewriting the .mog; don't compile the GLB.
Plus all common LLM flags.	
Use repair after editing a .mog by hand and breaking validation, or after pasting in a snippet from somewhere else. It's the same machinery the generate / modify / animate repair loops use, exposed as a top-level command.

#textures
Generate PBR textures for every material in a .mog. The albedo is LLM-drawn via Gemini 2.5 Flash Image, then locally derived normal, metallic-roughness, and occlusion maps are computed from the albedo (Sobel-from-luminance, variance-based, cavity-based). PNGs are written next to the .mog and the matching *_texture="…" attrs are spliced back into the source via spans (no reformatting).

shmogen textures <input.mog> [--style "<hint>"] [--texture-size <N>]
flag	meaning
--out	Where to write the modified .mog. Defaults to in-place.
--glb	GLB output path. Defaults to <input>.glb.
--textures-dir	Where PNGs are written. Defaults to textures/<mog-stem>/ so sibling assets don't collide on shared material names.
--style	Style hint appended to each image prompt. Default photorealistic.
--model	Gemini image model id. Default depends on credentials: gemini-3-pro-image-preview when authenticated via OAuth, otherwise gemini-2.5-flash-image. Pass gemini-3.1-flash-image-preview (or any other image model) to override.
--force	Regenerate slots whose attr is already declared in the .mog or whose PNG already exists at the planned path.
--dry-run	Print the plan and skip all API calls and file writes.
--no-build	Stop after rewriting the .mog; don't run build.
--no-pbr	Skip every derived PBR map (normal / MR / AO). Albedo is still generated.
--no-normal / --no-metallic-roughness / --no-occlusion	Skip a specific derived map.
--texture-size <N>	Cap (in pixels) on the longer side of every generated albedo. Derived PBR maps inherit this size — the single lever for embedded-texture footprint. 0 keeps the model's native resolution (typically 1024²).
--api-key	Override GEMINI_API_KEY.
Idempotency. Per slot, materials that already declare a given *_texture attr — or whose target PNG already exists at the planned path — are skipped unless --force is passed. Existing on-disk PNGs still get their *_texture attr spliced into the source, just without an API call or a local re-derivation.

shmogen textures examples/chair.mog --style "weathered oak"
mogen textures examples/drone.mog --no-occlusion --texture-size 512
mogen textures examples/chair.mog --dry-run                          # see the plan first
#bench
Run a suite of prompts through generate and report success rate and mean token cost. Does not write GLBs.

shmogen bench [--prompts <file>] [common LLM flags]
flag	meaning
--prompts	File with one prompt per line. # starts a comment. Defaults to benches/prompts.txt.
--model	Gemini model id. Default gemini-pro-latest.
--max-repair-iters	Default 2.
--budget-tokens	Per-prompt token cap.
--api-key	Override GEMINI_API_KEY.
--no-cache	Disable the system-instruction cache.
--thinking	Default high.
Used as a regression gate during development — the project targets ≥ 80% success rate on the bundled prompt suite.

#moghub
Browse, download, like, comment on, and publish to MoGHub — the same community surface MoGen Studio's Community window exposes, driven from the terminal. Authentication reads ~/.mogen/moghub_auth.json written by mogen auth moghub login; read-only verbs (discover, info, download, comments) work without a session. The base URL is taken from the auth file (or --server); production defaults to https://moghub.org.

Models are addressed by a <user>/<slug> reference (the leading @ is optional), e.g. krazyjakee/parametric-chair or @krazyjakee/parametric-chair.

Every verb accepts --server <URL> to target a self-hosted MoGHub instance instead of the URL stored in the on-disk session.

shmogen moghub whoami                          # confirm the active session
mogen moghub discover --query chair --kind model --tag furniture
mogen moghub info     @user/cool-stool
mogen moghub download @user/cool-stool --version 3 --out stool/
mogen moghub like     @user/cool-stool
mogen moghub comment  @user/cool-stool "great topology!"
mogen moghub publish  examples/chair.mog --title "Parametric chair" --tags "chair,furniture"
#moghub whoami
Print the signed-in user's handle and id. Exits non-zero with the message anonymous if no session is active.

#moghub discover
Walk the public discover feed.

flag	meaning
--query, -q	Free-text search.
--kind	Filter by kind: scene, model, module, or all.
--tag	Filter by a single tag.
--limit / --offset	Pagination.
--json	Emit the raw API response as JSON instead of the columnar summary.
The default human view prints one line per result: @user/slug title [kind] ♥like_count #tag1 #tag2. A featured pick, when the API returns one, is shown first prefixed with ★.

#moghub info
Print full detail for a model: kind, license, like + fork counts, the latest version number, description, tags, and the file list (the entry .mog is marked with →).

shmogen moghub info @user/cool-stool
mogen moghub info @user/cool-stool --json
#moghub download
Fetch a model's .mog files into a directory. Defaults to the latest version; pass --version <N> to pin one.

flag	meaning
--version <N>	Pin a specific version instead of the latest.
--out, -o	Destination directory. Defaults to <slug>-v<version> in the working directory.
--entry-only	Only fetch the entry .mog; skip imports and the thumbnail.
The thumbnail (thumbnail.png) is downloaded best-effort alongside the .mog files unless --entry-only is set; versions that were never thumbnailed silently skip it.

#moghub comments
List comments on a model. Soft-deleted comments are hidden. Body content can include MoGHub bbcode and is printed verbatim.

#moghub comment
Post a comment. Requires login. Body accepts MoGHub bbcode.

shmogen moghub comment @user/cool-stool "great topology!"
#moghub like / moghub unlike
Toggle a like on a model. Both verbs are idempotent and print the new liked= / total= state. Requires login.

#moghub notifications
List the signed-in user's notifications, newest first. Each line is prefixed with • for unread or a space for read entries. Pass --mark-read to mark every notification as read instead of just listing.

#moghub publish
Publish a .mog to MoGHub. Bundles the entry .mog plus every locally-imported .mog and every referenced PNG / JPG / JPEG / WebP texture into a single submission. Requires login.

shmogen moghub publish <input.mog> [flags]
flag	meaning
--title	Override meta(name=…) for this publish. Required if the source has no meta(name=…).
--description	Override meta(description=…).
--tags "a,b,c"	Comma-separated tag list. Lowercased and capped at 8. Overrides meta(tags=[…]).
--license	SPDX-style license id. Defaults to CC0-1.0.
--visibility	public, unlisted, or private. Defaults to public.
--message, -m	Version changelog message.
--thumbnail	Path to a PNG to attach as the model thumbnail.
--filename	Override the published filename. Defaults to the input file's basename.
--module	Publish as a registry-importable module. Mutually exclusive with --scene.
--scene	Publish as a scene. Mutually exclusive with --module.
--new	Force creation of a new model even if the source carries a prior MoGHub stamp.
--server	Target a self-hosted MoGHub instance.
Defaults from meta(...). When --title, --description, or --tags are omitted, publish reads the corresponding key from the source's top-level meta(...) block. Any locally-imported .mog (via use "file.mog") is bundled automatically; their filenames must not collide with the entry filename.

Scene vs. module. If neither --module nor --scene is passed, the source is published as a module when it has no import declarations and as a scene when it does. Pass an explicit flag to override.

Updates round-trip. On success, publish writes three keys back into the source's meta(...) block:

mogmeta (
  ...
  moghub_model_id = "…",
  moghub_slug     = "…",
  moghub_version  = "2",
)
Subsequent moghub publish runs read those keys and append a new version (moghub_version + 1) to the same model. Pass --new to ignore the stamp and create a fresh model instead.

Texture bundling. Every string attribute that ends in .png, .jpg, .jpeg, or .webp is resolved relative to the .mog it appears in (entry or import) and uploaded. All texture paths must resolve inside the entry's directory — references that point to a parent directory are rejected so the upload bundle stays self-contained.

shmogen moghub publish examples/chair.mog --title "Parametric chair" --tags "chair,furniture"
mogen moghub publish examples/chair.mog -m "added armrests"          # appends a new version
mogen moghub publish examples/chair.mog --new --visibility unlisted  # forks off a fresh model
#mcp
Run mogen as an MCP (Model Context Protocol) server over stdio. Every other CLI subcommand is exposed as a tool the connected LLM client can invoke, so an MCP-aware client can drive the full mogen pipeline — compile, validate, inspect, generate, publish — without shelling out manually.

shmogen mcp
Speaks JSON-RPC on stdin/stdout — don't run it interactively. Launch it from an MCP client (Claude Desktop, a custom client, etc.). Tracing logs are routed to stderr so they never corrupt the protocol stream; set RUST_LOG to tune verbosity (defaults to warn).

How it works. Each tool call spawns the same mogen binary as a subprocess with the equivalent CLI arguments, captures stdout and stderr, and returns them as the tool result. Behaviour is identical to running the command from a terminal — same auth files (~/.mogen/…), same env vars (GEMINI_API_KEY, MOGEN_CACHE_DIR, …), same exit semantics. Non-zero exits surface as MCP tool errors with stderr bundled in so the calling LLM can repair from the diagnostics.

Paths are server-relative. Every <input.mog> / --out path passed to a tool is resolved against the working directory mogen mcp was launched from, not the LLM client's notion of cwd. Configure your MCP client to launch the server in the project directory you want it to operate on.

Tool catalog. Tool names mirror the CLI subcommands with hyphens replaced by underscores (e.g. dump-scene → dump_scene); MoGHub verbs are prefixed with moghub_ (moghub_whoami, moghub_discover, moghub_info, moghub_download, moghub_comments, moghub_comment, moghub_like, moghub_unlike, moghub_notifications, moghub_publish). The full set: build, parse, check, dump_scene, inspect, thumbnail, generate, modify, animate, repair, textures, update, bench, plus the moghub_* family.

Example Claude Desktop config entry:

json{
  "mcpServers": {
    "mogen": {
      "command": "mogen",
      "args": ["mcp"]
    }
  }
}
#Environment variables
variable	meaning
GEMINI_API_KEY	Required by generate / modify / animate / repair / textures / bench unless --api-key is passed.
MOGEN_CACHE_DIR	Where the system-instruction cache is stored. Defaults to $HOME/.cache/mogen/.
MOGEN_GOLDENS_UPDATE	When set during tests, regenerates the golden snapshots used by the validator and exporter test suites.
MOGEN_GLTF_VALIDATOR	Path to an external glTF validator binary. When set, the build pipeline runs the output GLB through it as an additional smoke check.
#Exit codes
code	meaning
0	success
non-zero	validation, parse, IO, or remote-API error — diagnostic written to stderr
check --json and the LLM repair loop emit machine-readable diagnostics; everything else uses human-readable formatting via codespan-reporting.
------------------------------------------------------
Module catalog
How `module` and `use` work, plus the stdlib module catalog (humanoid, animals, foliage).

Modules are parametric sub-graphs: reusable snippets of DSL that take scalar parameters, expand to a tree of primitives, and can expose connectors for downstream composition. The full language is documented in dsl.md; this page is a catalog of the modules shipped in the stdlib and a recipe for adding more.

How modules resolve
Authoring a new module
Stdlib catalog
Humanoid — body, head, limbs, hands, feet, face, hair
Humanoid animations — idle, walk, run, jump
Animals — quadruped torso/leg, tail, ear, eye
Foliage — leaf, branch
#How modules resolve
Given a call use "leg" (height=0.5):

Look up "leg" in the module registry — a flat map populated from three sources, in this precedence order: **user declarations > imports
stdlib**. A user module "leg" { … } shadows any imported leg, and an imported leg shadows the stdlib's leg.

Bind caller arguments (height=0.5) against the declared parameter list. Unknown argument names are a hard error (catches typos).
Fill declared defaults for any parameter the caller omitted.
Expand the module body, substituting every $name with its bound numeric value. vec3, list, string, or ident defaults are not accepted — every parameter is scalar.
Recurse: module bodies may themselves call use, up to a recursion- depth check that prevents accidental loops.
Expansion happens before the scene graph is built — by the time lowering runs, every $name has been replaced and every use node has been replaced with its expanded body. See dsl.md §Modules and §Imports for the full resolution rules.

#Authoring a new module
Three rules cover almost everything:

All parameters are scalars. Numeric defaults are required (height=0.5, count=4); vec3 / list / string / ident defaults are rejected. If you want a positioned pose, pass the three components as separate scalars.

Reference parameters as $name inside the body. They compose into expressions in any numeric attribute position — pos=[0, $h * 0.5, 0], radius=$r, height=$h + 0.1, and so on.

Expose connectors where the caller will join you. A leg that the seat attaches on top of should emit connector "top" (...) inside its mesh node. Tagging them (tag=leg_top) lets downstream fitting logic pair compatible anchors without hard-coded positions.

Stdlib modules also include a // summary: <one-liner> comment on the first line. The CLI's stdlib index reads this to inject a single-line doc for each module into LLM prompts, so write a description that says what the module is and what its connectors are called — the LLM consumes it verbatim.

A skeleton:

// summary: A box-shaped part with top/bottom connectors. Caller declares mat=part.
module "my_part" (width=1.0, height=1.0, depth=1.0) {
  box "body" (size=[$width, $height, $depth]) {
    connector "top"    (at=[0,  $height * 0.5, 0], dir=[0,  1, 0], tag=part_top)
    connector "bottom" (at=[0, -$height * 0.5, 0], dir=[0, -1, 0], tag=part_bottom)
  }
}
Drop the file in crates/mogen-dsl/stdlib/<name>.mog and add an entry to the STDLIB_FILES table in crates/mogen-dsl/src/stdlib.rs. The all_stdlib_modules_parse_and_load test enforces that every entry parses and carries a // summary: line; each_stdlib_module_lowers_in_isolation checks that defaults produce a valid scene graph.

#Stdlib catalog
Every module below lives at crates/mogen-dsl/stdlib/<name>.mog and is registered in stdlib.rs. All stdlib content is shadowed by user declarations and imports, so a project can override any module by re-declaring it in the importing file.

#Humanoid
Modular body parts that compose into a full character. Most accept a single size/length/radius knob and a few independent tuning params. The full body is humanoid_full; the others are useful for composing a custom rig from a subset of parts.

#humanoid_full
Complete rigged humanoid in one declaration — torso, head, arms, hands, legs, feet, face, attached and skinned to a "rig" skeleton.

parameter	default	meaning
height	1.7	overall height in meters
Caller declares materials: skin, cloth, eye, mouth, boot. Hair is not bundled — use "humanoid_hair_short" (or humanoid_hair_long) and attach to the head's crown socket if the figure needs hair. Use only once per scene since it owns the global "rig" skeleton; pair with one of the humanoid animation modules below.

#humanoid_torso
Soft superellipsoid torso with neck, shoulder, and hip sockets.

parameter	default	meaning
height	0.55	torso length along +Y
width	0.36	extent along +X
depth	0.22	extent along +Z
Connectors: neck, shoulder_l, shoulder_r, hip_l, hip_r. Shoulders point in an A-pose direction (20° outward from straight-down) so attached arms hang in a natural rest pose.

#humanoid_head
Smooth-blended cranium + jaw with a face-and-ears connector cluster.

parameter	default	meaning
size	0.11	head radius (m)
jaw	0.7	jaw fullness fraction (0 = no jaw, 1 = matching cranium)
Connectors: neck (under), crown (top, hair anchor), eye_l, eye_r, nose, mouth, ear_l, ear_r.

#humanoid_arm
Upper-arm + forearm capsules smoothly joined at the elbow.

parameter	default	meaning
length	0.55	total arm length
radius	0.05	upper-arm cross-section radius (forearm tapers to 0.85×)
Connectors: shoulder (top), wrist (bottom).

#humanoid_leg
Thigh + shin capsules smoothly joined at the knee.

parameter	default	meaning
length	0.9	total leg length
radius	0.07	thigh cross-section radius
Connectors: hip (top), ankle (bottom).

#humanoid_hand_5fingers
Five-fingered left hand. Mirror with mirror axis=x to get a right hand. Wrist plug at +Y, fingers extending in -Y.

parameter	default	meaning
size	0.09	hand width (drives finger / palm scale)
Connectors: wrist (attach to arm), grip (anchor for held props).

#humanoid_foot
Sole + toe block smoothly blended into a boot-shaped form.

parameter	default	meaning
length	0.26	foot length along +Z
width	0.10	foot width
height	0.10	foot height
Connectors: ankle (top), toe (front tip), heel (back). Caller declares material boot (or sets mat= on the wrapping group).

#humanoid_face
Face cluster — eye_l, eye_r, nose, mouth as separate top-level nodes. Attach each to its matching connector on humanoid_head.

parameter	default	meaning
size	0.11	head reference size; drives feature scale
Caller declares materials eye, skin, mouth.

#humanoid_hair_short
Skullcap with substantial occiput / nape bulk. Sits on the head's crown socket.

parameter	default	meaning
size	0.115	hair-cap radius
Caller declares material hair.

#humanoid_hair_long
Skullcap + back-falling drape past the shoulders.

parameter	default	meaning
size	0.115	cap radius
length	0.45	drape length
Caller declares material hair.

#Humanoid animations
Each one expands into a single clip { track … } that drives bones on the "rig" skeleton declared by humanoid_full. They take no parameters because every track is hand-tuned. Pair one with humanoid_full (or any rig that uses the same bone names).

module	duration	shape
humanoid_idle	4.0 s loop	subtle breathing + weight-shift, very small amplitudes
humanoid_walk	1.0 s loop	hip swing, opposite-arm shoulder swing, mid-swing knee lift, subtle spine counter-rotation
humanoid_run	0.55 s loop	bigger amplitudes than walk, elbows held at 90° flex
humanoid_jump	1.2 s one-shot	crouch → extend → airborne tuck → land (does not loop)
Use exactly one humanoid animation per scene — they all author a clip named after themselves driving the same bones, so combining two is a recipe for fighting tracks.

#Animals
#quadruped_torso
Elongated soft body with head, tail, and four leg sockets.

parameter	default	meaning
length	0.9	body length along +Z
height	0.32	body height
width	0.30	body width
Connectors: neck (front), tail (back), leg_fl, leg_fr, leg_bl, leg_br (four hip anchors).

#quadruped_leg
Single capsule from hip to paw.

parameter	default	meaning
length	0.45	leg length
radius	0.045	cross-section radius
Connectors: top (tagged hip), paw (bottom).

#tail
Tapered tail (~0.4 m, base radius ~0.04 m) using spline_tube curving down then up. Wrap in a group and apply scale= / rot= to resize.

No parameters. Connector: base at the trunk end.

#ear
Curved-plane animal ear (triangular pinna).

parameter	default	meaning
size	0.06	ear extent (m)
Connector: base at the head-side edge.

#eye
Spherical eyeball.

parameter	default	meaning
radius	0.022	eyeball radius
Connector: back at the socket-facing pole.

#Foliage
#leaf
Curved-plane leaf with a slight cup along its length. Set the leaf material's double_sided=1.

parameter	default	meaning
length	0.12	leaf length along +Y
width	0.05	leaf width along +X
Connector: stem at the leaf's base.

#branch
Tapered single branch (~0.6 m, base 0.04 m → tip 0.008 m) with a gentle S-curve. Wrap in a group plus scale= / rot= to compose trees, antlers, vines, and root systems.

No parameters. Connectors: base (trunk end), tip.

For a fully procedural recursive tree (multiple levels of splits and auto-emitted leaves), use the branch primitive instead — see dsl.md §Branch.
---------------------------------------------------
MoGen Studio
The desktop GUI: editor, viewer, gizmos, inspector, diagnostics, LLM tools, themes.

A desktop editor for .mog scenes. Studio is a thin GUI on top of the same compile pipeline the CLI uses — every feature you can run from mogen <subcommand> is also available as a button or menu item. It adds a live 3D preview, a span-aware inspector, viewport gizmos, syntax highlighting, and a settings store so per-project knobs stick across sessions.

Window title is MoGen Studio. Settings live at ~/.config/mogen/settings.json on Linux (%APPDATA%\mogen\settings.json on Windows; ~/Library/Application Support/mogen/settings.json on macOS).

Launching
The window at a glance
Tabs and recent files
The editor pane
The 3D viewer
The inspector
Diagnostics
Building
LLM tools — generate, modify, animate, repair, textures
Themes and preview shaders
Settings
Keyboard shortcuts
File layout on disk
#Launching
shcargo run --release -p mogen-studio          # from a source checkout

# Or from a release artifact:
mogen-studio                                 # Linux tarball
open "/Applications/MoGen Studio.app"        # macOS .dmg
# On Windows: launch from the Start menu after running the .msi installer.
On first launch, Studio shows an onboarding dialog asking for a Gemini API key. You can skip it — every non-LLM feature still works without one — or paste a key in. The key is stored in the settings file and is the same value GEMINI_API_KEY would supply to the CLI.

#The window at a glance
Studio's main view is a four-region layout:

region	what it does
menu bar	File / Edit / View / Generate / Options / Help, plus the active-tab strip just below
editor pane	.mog source with live syntax highlighting, autocomplete, error squiggles, and a per-file diagnostics footer
3D viewer	Live preview of the most recently built .mog, with translate/rotate/scale gizmos and click-to-select picking
inspector	Selected-node attribute editor, material editor, texture roster, and per-file build options
The editor and viewer are separated by a draggable splitter; the inspector is a collapsible side panel.

#Tabs and recent files
Multiple .mog files can be open simultaneously, one per tab.

The tab strip remembers order across sessions — closing Studio with three tabs open reopens all three on the next launch, with the last active tab focused.
Untitled buffers (no path yet) are not persisted across restarts, but they survive accidental re-runs of Studio because every change is held in memory.
File → Open Recent shows the last 12 opened paths, newest first. Items are removed automatically if the file no longer exists at that path.
Save / Save As use a native file dialog. New tabs default to "Untitled" and prompt for a path on first save.
#The editor pane
The editor is a custom egui-based text view tuned for .mog. It does NOT use a pest-driven highlighter on every keystroke — instead, a loose tokeniser in highlight.rs colours kinds, strings, numbers, comments, and $param references, so mid-edit source still highlights even when the parser would reject it.

Features:

Syntax highlighting — kinds, attributes, strings, numbers, comments, $param references.
Autocomplete — typing a kind, attribute, or material name pops a fuzzy list. Tab / Enter accepts; Esc cancels; ↑/↓ moves the selection.
Indent on enter — opening a { block bumps the indent; closing brace de-indents in place.
Error squiggles — every diagnostic from the AST or graph validator gets an underline at the exact span the validator emitted. Hover for the message.
Find — Ctrl+F / ⌘F opens a find bar.
External-edit detection — if the file changes on disk while a tab is open, Studio prompts to reload (or keep your in-memory copy if you have unsaved changes).
#The 3D viewer
A live preview built on eframe's wgpu backend. Loaded directly from the in-memory SceneGraph after each successful build — there's no intermediate GLB on disk for the preview.

Camera:

Left-drag orbits the focus point.
Middle-drag (or Shift+left-drag) pans.
Mouse wheel zooms.
⌘0 / Ctrl+0 frames the whole scene.
Selection:

Left-click picks the node under the cursor (Möller–Trumbore ray cast against the rendered meshes). The selected node highlights both in the viewer and in the inspector.
Esc clears the selection.
Gizmos:

When a node is selected, a translate / rotate / scale gizmo handle floats over its origin in world space. The mode toggles in the View menu (or the gizmo widget itself).
Dragging a handle modifies pos / rot / scale on the selected node and writes the change back into the source .mog as a span-preserving edit. Other formatting in the file is left alone.
#The inspector
The inspector binds the currently selected node to its attributes:

Per-attribute fields — drag-numeric inputs, vec3 spinners, colour pickers for material colours, dropdowns for enum-like attrs (anchor, axis, alpha_mode).
Material editor — every authored material gets a collapsing section. Edit base color, roughness, metallic, alpha mode, transmission, emissive, etc.; changes flow back to the source material "…" declaration via the same span-preserving edit machinery.
Texture roster — each material's texture slots show ✓ / ✗ markers based on whether the referenced PNG actually exists at the resolved path. Missing textures are visible before you try to build.
LOD scale slider — edits the top-level lod_scale (value=N) directive in place. Drag down to iterate quickly on big scenes; drag back to 1.0 and Studio removes the directive entirely so saved files stay clean.
Per-file export options — include_animations, include_textures, merge_sibling_meshes (sticky per file).
Edits made in the inspector and via gizmos are persisted into the source file the next time you save. They are reflected in the editor text immediately, and they preserve every comment, blank line, and whitespace style elsewhere in the source.

#Diagnostics
Every build runs the same dual validator the CLI uses (AST-level + graph-level). The diagnostics show up in three places:

Error squiggles in the editor at the exact source span.
Diagnostics footer under the editor — collapsible; auto-hides when there are no errors or warnings.
Tab badges — a tab with errors gets a red dot; a tab with only info-level diagnostics looks clean.
mogen check --json and the studio share the same diagnostic format — the studio is a viewer for that JSON, dressed up as a UI.

#Building
The Build button (or ⌘B / Ctrl+B) compiles the current tab to GLB and refreshes the 3D viewer. The output GLB lands at <file>.glb next to the source by default.

The build pipeline is the same one mogen build runs:

Parse → AST → AST validation
Lower → SceneGraph
Graph validation
Optional sibling-mesh merge (per-file merge_sibling_meshes setting)
GLB export
Validation errors abort the build and surface in the diagnostics footer without writing a GLB.

F5 re-runs the validator only, without re-emitting a GLB. Useful when you've edited a .mog from outside Studio and want a quick diagnostic refresh.

#LLM tools
The Generate menu mirrors the LLM-driven CLI subcommands. Each opens a small modal that collects a prompt and the relevant flags.

menu item	CLI equivalent
New from prompt… (⌘⇧N)	mogen generate
Modify…	mogen modify
Animate…	mogen animate
Repair	mogen repair
Generate textures…	mogen textures
Behaviour matches the CLI:

The repair loop runs in the background; progress is shown in the status line.
The generated .mog opens in a new tab (Generate) or replaces the current tab's contents (Modify / Animate / Repair).
Seeds are embedded in the DSL header so the same prompt + same seed re-emits the same scene. The seed field in each modal is pre-filled with the input file's existing seed when present.
Thinking level, model, temperature, and max_repair_iters come from Options → Models. Per-modal overrides live next to the prompt field for one-off tuning.
If gemini_api_key is empty in the settings, every LLM action prompts for a key first (the same onboarding dialog as on first launch).

#Themes and preview shaders
UI themes (Options → Theme):

key	label	use
dark	Dark	classic dark editor
light	Light	bright office mode
sunset	Sunset (warm)	warm-toned
nord	Nord (cool)	cool-toned blue/grey — default
high-contrast	High Contrast	accessibility / projector
The theme name is stored in settings.json as a lowercase label so new variants can land without breaking older settings files. Empty / unknown labels fall back to Nord.

Preview shaders (View → Preview shader) control the 3D viewer only — they don't affect the exported GLB.

key	label	what it shows
standard	Standard (PBR)	full PBR with embedded textures — default
toon	Toon (cel-shaded)	hard-shaded NPR look
crt	CRT (scanlines)	post-process scanlines + bloom
matcap	Matcap (clay)	unlit material capture for sculpt-style review
wireframe	Wireframe	edges only, ignores materials
Wireframe is useful for inspecting topology after CSG or sibling-mesh merge. CRT is for vibes.

#Settings
The settings file is a JSON document stored at the OS-appropriate config path. It's safe to edit by hand — Studio reloads on next launch.

key	meaning
gemini_api_key	API key used by every LLM action.
gemini_model	Heavy model id. Empty → gemini-pro-latest.
gemini_fast_model	Fast model id used for low-stakes rewrites (Prompt Enhancer). Empty → gemini-flash-latest.
gemini_temperature	Sampling temperature. null → library default (0.3).
thinking_level	low / medium / high / xhigh. Empty → library default (high).
max_repair_iters	LLM repair budget. null → library default (2).
seed_override	Optional deterministic seed. null → derive from DSL header or random per call.
theme	UI theme key (see above).
preview_shader	Viewer shader key (see above).
last_opened	Absolute path of the last .mog opened.
open_tabs	Absolute paths of every titled tab open at last persist time.
recent_files	Most-recently-opened paths, newest first. Capped at 12.
onboarded	Set once the first-launch onboarding has been dismissed.
Untitled buffers are deliberately not persisted — there's nothing to key off — so a fresh Studio launch with only-untitled tabs comes up empty. Save first if you want them back.

#Keyboard shortcuts
COMMAND is ⌘ on macOS and Ctrl elsewhere. All shortcuts work globally; egui consumes them before the menu or editor see the key.

shortcut	action
⌘N	New untitled tab
⌘⇧N	New from prompt (Gemini generate)
⌘O	Open file…
⌘S	Save active tab
⌘⇧S	Save As…
⌘B	Build active tab to GLB
F5	Re-run the validator without re-emitting the GLB
⌘W	Close active tab
⌘0	Frame the scene in the 3D viewer
⌘,	Open Options
⌘Q	Quit (with prompt-to-save for dirty tabs)
Tab / Enter	Accept autocomplete suggestion
Esc	Dismiss autocomplete; clear viewer selection
Standard editing shortcuts (⌘C, ⌘X, ⌘V, ⌘A, ⌘Z, ⌘⇧Z) work in the editor pane.

#File layout on disk
For a given project directory, Studio expects (and creates) the following layout:

my-project/
├── chair.mog              # source
├── chair.glb              # build output (next to the .mog by default)
└── textures/
    └── chair/             # mogen textures --textures-dir default
        ├── wood_base_color.png
        ├── wood_normal.png
        ├── wood_metallic_roughness.png
        └── wood_occlusion.png
Texture paths in material "…" declarations are resolved relative to the .mog file. The textures/<mog-stem>/ subdirectory is the default output of mogen textures so sibling .mogs with shared material names don't clobber each other.