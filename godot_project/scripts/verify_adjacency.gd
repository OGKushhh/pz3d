# verify_adjacency.gd — checks that adjacency-aware recipe picking works.
# Runs generate_map in-memory, then for each block, counts how many of its
# neighbors have the SAME recipe. Lower = better diversity.
extends SceneTree

const CityGenV2 = preload("res://tools/city_gen_v2.gd")

func _init():
	print("=== Adjacency Verification ===")
	var map = CityGenV2.generate_map(1337)
	var plans: Array = map.plans
	var adjacency: Dictionary = map.adjacency

	var total_neighbors: int = 0
	var same_recipe_pairs: int = 0
	var blocks_with_same_neighbor: int = 0

	for i in range(plans.size()):
		var recipe: String = plans[i].recipe
		var neighbors: Array = adjacency.get(i, [])
		if neighbors.is_empty():
			continue
		var same_in_block: int = 0
		for n in neighbors:
			if n < plans.size() and plans[n].recipe == recipe:
				same_in_block += 1
		total_neighbors += neighbors.size()
		same_recipe_pairs += same_in_block
		if same_in_block > 0:
			blocks_with_same_neighbor += 1

	var pct: float = 0.0
	if total_neighbors > 0:
		pct = float(same_recipe_pairs) / float(total_neighbors) * 100.0

	print("Total blocks: %d" % plans.size())
	print("Total neighbor pairs: %d" % total_neighbors)
	print("Same-recipe neighbor pairs: %d" % same_recipe_pairs)
	print("Blocks with >=1 same-recipe neighbor: %d/%d" % [blocks_with_same_neighbor, plans.size()])
	print("Same-recipe rate: %.1f%% (lower = better diversity)" % pct)
	print("")
	print("For comparison:")
	print("  - Random picking (4 recipes/district): expected ~25% same-recipe rate")
	print("  - Adjacency-aware picking: should be < 10%")
	quit()
