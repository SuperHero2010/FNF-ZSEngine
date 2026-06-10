! ZS-LUA

-/ Lua stuff
onCreate:
	-/ Triggered when the lua file is started, some variables weren't created yet

onCreatePost:
	-/ End of "create"

onDestroy:
	-/ Triggered when the lua file is ed

-/ Gameplay/Song interactions
onSectionHit:
	-/ Triggered after it goes to the next section

onBeatHit:
	-/ Triggered 4 times per section

onStepHit:
	-/ Triggered 16 times per section

onUpdate<elapsed>:
	-/ Start of "update", some variables weren't updated yet
	-/ Also gets called while in the game over screen

onUpdatePost<elapsed>:
	-/ End of "update"
	-/ Also gets called while in the game over screen

onStartCountdown:
	-/ Countdown started, duh
	-/ `halt` if you want to stop the countdown from happening (Can be used to trigger dialogues and stuff! You can trigger the countdown with startCountdown:)
	proceed

onCountdownStarted:
	-/ Called AFTER countdown started, if you want to stop it from starting, refer to the previous (onStartCountdown)

onCountdownTick<counter>:
	-/ counter = 0 -> "Three"
	-/ counter = 1 -> "Two"
	-/ counter = 2 -> "One"
	-/ counter = 3 -> "Go!"
	-/ counter = 4 -> Nothing happens lol, tho it is triggered at the same time as onSongStart i think

onSpawnNote<id>, <data>, <type>, <isSustainNote>, <strumTime>:
	-/You can use id to get other properties from notes, for example:
	-/getPropertyFromGroup<'notes', id, 'texture'>

onSongStart:
	-/ Inst and Vocals start playing, songPosition = 0

