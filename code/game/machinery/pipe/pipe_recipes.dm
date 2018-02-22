//
// Recipies for Pipe Dispenser and (someday) the RPD
//

var/global/list/atmos_pipe_recipes = null
var/global/list/disposal_pipe_recipes = null

/hook/startup/proc/init_pipe_recipes()
	global.atmos_pipe_recipes = list(
		"Pipes" = list(
			new /datum/pipe_info/pipe("Pipe",				/obj/machinery/atmospherics/pipe/simple),
			new /datum/pipe_info/pipe("Manifold",			/obj/machinery/atmospherics/pipe/manifold),
			new /datum/pipe_info/pipe("Manual Valve",		/obj/machinery/atmospherics/components/binary/valve),
			new /datum/pipe_info/pipe("Digital Valve",		/obj/machinery/atmospherics/components/binary/valve/digital),
			new /datum/pipe_info/pipe("4-Way Manifold",		/obj/machinery/atmospherics/pipe/manifold4w),
			new /datum/pipe_info/pipe("Layer Manifold",		/obj/machinery/atmospherics/pipe/layer_manifold),
		),
		"Devices" = list(
			new /datum/pipe_info/pipe("Connector",			/obj/machinery/atmospherics/components/unary/portables_connector),
			new /datum/pipe_info/pipe("Unary Vent",			/obj/machinery/atmospherics/components/unary/vent_pump),
			new /datum/pipe_info/pipe("Gas Pump",			/obj/machinery/atmospherics/components/binary/pump),
			new /datum/pipe_info/pipe("Passive Gate",		/obj/machinery/atmospherics/components/binary/passive_gate),
			new /datum/pipe_info/pipe("Volume Pump",		/obj/machinery/atmospherics/components/binary/volume_pump),
			new /datum/pipe_info/pipe("Scrubber",			/obj/machinery/atmospherics/components/unary/vent_scrubber),
			new /datum/pipe_info/pipe("Injector",			/obj/machinery/atmospherics/components/unary/outlet_injector),
			new /datum/pipe_info/meter("Meter"),
			new /datum/pipe_info/pipe("Gas Filter",			/obj/machinery/atmospherics/components/trinary/filter),
			new /datum/pipe_info/pipe("Gas Mixer",			/obj/machinery/atmospherics/components/trinary/mixer),
		),
		"Heat Exchange" = list(
			new /datum/pipe_info/pipe("Pipe",				/obj/machinery/atmospherics/pipe/heat_exchanging/simple),
			new /datum/pipe_info/pipe("Manifold",			/obj/machinery/atmospherics/pipe/heat_exchanging/manifold),
			new /datum/pipe_info/pipe("4-Way Manifold",		/obj/machinery/atmospherics/pipe/heat_exchanging/manifold4w),
			new /datum/pipe_info/pipe("Junction",			/obj/machinery/atmospherics/pipe/heat_exchanging/junction),
			new /datum/pipe_info/pipe("Heat Exchanger",		/obj/machinery/atmospherics/components/unary/heat_exchanger),
		)
	))
	
	global.disposal_pipe_recipes, list(
		"Disposal Pipes" = list(
			new /datum/pipe_info/disposal("Pipe",			/obj/structure/disposalpipe/segment, PIPE_BENDABLE),
			new /datum/pipe_info/disposal("Junction",		/obj/structure/disposalpipe/junction, PIPE_TRIN_M),
			new /datum/pipe_info/disposal("Y-Junction",		/obj/structure/disposalpipe/junction/yjunction),
			new /datum/pipe_info/disposal("Sort Junction",	/obj/structure/disposalpipe/sorting/mail, PIPE_TRIN_M),
			new /datum/pipe_info/disposal("Trunk",			/obj/structure/disposalpipe/trunk),
			new /datum/pipe_info/disposal("Bin",			/obj/machinery/disposal/bin, PIPE_ONEDIR),
			new /datum/pipe_info/disposal("Outlet",			/obj/structure/disposaloutlet),
			new /datum/pipe_info/disposal("Chute",			/obj/machinery/disposal/deliveryChute),
		)
	))

	return TRUE

//
// New method of handling pipe construction.  Instead of numeric constants and a giant switch statement of doom
// 	every pipe type has a datum instance which describes its name, placement rules and construction method, dispensing etc.
// The advantages are obvious, mostly in simplifying the code of the dispenser, and the ability to add new pipes without hassle.
//
/datum/pipe_info
	var/name = "Abstract Pipe (fixme)"
	var/icon_state
	var/id = -1  // The legacy pipe id defined in construction.dm  (Is this needed? We'll see)
	var/obj/item/pipe/pipe_type // This is the type PATH to the type of pipe we will construct
	var/dirtype = PIPE_BENDABLE // Class of possible connection types

