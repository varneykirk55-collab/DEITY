class_name FutureHooks
extends RefCounted
## Extension points. These features are intentionally not implemented yet.
##
## Human Incarnation Mode
##   The deity may later descend into a third-person human body and walk settlements.
##   Hook: spawn a player-controlled human, switch GodCamera to follow, disable tools.
##
## Direct Human Interaction
##   The deity may later speak with individuals, influence rulers, and reveal identity.
##   Hook: inspect panel grows a dialogue list; does not gate divine powers.

const INCARNATION_IMPLEMENTED := false
const DIRECT_INTERACTION_IMPLEMENTED := false


static func incarnation_available() -> bool:
	return INCARNATION_IMPLEMENTED


static func dialogue_available() -> bool:
	return DIRECT_INTERACTION_IMPLEMENTED
