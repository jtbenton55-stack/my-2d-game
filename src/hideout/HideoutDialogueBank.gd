extends Node
class_name HideoutDialogueBank

const FALLBACK_LINE := "The hideout is quiet for a second. Suspicious."

static var _last_indices: Dictionary = {}

const LINES := {
	"bentley_care_wipe_paws": [
		"Bentley allows the paw wipe because he understands brand management.",
		"Bentley presents one paw like a tiny monarch approving a treaty.",
		"Bentley believes the wipes are for everyone else's emotional growth.",
	],
	"bentley_care_give_treat": [
		"Bentley accepts the treat with the seriousness of a witness protection deal.",
		"Bentley takes the treat and immediately begins negotiating for the sequel.",
		"Bentley considers this a reasonable tribute.",
	],
	"bentley_care_brush": [
		"Bentley has been brushed. The operation is now 12% softer.",
		"Bentley tolerates grooming because the room clearly needed leadership.",
		"Bentley emerges fluffier and somehow more legally persuasive.",
	],
	"bentley_care_restock_poop_bags": [
		"Poop bags restocked. Tactical readiness improved.",
		"Bentley refuses to comment on logistics, but approves the preparedness.",
		"The poop bags are now stocked like a morally complicated supply chain.",
	],
	"bentley_bed_fresh": [
		"Bentley accepts pets with the gravity of a judge accepting sealed evidence.",
		"Bentley looks innocent, which is impressive considering the entire room is a cork-board confession.",
		"Bentley requires immediate paw-related legal defense and possibly a smaller pillow jurisdiction.",
		"Bentley has decided the bed is command central and everyone else is support staff.",
		"Bentley sighs like a dog carrying the emotional weight of organized snacks.",
		"Bentley blinks twice, which you understand to mean: proceed, but bring treats.",
	],
	"bentley_bed_taco_bell_completed": [
		"Bentley looks extremely proud of surviving the sauce incident.",
		"Bentley has processed the mission emotionally and requires snacks.",
		"Bentley carries himself like the delivery bag was his idea.",
		"Bentley is pretending he did not enjoy the chaos, which is false and legally observable.",
		"Bentley checks his paws like a veteran detective checking old scars.",
		"Bentley believes the Taco Bell Drop was primarily a dog enrichment activity.",
	],
	"bentley_bed_high_heat": [
		"Bentley looks innocent in a way that suggests legal counsel.",
		"Bentley has decided the red lights are not his department.",
		"Bentley sits like a dog with several sealed records.",
	],
	"bentley_bed_after_care": [
		"Bentley has been cared for and now expects the room to acknowledge his improved softness.",
		"Bentley displays one clean paw like it belongs in a museum with guarded lighting.",
		"Bentley accepts grooming only because justice sometimes has tangles.",
		"Bentley is now brushed, wiped, treated, and fully prepared to be emotionally central.",
		"Bentley smells faintly less like sauce and strongly more like leadership.",
		"Bentley considers the care checklist a tribute wall with better towels.",
	],
	"bentley_bed_after_store_purchase": [
		"Bentley notices the new item and immediately evaluates whether it improves his nap economy.",
		"Bentley supports interior design when it creates more places to look innocent.",
		"Bentley believes every purchase should include a dog comfort rider.",
	],
	"jake_fresh": [
		"I'm not saying this is a healthy coping mechanism, but the cork board does have excellent diagnostic clarity.",
		"This room has the vibe of a differential diagnosis with furniture.",
		"I have slept too little to criticize the crime board responsibly.",
		"If I charted this hideout, the chief complaint would be 'neon anxiety with promising storage.'",
		"The planning table is organized enough to worry me and chaotic enough to feel familiar.",
		"I did twelve hours at the hospital and still somehow this room has the worse triage system.",
	],
	"jake_taco_bell_completed": [
		"Bentley's paws smell like mild sauce and adrenaline. I'm documenting this as a new syndrome.",
		"The medical literature is silent on post-heist sauce exposure.",
		"I'm proud of us, concerned about us, and unwilling to chart any of this.",
		"Vitals are stable, morale is weirdly high, and the evidence smells like drive-thru plastic.",
		"The mission was successful, assuming success includes a dog, a bag, and several avoidable decisions.",
		"I have seen less emotional complexity in an emergency room at shift change.",
	],
	"jake_taco_bell_missing_items": [
		"Clinically speaking, the room has the energy of an unfinished differential.",
		"The missing evidence is presenting with classic unresolved-board symptoms.",
		"I would prescribe rest, hydration, and one more sweep for suspicious sauce.",
	],
	"jake_high_heat": [
		"From a medical perspective, our stress level is elevated. From a crime perspective, I think the room glowing red is probably bad.",
		"If this were a patient, I would call it unstable but weirdly charismatic.",
		"I recommend fluids, rest, and fewer felony-adjacent errands.",
		"The heat level is doing the thing monitors do right before everyone starts pretending they are calm.",
		"I can manage a code blue. I cannot medically justify whatever Louis is doing near the lamps.",
		"Deep breaths. Slow movements. Nobody make eye contact with the evidence board until the room stops looking radioactive.",
	],
	"jake_louis_unlocked": [
		"I don't trust Louis's supply chain, but I respect the confidence.",
		"Louis has the blood pressure of a man who itemizes suspicious lamps.",
		"Medically, I cannot recommend buying decor from a duffel bag.",
	],
	"mere_fresh": [
		"This room is somewhere between detective office, dog daycare, and tax fraud.",
		"I like that the cozy corner is doing most of the emotional labor.",
		"This hideout says 'we have a plan' in a legally deniable font.",
		"I appreciate that the room is trying to be cozy while also obviously planning something.",
		"The greenhouse is carrying the entire emotional health budget, and honestly, good for her.",
		"If anyone asks, this is a craft room with unusually specific maps.",
	],
	"mere_taco_bell_completed": [
		"I love that we're calling this evidence when it is clearly stolen decor.",
		"The room somehow smells like victory and drive-thru tile grout.",
		"I support the mission but reserve judgment on the sauce-themed interior design.",
		"Bentley has the posture of someone who saved the day and knows the treat jar is reachable.",
		"Success looks good on the room, though the suspicious fry basket is doing a lot.",
		"I am proud, unsettled, and already thinking about where that trophy should not go.",
	],
	"mere_taco_bell_missing_items": [
		"I feel like the board is silently judging us for missing something.",
		"The missing collectibles are giving the room abandonment issues.",
		"I believe in us, but I also believe the shelves know we forgot something.",
	],
	"mere_high_heat": [
		"I feel like the red warning lights are trying to tell us something subtle.",
		"The room is glowing like it knows what we did.",
		"I would call this ambiance if it were less threatening.",
		"Everyone breathe. The room is being dramatic, but we do not have to match its energy.",
		"This is less cozy crime-noir and more 'the lamp knows too much.'",
		"If the heat gets higher, I am putting a weighted blanket over the evidence board.",
	],
	"mere_louis_unlocked": [
		"Louis has the energy of a man who sells lamps out of a duffel bag.",
		"I respect his aesthetic and fear his invoices.",
		"Every Louis item feels like it has a backstory and a sealed record.",
	],
	"louis_unlocked": [
		"I know a guy who knows a guy who sells lamps. Crime lamps.",
		"Everything fell off a truck. Emotionally.",
		"Do not ask where the rug came from. Do ask how good it looks.",
		"This stool? Practically clean. Spiritually used. Very affordable.",
		"I only sell decor with character, history, and at least one confusing receipt.",
		"If a lamp asks you where you got it, you tell it Louis sent you.",
		"Cash is fine. Case Cash is finer. Questions are expensive.",
		"The headset works, mostly. Sometimes it picks up a drive-thru from 1998. That's ambiance.",
	],
	"store_purchase_success": [
		"Purchased. The hideout becomes harder to explain.",
		"Item acquired. Interior design has entered its suspicious era.",
		"Bought and delivered. Probably legally.",
	],
	"store_insufficient_funds": [
		"Not enough Case Cash. Crime is expensive.",
		"You are short on funds and long on ambition.",
		"The store rejects your vibes and requests more money.",
	],
	"greenhouse_interaction": [
		"The greenhouse makes the whole operation feel almost emotionally sustainable.",
		"Something about the plants suggests they know more than they're saying.",
		"The city view is beautiful, which is rude given the circumstances.",
	],
	"greenhouse_take_breath": [
		"For one second, the room is just plants, glass, and plausible deniability.",
		"The greenhouse does not solve the case, but it does lower everyone's shoulders.",
		"You take a breath. Somewhere, the cork board waits.",
	],
	"greenhouse_water_plants": [
		"The plants accept water with fewer questions than Louis.",
		"A leaf trembles like it knows a side quest.",
		"The greenhouse remains hydrated and legally ambiguous.",
	],
	"greenhouse_inspect_skyline": [
		"The city glows like a problem with excellent lighting.",
		"From up here, every job looks smaller and somehow more expensive.",
		"The skyline says nothing. That feels deliberate.",
	],
	"mission_start_warning": [
		"Double-check the scheme cards. Confidence is not a substitute for preparation.",
		"The job can start now, but the planning table is judging your loadout.",
		"Bentley recommends snacks, plausible deniability, and one more look at the cards.",
	],
	"big_case_review": [
		"The pieces are not random anymore.",
		"The board is starting to argue back.",
		"A larger pattern is forming, which is exactly what a larger pattern would want.",
	],
	"open_decor_area": [
		"This area is waiting to become either cozy or incriminating.",
		"Future furniture will go here. Future judgment will follow.",
		"A blank canvas for rugs, trophies, and questionable priorities.",
	],
	"decoration_place_success": [
		"Placed. The room now has more personality and possibly more evidence.",
		"Decor placed. The hideout approves in a legally neutral way.",
		"That looks good there. Suspiciously good.",
	],
	"decoration_remove_success": [
		"Removed. The room pretends not to miss it.",
		"Decor removed. Minimalism has entered the investigation.",
		"Gone. Like a receipt in a panic.",
	],
	"store_category_placeholder": [
		"This category is browsing with intent.",
		"The catalog hums like it has opinions.",
		"Several items look useful, decorative, or admissible.",
	],
	"arrange_later": [
		"Arrangement is coming in a later pass. The room is practicing patience.",
		"Decor placement has boundaries now, which is healthy for everyone.",
		"The hideout nods toward future drag-and-drop without committing.",
	],
}

static func get_line(context_id: String, state_id: String = "") -> String:
	return get_random_line(context_id, state_id)

static func get_random_line(context_id: String, state_id: String = "") -> String:
	var key := context_id
	if state_id != "" and LINES.has("%s_%s" % [context_id, state_id]):
		key = "%s_%s" % [context_id, state_id]
	var lines: Array = LINES.get(key, [])
	if lines.is_empty():
		return FALLBACK_LINE
	var previous := int(_last_indices.get(key, -1))
	var index := randi() % lines.size()
	if lines.size() > 1 and index == previous:
		index = (index + 1) % lines.size()
	_last_indices[key] = index
	return String(lines[index])

static func context_count() -> int:
	return LINES.size()

static func context_has_three_lines(context_id: String) -> bool:
	return Array(LINES.get(context_id, [])).size() >= 3

static func context_has_at_least(context_id: String, minimum_count: int) -> bool:
	return Array(LINES.get(context_id, [])).size() >= minimum_count
