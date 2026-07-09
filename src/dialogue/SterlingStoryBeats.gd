extends RefCounted
class_name SterlingStoryBeats

## Mission Bible v2 - Sterling escalation beats + Act 1 Ellie setup.
##
## One-shot hideout dialogue sequences that fire on the first hideout visit
## after their trigger mission completes. Delivered through the existing
## DialogueManager.start_simple_dialogue path; each beat marks a dialogue
## flag so it never repeats. Beats play oldest-first, one per hideout visit.
##
## Beats:
##   ellie_setup            - after taco_bell_drop. Plants Bentley's lost Ellie
##                            so Elephant in the Room lands as a payoff.
##   sterling_rivals_welcome - after rewrite_room (Act 1 break). Sterling
##                            notices Parmida and welcomes his new "rival".
##   sterling_retaliation   - after fast_family_getaway (Act 2 midpoint).
##                            Sterling makes it personal and reveals he holds
##                            Ellie.

const _BEATS: Array = [
	{
		"flag": "story_beat_ellie_setup_seen",
		"required_mission": "taco_bell_drop",
		"lines": [
			{"speaker": "Jake", "text": "Bentley froze at the pet store window again today. The pink elephant plush. He didn't bark. He just... looked.", "portrait_id": "jake"},
			{"speaker": "Bentley", "text": "Bark translation: I am not thinking about Ellie. I have not thought about Ellie in years. Please stop looking at me.", "portrait_id": "bentley"},
			{"speaker": "Parmida", "text": "He had a friend once. Ellie. She was lost a long time ago. We don't talk about it - but he still checks every storage window we pass.", "portrait_id": "parmida"},
		],
	},
	{
		"flag": "story_beat_sterling_rivals_welcome_seen",
		"required_mission": "rewrite_room",
		"lines": [
			{"speaker": "Louis", "text": "Boss. This came through my route. No sender, heavy paper, smells like money and menace. I did NOT sign for it.", "portrait_id": "louis"},
			{"speaker": "", "text": "The note reads: \"To the new operator. Three of my holdings in one month - the routes, the club, the firm. Bold. I admire ambition; I collect it. Welcome to the game. - V.S.\"", "portrait_id": "fallback"},
			{"speaker": "Parmida", "text": "...He thinks I'm a rival crime lord. A real one. This is the nicest thing anyone has ever accused me of.", "portrait_id": "parmida"},
			{"speaker": "Jake", "text": "Parmida. The man who steals people's life's work thinks you're competition. That is not a compliment. That is a targeting system.", "portrait_id": "jake"},
			{"speaker": "Bentley", "text": "Bark translation: the paper smells of cold rooms and old lies. This man keeps a list. I keep a better one.", "portrait_id": "bentley"},
		],
	},
	{
		"flag": "story_beat_sterling_retaliation_seen",
		"required_mission": "fast_family_getaway",
		"lines": [
			{"speaker": "Jake", "text": "Someone was here. Nothing's missing - that's what scares me. They wanted us to know they could walk right in.", "portrait_id": "jake"},
			{"speaker": "", "text": "On the planning table: a photograph of a storage unit. In it, on a cold metal shelf, a faded pink elephant. On the back, one line: \"Everything can be collected. - V.S.\"", "portrait_id": "fallback"},
			{"speaker": "Bentley", "text": "Bentley goes completely silent. Not tactical-silent. Silent.", "portrait_id": "bentley"},
			{"speaker": "Parmida", "text": "Ellie. He has Ellie. Okay. This stopped being about the title a while ago - but now it's personal. We're taking everything back. Starting with her.", "portrait_id": "parmida"},
		],
	},
]

## Returns the oldest unseen beat whose trigger mission is complete, or {}.
static func get_pending_beat(game_state: Node) -> Dictionary:
	if game_state == null:
		return {}
	for beat in _BEATS:
		var beat_dict: Dictionary = beat
		var flag := String(beat_dict.get("flag", ""))
		if bool(game_state.dialogue_flags.get(flag, false)):
			continue
		var required := String(beat_dict.get("required_mission", ""))
		if required != "" and not game_state.completed_missions.has(required):
			continue
		return beat_dict
	return {}

## Marks a beat as seen so it never replays.
static func mark_beat_seen(game_state: Node, beat: Dictionary) -> void:
	if game_state == null or beat.is_empty():
		return
	var flag := String(beat.get("flag", ""))
	if flag != "":
		game_state.dialogue_flags[flag] = true