// Render an HTML link to select this pipe type
/datum/pipe_info/proc/Render(dispenser)
	var/dat = "<li><a href='?src=\ref[dispenser]&[Params()]'>[name]</a></li>"
	// Stationary pipe dispensers don't allow you to pre-select pipe directions.
	// This makes it impossble to spawn bent versions of bendable pipes.
	// We add a "Bent" pipe type with a preset diagonal direction to work around it.
	if(istype(dispenser, /obj/machinery/pipedispenser) && (dirtype == PIPE_BENDABLE || dirtype == /obj/item/pipe/binary/bendable))
		dat += "<li><a href='?src=\ref[dispenser]&[Params()]&dir=[NORTHEAST]'>Bent [name]</a></li>"
	return dat

/datum/pipe_info/proc/Params()
	return ""

/datum/pipe_info/proc/get_preview(selected_dir)
	var/list/dirs
	switch(dirtype)
		if(PIPE_STRAIGHT, PIPE_BENDABLE)
			dirs = list("[NORTH]" = "Vertical", "[EAST]" = "Horizontal")
			if(dirtype == PIPE_BENDABLE)
				dirs += list("[NORTHWEST]" = "West to North", "[NORTHEAST]" = "North to East",
							 "[SOUTHWEST]" = "South to West", "[SOUTHEAST]" = "East to South")
		if(PIPE_TRINARY, PIPE_TRIN_M)
			dirs = list("[NORTH]" = "West South East", "[EAST]" = "North West South",
						"[SOUTH]" = "East North West", "[WEST]" = "South East North")
			if(dirtype == PIPE_TRIN_M)
				dirs += list("[SOUTHEAST]" = "West South East", "[NORTHEAST]" = "North West South",
							 "[NORTHWEST]" = "East North West", "[SOUTHWEST]" = "South East North")
		if(PIPE_UNARY)
			dirs = list("[NORTH]" = "North", "[EAST]" = "East", "[SOUTH]" = "South", "[WEST]" = "West")
		if(PIPE_ONEDIR)
			dirs = list("[SOUTH]" = name)
		if(PIPE_UNARY_FLIPPABLE)
			dirs = list("[NORTH]" = "North", "[NORTHEAST]" = "North Flipped", "[EAST]" = "East", "[SOUTHEAST]" = "East Flipped",
						"[SOUTH]" = "South", "[SOUTHWEST]" = "South Flipped", "[WEST]" = "West", "[NORTHWEST]" = "West Flipped")

	var/list/rows = list()
	var/list/row = list("previews" = list())
	var/i = 0
	for(var/dir in dirs)
		var/numdir = text2num(dir)
		var/flipped = ((dirtype == PIPE_TRIN_M) || (dirtype == PIPE_UNARY_FLIPPABLE)) && (numdir in GLOB.diagonals)
		row["previews"] += list(list("selected" = (numdir == selected_dir), "dir" = dir2text(numdir), "dir_name" = dirs[dir], "icon_state" = icon_state, "flipped" = flipped))
		if(i++ || dirtype == PIPE_ONEDIR)
			rows += list(row)
			row = list("previews" = list())
			i = 0

	return rows

// Subtype for actual pipes
/datum/pipe_info/pipe/New(label, obj/machinery/atmospherics/path)
	name = label
	id = path
	pipe_type = path
	icon_state = initial(path.pipe_state)
	var/obj/item/pipe/c = initial(path.construction_type)
	dirtype = initial(c.RPD_type)

/datum/pipe_info/pipe/Params()
	return "makepipe=[id]&type=[dirtype]"

// Subtype for meters
/datum/pipe_info/meter
	icon_state = "meterX"
	dirtype = PIPE_ONEDIR

/datum/pipe_info/meter/New(label)
	name = label

/datum/pipe_info/meter/Params()
	return "makemeter=[id]&type=[dirtype]"

// Subtype for disposal pipes
/datum/pipe_info/disposal/New(label, obj/path, dt=PIPE_UNARY)
	name = label
	id = path

	icon_state = initial(path.icon_state)
	if(ispath(path, /obj/structure/disposalpipe))
		icon_state = "con[icon_state]"

	dirtype = dt

/datum/pipe_info/disposal/Params()
	return "dmake=[id]&type=[dirtype]"

/datum/pipe_info/transit/New(label, obj/path, dt=PIPE_UNARY)
	name = label
	id = path
	dirtype = dt
	icon_state = initial(path.icon_state)
	if(dt == PIPE_UNARY_FLIPPABLE)
		icon_state = "[icon_state]_preview"