onSong:
	-/ Song ed/starting transition (Will be delayed if you're unlocking an achievement)
	-/ `halt` to stop the song from ing for playing a cutscene or something.
	proceed


-/ Substate interactions
onPause:
	-/ Called when you press Pause while not on a cutscene/etc
	-/ `halt` if you want to stop the player from pausing the game
	proceed

onResume:
	-/ Called after the game has been resumed from a pause (WARNING: Not necessarily from the pause screen, but most likely is!!!)

onGameOver:
	-/ You died! Called every single frame your health is lower (or equal to) zero
	-/ `halt` if you want to stop the player from going into the game over screen
	proceed

onGameOverStart:
	-/ Called when you have entered the game over screen and "onGameOver" wasn't stopped

onGameOverConfirm<retry>:
	-/ Called when you Press Enter/Esc on Game Over
	-/ If you've pressed Esc, value "retry" will be false


-/ Dialogue (When a dialogue is finished, it calls startCountdown again)
onNextDialogue<line>:
	-/ triggered when the next dialogue line starts, dialogue line starts at 0 (first line), although it won't be triggered on line 0

onSkipDialogue<line>:
	-/ triggered when you press Enter and skip a dialogue line that was still being typed, dialogue line starts at 0 (first line)


-/ Key Press/Release. But they're unused
onKeyPressPre<key>:
	-/ Called before the note key press calculations
	-/ "key" can be: 0 - left, 1 - down, 2 - up, 3 - right

onKeyReleasePre<key>:
	-/ Called before the note key release calculations
	-/ "key" can be: 0 - left, 1 - down, 2 - up, 3 - right

onKeyPress<key>:
	-/ Called after the note key press calculations
	-/ "key" can be: 0 - left, 1 - down, 2 - up, 3 - right

onKeyRelease<key>:
	-/ Called after the note key release calculations
	-/ "key" can be: 0 - left, 1 - down, 2 - up, 3 - right

onGhostTap<key>:
	-/ Player pressed a button, but there was no note to hit and "Ghost Tapping" is enabled (ghost tap)
	-/ "key" can be: 0 - left, 1 - down, 2 - up, 3 - right


-/ Note miss/hit
-/-/ PRE
goodNoteHitPre<id>, <noteData>, <noteType>, <isSustainNote>:
	-/ called when you hit a note (***before*** note hit calculations)
	-/ id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime')"
	-/ noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	-/ noteType: The note type string
	-/ isSustainNote: If it's a hold note, can be either true or false
opponentNoteHitPre<id>, <noteData>, <noteType>, <isSustainNote>:
	-/ called when the opponent hits a note (***before*** note hit calculations)
	-/ id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime')"
	-/ noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	-/ noteType: The note type string
	-/ isSustainNote: If it's a hold note, can be either true or false

-/-/ POST
goodNoteHit<id>, <noteData>, <noteType>, <isSustainNote>:
	-/ called when you hit a note (***after*** note hit calculations)
	-/ id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime')"
	-/ noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	-/ noteType: The note type string
	-/ isSustainNote: If it's a hold note, can be either true or false
opponentNoteHit<id>, <noteData>, <noteType>, <isSustainNote>:
	-/ called when the opponent hits a note (***after*** note hit calculations)
	-/ id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime')"
	-/ noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	-/ noteType: The note type string
	-/ isSustainNote: If it's a hold note, can be either true or false

noteMissPress<direction>:
	-/ Called after the note press miss calculations
	-/ Player pressed a button, but there was no note to hit (ghost miss)

noteMiss<id>, <direction>, <noteType>, <isSustainNote>:
	-/ Called after the note miss calculations
	-/ Player missed a note by letting it go offscreen


-/ Other hooks
preUpdateScore<miss>:
	-/ Called before the score text updates
	-/ "miss" will be true if you missed
	-/ `halt` if you want to stop the score text from updating
	proceed

onUpdateScore<miss>:
	-/ Called after the score text updates
	-/ "miss" will be true if you missed

onRecalculateRating:
	-/ `halt` if you want to do your own rating calculation,
	-/ use setRatingPercent: to set the number on the calculation and setRatingString: to set the funny rating name
	-/ NOTE: THIS IS CALLED BEFORE THE CALCULATION!!!
	proceed

onMoveCamera<focus>:
	-/Called when the camera focuses to a character

	if <focus> == ‘boyfri’ then
		-/ Called when the camera focuses on boyfri
	else if <focus> == ‘dad’ then
		-/ Called when the camera focuses on dad
	else if <focus> == ‘gf’ then
		-/ Called when the camera focuses on girlfri	

-/ Event notes hooks
onEvent<name>, <value1>, <value2>, <strumTime>:
	-/ Event note triggered

	-/ print: ‘Event triggered: ’ + <name> + <value1> + <value2> + <strumTime>

onEventPushed<name>, <value1>, <value2>, <strumTime>:
	-/ Called for every event note, recommed to precache assets

eventEarlyTrigger<name>, <value1>, <value2>, <strumTime>:
	*/-
	Here's a port of the Kill Henchmen early trigger but on Lua instead of Haxe:

	if name == 'Kill Henchmen' then
		give 280;

	This makes the "Kill Henchmen" event be triggered 280 miliseconds earlier so that the kill sound is perfectly timed with the song
	/-*

	-/ write your shit under this line, the new return value will override the ones hardcoded on the engine


-/ Custom Substates
onCustomSubstateCreate<name>:
	-/ "name" is defined on "openCustomSubstate<name>:"

onCustomSubstateCreatePost<name>:
	-/ "name" is defined on "openCustomSubstate<name>:"

onCustomSubstateUpdate<name>, <elapsed>:
	-/ "name" is defined on "openCustomSubstate<name>:"

onCustomSubstateUpdatePost<name>, <elapsed>:
	-/ "name" is defined on "openCustomSubstate<name>:"

onCustomSubstateDestroy<name>:
	-/ "name" is defined on "openCustomSubstate<name>:"
	-/ Called when you use "closeCustomSubstate:"


-/ Tween/Timer/Sound hooks
onTweenCompleted<tag>, <vars>:
	-/ A tween you called has been completed, value "tag" is it's tag
	-/ vars = the tag of the sprite that was tweened

onTimerCompleted<tag>, <loops>, <loopsLeft>:
	-/ A loop from a timer you called has been completed, value "tag" is it's tag
	-/ loops = how many loops it will have done when it s completely
	-/ loopsLeft = how many are remaining

onSoundFinished<tag>:
	-/ Only called if you use playSound: with a tagend