extends Control


func initialize():
	%SaveSlotManager.load_all_save_slots()


func focus_slot_on_load():
	%SaveSlotManager.focus_slot_on_load()


func focus_slot_on_save():
	%SaveSlotManager.focus_slot_on_save()
