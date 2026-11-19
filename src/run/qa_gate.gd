class_name QaGate
extends RefCounted
## Story 024: the single switch for every QA / test entry point (CLI flags --seed / --starter / --encounter and the
## Main.qa_* / BattleScreen.qa_* cheats that change a run).
## RULE: the Windows / Linux export presets set `custom_features="release"`, so OS.has_feature("release") is true only in
## an exported game. QA is therefore ON in the editor, with `godot --path .` and in the headless test / walkthrough
## scripts, and OFF in every exported build. Never read OS.get_cmdline_user_args() for a QA purpose outside this gate.

const RELEASE_FEATURE: String = "release"


## True when QA tools may act (editor, headless tests); false in an exported build.
static func enabled() -> bool:
	return not OS.has_feature(RELEASE_FEATURE)
