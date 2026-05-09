extends RefCounted
class_name HideoutCharacterDialogueBank

## Phase 0M-C3 - Funny/clever/heartfelt birthday dialogue for the hideout's
## four anchor characters: Jake, Parmida (a.k.a. Mere), Bentley, and Louis.
##
## Each line is a Dictionary in the shape DialogueManager expects:
##   { "speaker": "Jake", "text": "...", "portrait_id": "jake" }
##
## Speaker_ids "parmida" and "mere" are aliased - both refer to the same
## character. The bank exposes both keys for callers that already use either.
##
## The lines are written specifically for this birthday-build:
##   Jake          - overworked resident, tired, forgetful, sweet tooth, adores
##                   Parmida, always forgets the poop bags, building everything
##                   out of love and panic.
##   Parmida/Mere  - kind, compassionate, intelligent, gently teasing, soft
##                   strength, notices Jake's effort, loves Bentley, birthday
##                   warmth.
##   Bentley       - black Shiba Inu, loyal, self-centered, dramatic, kid-like
##                   adoration of Mom (Parmida), professionally disappointed
##                   in Jake's poop-bag failures, suspicious of Louis.
##   Louis         - goofy delivery wisdom, absurd confidence, streetwise
##                   chaos, Taco Bell shorthand, fears only expired sauce
##                   and a quiet Bentley.

static var _last_indices: Dictionary = {}

const FALLBACK_LINE := {
	"speaker": "",
	"text": "The hideout hums to itself. Pretend you didn't hear that.",
	"portrait_id": "fallback",
}

const _JAKE_LINES: Array = [
	"I triple-checked the mission board and then forgot why I walked into this room. Medically speaking, we are operating at peak Jake.",
	"I stocked the hideout with security systems, emergency exits, and somehow zero poop bags. Bentley has filed a formal complaint.",
	"I know the neon screams 'crime boss', but emotionally this is just me trying to make sure Parmida has a good birthday.",
	"If anything looks over-engineered, that is because I love her and I had access to caffeine.",
	"I packed snacks for morale. Then I ate the morale. We are rebuilding.",
	"The plan is simple: keep Parmida safe, make Bentley proud, and do not let Louis near anything labeled 'experimental sauce'.",
	"I am not saying I am tired, but I just tried to badge into the snack drawer.",
	"The poop bag dispenser is empty again. I accept responsibility, but I would like the record to reflect I was building a heist command center.",
	"Parmida deserves a world that lights up when she walks in. I only had Godot and panic, but I made do.",
	"If she smiles even once, every bug in this project becomes legally irrelevant.",
	"Sweet tooth update: I'm rationing gummy worms like classified documents. Bentley sees this. Bentley judges this.",
	"I rehearsed three birthday speeches. Lost two. The third one is just the word 'hi' and a long, hopeful pause.",
	"I love you, Parmida. That sentence has been the only stable variable in this entire build.",
	"I built this hideout for you. The lighting is dramatic because YOU deserve a dramatic entrance.",
	"Worst case: the city falls. Best case: you laugh once. Either way, I'm here, with juice boxes, ready.",
]

const _PARMIDA_LINES: Array = [
	"This place is ridiculous. But it is ridiculous in a way that makes me feel very loved.",
	"I can tell Jake made this because there are twelve safety systems and somehow the poop bags are still empty.",
	"Bentley is pretending he is above all of this, which means he is having the best day of his life.",
	"I'm not sure I'm qualified to lead a heist crew, but I am very qualified to worry about everyone afterward.",
	"The neon is dramatic, the planning table is suspicious, and the emotional effort is... very obvious.",
	"I like this hideout. It feels like someone tried to turn love into architecture.",
	"If this is what Jake builds while exhausted, I am a little afraid of what he could do after a nap.",
	"I do not need everything to be perfect. I can see how much of your heart is in it.",
	"Bentley, please stop interrogating Louis. Actually... no, continue. He looks guilty.",
	"I feel safe here. Not because of the locks. Because of the people.",
	"You stayed up all night to make this look easy, didn't you? I can tell. I'm keeping the snack stash.",
	"Birthday me has decided: anyone who hands me Bentley gets one (1) gentle hug.",
	"I love that the cozy corner is somehow doing more strategic work than the planning table.",
	"Jake. Look at me. You did good. Now drink water. That is also a plan.",
	"This is the best worst hideout I have ever been emotionally responsible for.",
]

const _BENTLEY_LINES: Array = [
	"Bark translation: I have inspected the hideout. It is acceptable. The lack of filled poop bags is not.",
	"Bentley looks at Parmida, then immediately looks away like he was not being emotionally vulnerable.",
	"Bark translation: I am not worried about Mom. I am monitoring the room for tactical reasons.",
	"Bentley sits directly in the most important walkway and calls it leadership.",
	"Bark translation: Jake is forgetful, but he gives snacks. The council remains divided.",
	"Bentley sniffs the air. Louis has been here. The investigation is ongoing.",
	"Bark translation: If danger approaches Mom, I will become extremely loud and legally unstoppable.",
	"Bentley's tail betrays his entire personality.",
	"Bark translation: I am the best part of this operation. This is not ego. This is data.",
	"Bentley gently bumps Parmida's leg, then pretends it was part of a security sweep.",
	"Bark translation: I do not need affection. However, if Mom offers it, I will accept for morale.",
	"Bentley has promoted himself to Head of Snacks, Security, and Emotional Oversight.",
	"Bark translation: The poop bag situation has been escalated to the highest paw-thority. Someone will be answering for this.",
	"Bentley stares at Louis with the calm of a dog who keeps a list.",
	"Bark translation: Mom said it was her birthday. I have prepared a gift. The gift is me. Lying down. Heroically.",
]

