class_name Loc
extends RefCounted
## Language helper. English text is the key; Loc.t("Play") returns the Chinese text when the language is Chinese.
##   Loc.t("Not enough gold")            plain lookup
##   Loc.f("Gold  %d", [g])              lookup, then format
## Text that is already a name or story line works the same way (see data/translations.gd). Unknown text is shown as is.

static func is_zh() -> bool:
	return Settings.language == "zh"


static func t(text: String) -> String:
	if Settings.language == "zh" and Translations.ZH.has(text):
		return String(Translations.ZH[text])
	return text


static func f(text: String, args: Array) -> String:
	return t(text) % args