const _LOUIS_LINES: Array = [
	"People think delivery is about speed. Wrong. It is about timing, instinct, and knowing which door is spiritually unlocked.",
	"I've seen things in a Taco Bell parking lot that would make a security camera request PTO.",
	"You need a route? I got three: safe, fast, and the one my lawyer calls 'an ongoing concern'.",
	"The city talks if you listen. Mostly it says, 'Your order is ready'.",
	"Bentley doesn't trust me, which is fair. Great leaders recognize other great leaders.",
	"Never underestimate a man with a thermal bag and no questions.",
	"If anyone asks, I was never here. Unless there are rewards points.",
	"I don't run from danger. I reroute around it and arrive four minutes early.",
	"The secret is confidence. And mild trespassing. Mostly confidence.",
	"I once delivered a Crunchwrap through three locked doors and a vibes-based security system.",
	"I fear only two things: expired sauce and Bentley when he is quiet.",
	"This hideout has good energy. Suspicious energy, but good.",
	"I told Jake the back door was 'mostly secure'. He looked at me like a doctor looks at a third coffee.",
	"Happy birthday to the boss. I brought you intel, snacks, and one (1) plausibly clean spoon.",
	"You ever get a hot sauce packet that just feels lucky? I built a whole career on that feeling.",
]

const _LINES_BY_SPEAKER := {
	"jake": _JAKE_LINES,
	"parmida": _PARMIDA_LINES,
	"mere": _PARMIDA_LINES,
	"bentley": _BENTLEY_LINES,
	"louis": _LOUIS_LINES,
}

const _PORTRAIT_ID_BY_SPEAKER := {
	"jake": "jake",
	"parmida": "parmida",
	"mere": "mere",
	"bentley": "bentley",
	"louis": "louis",
}

const _DISPLAY_NAME_BY_SPEAKER := {
	"jake": "Jake",
	"parmida": "Parmida",
	"mere": "Mere",
	"bentley": "Bentley",
	"louis": "Louis",
}

static func has_speaker(speaker_id: String) -> bool:
	return _LINES_BY_SPEAKER.has(_normalize(speaker_id))

static func line_count(speaker_id: String) -> int:
	var key := _normalize(speaker_id)
	if not _LINES_BY_SPEAKER.has(key):
		return 0
	return (_LINES_BY_SPEAKER[key] as Array).size()

static func get_all_lines(speaker_id: String) -> Array:
	var key := _normalize(speaker_id)
	if not _LINES_BY_SPEAKER.has(key):
		return []
	var out: Array = []
	for raw in (_LINES_BY_SPEAKER[key] as Array):
		out.append({
			"speaker": _DISPLAY_NAME_BY_SPEAKER.get(key, key.capitalize()),
			"text": String(raw),
			"portrait_id": _PORTRAIT_ID_BY_SPEAKER.get(key, key),
		})
	return out

static func get_random_line(speaker_id: String) -> Dictionary:
	var key := _normalize(speaker_id)
	if not _LINES_BY_SPEAKER.has(key):
		return FALLBACK_LINE.duplicate(true)
	var pool: Array = _LINES_BY_SPEAKER[key]
	if pool.is_empty():
		return FALLBACK_LINE.duplicate(true)
	var previous := int(_last_indices.get(key, -1))
	var index := randi() % pool.size()
	if pool.size() > 1 and index == previous:
		index = (index + 1) % pool.size()
	_last_indices[key] = index
	return {
		"speaker": _DISPLAY_NAME_BY_SPEAKER.get(key, key.capitalize()),
		"text": String(pool[index]),
		"portrait_id": _PORTRAIT_ID_BY_SPEAKER.get(key, key),
	}

static func build_short_sequence(speaker_id: String, count: int = 2) -> Array:
	var key := _normalize(speaker_id)
	if not _LINES_BY_SPEAKER.has(key):
		return [FALLBACK_LINE.duplicate(true)]
	var pool: Array = _LINES_BY_SPEAKER[key]
	if pool.is_empty():
		return [FALLBACK_LINE.duplicate(true)]
	var clamped := clampi(count, 1, pool.size())
	var picks: Array = []
	var taken: Dictionary = {}
	while picks.size() < clamped:
		var idx := randi() % pool.size()
		if taken.has(idx):
			continue
		taken[idx] = true
		picks.append({
			"speaker": _DISPLAY_NAME_BY_SPEAKER.get(key, key.capitalize()),
			"text": String(pool[idx]),
			"portrait_id": _PORTRAIT_ID_BY_SPEAKER.get(key, key),
		})
	return picks

static func _normalize(speaker_id: String) -> String:
	return speaker_id.strip_edges().to_lower()
