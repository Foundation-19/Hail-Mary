// ====================================================
// CIRCUIT NODE SYSTEM
// F13-native replacement for the SS13 integrated
// circuit computation files:
//   arithmetic.dm, trig.dm, logic.dm, converters.dm
//   text.dm, time.dm, memory.dm, data_transfer.dm
//   lists.dm
//
// Nodes live inside a datum/robot_hardware/circuit_board.
// They are connected by the board's connection list.
// The board calls evaluate() on each node in order,
// propagating output values to connected inputs.
//
// Workshop circuit editor creates/configures nodes
// via browser UI - no physical wirer tool needed.
//
// File: code/modules/integrated_electronics/circuit_node.dm
// ====================================================


// ====================================================
// BASE NODE DATUM
// ====================================================

/datum/circuit_node
	/// Display name shown in the circuit editor
	var/node_name = "Unknown Node"
	/// Category shown in add-node picker
	var/node_category = "General"
	/// Brief description
	var/node_desc = "A circuit node."
	/// Tutorial text shown when selected
	var/node_tutorial = "No documentation."

	/// Weakref back to the circuit_board this belongs to
	var/datum/weakref/board_ref = null

	/// Named input slots - assoc list: name -> current value
	var/list/inputs = list()
	/// Named output slots - assoc list: name -> current value
	var/list/outputs = list()
	/// Config vars that can be set at workshop build time
	/// Assoc list: var_name -> list("label", "type", default)
	var/list/config_defs = list()


/// Called by circuit_board.evaluate() to compute outputs from inputs.
/// Override in all subtypes.
/datum/circuit_node/proc/evaluate()
	return

/// Convenience: get the board this node lives on
/datum/circuit_node/proc/get_board()
	return board_ref?.resolve()

/// Convenience: find installed hardware of a given type on the robot this node's board is attached to.
/// Returns null if not found or not attached.
/datum/circuit_node/proc/get_robot_hardware(hw_type)
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(!B) return null
	var/mob/living/silicon/robot/R = B.get_robot()
	if(!R || !R.installed_hardware) return null
	for(var/datum/robot_hardware/HW in R.installed_hardware)
		if(istype(HW, hw_type))
			return HW
	return null


// ====================================================
// MATH NODES
// Replaces: arithmetic.dm
// ====================================================

// -- ADD ----------------------------------------------

/datum/circuit_node/math/add
	node_name     = "Add"
	node_category = "Math"
	node_desc     = "Adds two numbers together."
	node_tutorial = "Inputs: A (number), B (number). Output: result = A + B."

/datum/circuit_node/math/add/New()
	inputs  = list("A" = 0, "B" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/add/evaluate()
	outputs["result"] = inputs["A"] + inputs["B"]


// -- SUBTRACT -----------------------------------------

/datum/circuit_node/math/subtract
	node_name     = "Subtract"
	node_category = "Math"
	node_desc     = "Subtracts B from A."
	node_tutorial = "Inputs: A (number), B (number). Output: result = A - B."

/datum/circuit_node/math/subtract/New()
	inputs  = list("A" = 0, "B" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/subtract/evaluate()
	outputs["result"] = inputs["A"] - inputs["B"]


// -- MULTIPLY -----------------------------------------

/datum/circuit_node/math/multiply
	node_name     = "Multiply"
	node_category = "Math"
	node_desc     = "Multiplies two numbers."
	node_tutorial = "Inputs: A (number), B (number). Output: result = A * B."

/datum/circuit_node/math/multiply/New()
	inputs  = list("A" = 0, "B" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/multiply/evaluate()
	outputs["result"] = inputs["A"] * inputs["B"]


// -- DIVIDE -------------------------------------------

/datum/circuit_node/math/divide
	node_name     = "Divide"
	node_category = "Math"
	node_desc     = "Divides A by B. Returns 0 if B is 0."
	node_tutorial = "Inputs: A (number), B (number). Output: result = A / B. Safe division - never crashes on zero."

/datum/circuit_node/math/divide/New()
	inputs  = list("A" = 0, "B" = 1)
	outputs = list("result" = 0)

/datum/circuit_node/math/divide/evaluate()
	outputs["result"] = inputs["B"] != 0 ? (inputs["A"] / inputs["B"]) : 0


// -- MODULO -------------------------------------------

/datum/circuit_node/math/modulo
	node_name     = "Modulo"
	node_category = "Math"
	node_desc     = "Returns the remainder of A divided by B."
	node_tutorial = "Inputs: A (number), B (number). Output: result = A % B."

/datum/circuit_node/math/modulo/New()
	inputs  = list("A" = 0, "B" = 1)
	outputs = list("result" = 0)

/datum/circuit_node/math/modulo/evaluate()
	outputs["result"] = inputs["B"] != 0 ? (inputs["A"] % inputs["B"]) : 0


// -- ABS ----------------------------------------------

/datum/circuit_node/math/abs
	node_name     = "Absolute Value"
	node_category = "Math"
	node_desc     = "Returns the absolute (positive) value of a number."
	node_tutorial = "Input: value (number). Output: result = abs(value)."

/datum/circuit_node/math/abs/New()
	inputs  = list("value" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/abs/evaluate()
	outputs["result"] = abs(inputs["value"])


// -- CLAMP --------------------------------------------

/datum/circuit_node/math/clamp
	node_name     = "Clamp"
	node_category = "Math"
	node_desc     = "Clamps a value between a minimum and maximum."
	node_tutorial = "Inputs: value, min, max. Output: result = clamp(value, min, max)."

/datum/circuit_node/math/clamp/New()
	inputs  = list("value" = 0, "min" = 0, "max" = 100)
	outputs = list("result" = 0)

/datum/circuit_node/math/clamp/evaluate()
	outputs["result"] = clamp(inputs["value"], inputs["min"], inputs["max"])


// -- MIN ----------------------------------------------

/datum/circuit_node/math/min_node
	node_name     = "Minimum"
	node_category = "Math"
	node_desc     = "Returns the smaller of two values."

/datum/circuit_node/math/min_node/New()
	inputs  = list("A" = 0, "B" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/min_node/evaluate()
	outputs["result"] = min(inputs["A"], inputs["B"])


// -- MAX ----------------------------------------------

/datum/circuit_node/math/max_node
	node_name     = "Maximum"
	node_category = "Math"
	node_desc     = "Returns the larger of two values."

/datum/circuit_node/math/max_node/New()
	inputs  = list("A" = 0, "B" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/max_node/evaluate()
	outputs["result"] = max(inputs["A"], inputs["B"])


// -- ROUND --------------------------------------------

/datum/circuit_node/math/round_node
	node_name     = "Round"
	node_category = "Math"
	node_desc     = "Rounds a number to the nearest integer or decimal place."

/datum/circuit_node/math/round_node/New()
	inputs  = list("value" = 0, "places" = 1)
	outputs = list("result" = 0)
	config_defs = list(
		"places" = list("Decimal Places", "number", 1)
	)

/datum/circuit_node/math/round_node/evaluate()
	var/places = max(1, inputs["places"])
	outputs["result"] = round(inputs["value"], places)


// -- EXPONENT -----------------------------------------

/datum/circuit_node/math/exponent
	node_name     = "Exponent"
	node_category = "Math"
	node_desc     = "Raises A to the power of B."
	node_tutorial = "Inputs: A (number), B (number). Output: result = A ^ B."

/datum/circuit_node/math/exponent/New()
	inputs  = list("A" = 0, "B" = 1)
	outputs = list("result" = 0)

/datum/circuit_node/math/exponent/evaluate()
	outputs["result"] = inputs["A"] ** inputs["B"]


// -- SIGN ---------------------------------------------

/datum/circuit_node/math/sign
	node_name     = "Sign"
	node_category = "Math"
	node_desc     = "Returns 1 if positive, -1 if negative, 0 if zero."
	node_tutorial = "Input: value (number). Output: result = sign(value)."

/datum/circuit_node/math/sign/New()
	inputs  = list("value" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/sign/evaluate()
	var/v = inputs["value"]
	outputs["result"] = v > 0 ? 1 : (v < 0 ? -1 : 0)


// -- AVERAGE ------------------------------------------

/datum/circuit_node/math/average
	node_name     = "Average"
	node_category = "Math"
	node_desc     = "Computes the average of up to four inputs. Null (0) inputs are skipped."
	node_tutorial = "Inputs: A, B, C, D (numbers). Output: average of non-zero inputs."

/datum/circuit_node/math/average/New()
	inputs  = list("A" = 0, "B" = 0, "C" = 0, "D" = 0)
	outputs = list("result" = 0, "count" = 0)

/datum/circuit_node/math/average/evaluate()
	var/sum = 0
	var/n   = 0
	for(var/key in list("A","B","C","D"))
		var/v = inputs[key]
		if(isnum(v) && v != 0)
			sum += v
			n++
	outputs["count"]  = n
	outputs["result"] = n > 0 ? (sum / n) : 0


// -- PI CONSTANT --------------------------------------

/datum/circuit_node/math/pi_const
	node_name     = "Pi"
	node_category = "Math"
	node_desc     = "Outputs the mathematical constant pi (~3.14159)."

/datum/circuit_node/math/pi_const/New()
	inputs  = list()
	outputs = list("value" = PI)

/datum/circuit_node/math/pi_const/evaluate()
	outputs["value"] = PI


// -- RANDOM -------------------------------------------

/datum/circuit_node/math/random_node
	node_name     = "Random"
	node_category = "Math"
	node_desc     = "Outputs a random integer between L and H (inclusive)."
	node_tutorial = "Inputs: L (low), H (high). Output: random integer in range L to H."

/datum/circuit_node/math/random_node/New()
	inputs  = list("L" = 1, "H" = 10)
	outputs = list("result" = 0)

/datum/circuit_node/math/random_node/evaluate()
	var/lo = round(inputs["L"])
	var/hi = round(inputs["H"])
	outputs["result"] = rand(min(lo, hi), max(lo, hi))


// ====================================================
// TRIG NODES
// Replaces: trig.dm
// ====================================================

/datum/circuit_node/math/trig/sin
	node_name     = "Sine"
	node_category = "Math/Trig"
	node_desc     = "Returns sin(angle) where angle is in degrees."

/datum/circuit_node/math/trig/sin/New()
	inputs  = list("angle" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/trig/sin/evaluate()
	outputs["result"] = sin(inputs["angle"])


/datum/circuit_node/math/trig/cos
	node_name     = "Cosine"
	node_category = "Math/Trig"
	node_desc     = "Returns cos(angle) where angle is in degrees."

/datum/circuit_node/math/trig/cos/New()
	inputs  = list("angle" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/trig/cos/evaluate()
	outputs["result"] = cos(inputs["angle"])


/datum/circuit_node/math/trig/arctan
	node_name     = "Arctangent"
	node_category = "Math/Trig"
	node_desc     = "Returns atan(y, x) in degrees. Used to compute angle between two points."

/datum/circuit_node/math/trig/arctan/New()
	inputs  = list("y" = 0, "x" = 1)
	outputs = list("angle" = 0)

/datum/circuit_node/math/trig/arctan/evaluate()
	outputs["angle"] = arctan(inputs["y"], inputs["x"])


/datum/circuit_node/math/trig/tan
	node_name     = "Tangent"
	node_category = "Math/Trig"
	node_desc     = "Returns tan(angle) where angle is in degrees."

/datum/circuit_node/math/trig/tan/New()
	inputs  = list("angle" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/trig/tan/evaluate()
	outputs["result"] = tan(inputs["angle"])


/datum/circuit_node/math/trig/sqrt
	node_name     = "Square Root"
	node_category = "Math/Trig"
	node_desc     = "Returns the square root of a value."

/datum/circuit_node/math/trig/sqrt/New()
	inputs  = list("value" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/math/trig/sqrt/evaluate()
	outputs["result"] = sqrt(max(0, inputs["value"]))


// ====================================================
// LOGIC NODES
// Replaces: logic.dm
// ====================================================

/datum/circuit_node/logic/and
	node_name     = "AND Gate"
	node_category = "Logic"
	node_desc     = "Output is TRUE only if both inputs are TRUE."

/datum/circuit_node/logic/and/New()
	inputs  = list("A" = FALSE, "B" = FALSE)
	outputs = list("result" = FALSE)

/datum/circuit_node/logic/and/evaluate()
	outputs["result"] = inputs["A"] && inputs["B"]


/datum/circuit_node/logic/or
	node_name     = "OR Gate"
	node_category = "Logic"
	node_desc     = "Output is TRUE if either input is TRUE."

/datum/circuit_node/logic/or/New()
	inputs  = list("A" = FALSE, "B" = FALSE)
	outputs = list("result" = FALSE)

/datum/circuit_node/logic/or/evaluate()
	outputs["result"] = inputs["A"] || inputs["B"]


/datum/circuit_node/logic/not
	node_name     = "NOT Gate"
	node_category = "Logic"
	node_desc     = "Inverts a boolean value."

/datum/circuit_node/logic/not/New()
	inputs  = list("A" = FALSE)
	outputs = list("result" = TRUE)

/datum/circuit_node/logic/not/evaluate()
	outputs["result"] = !inputs["A"]


/datum/circuit_node/logic/xor
	node_name     = "XOR Gate"
	node_category = "Logic"
	node_desc     = "Output is TRUE if exactly one input is TRUE."

/datum/circuit_node/logic/xor/New()
	inputs  = list("A" = FALSE, "B" = FALSE)
	outputs = list("result" = FALSE)

/datum/circuit_node/logic/xor/evaluate()
	outputs["result"] = (inputs["A"] || inputs["B"]) && !(inputs["A"] && inputs["B"])


/datum/circuit_node/logic/equals
	node_name     = "Equals"
	node_category = "Logic"
	node_desc     = "Returns TRUE if A equals B."

/datum/circuit_node/logic/equals/New()
	inputs  = list("A" = 0, "B" = 0)
	outputs = list("result" = FALSE)

/datum/circuit_node/logic/equals/evaluate()
	outputs["result"] = inputs["A"] == inputs["B"]


/datum/circuit_node/logic/compare
	node_name     = "Compare"
	node_category = "Logic"
	node_desc     = "Compares A and B with a configurable operator."
	var/operator  = ">"

/datum/circuit_node/logic/compare/New()
	inputs  = list("A" = 0, "B" = 0)
	outputs = list("result" = FALSE)
	config_defs = list(
		"operator" = list("Operator (< > == != >= <=)", "list", ">")
	)

/datum/circuit_node/logic/compare/evaluate()
	switch(operator)
		if("<")  outputs["result"] = inputs["A"] <  inputs["B"]
		if(">")  outputs["result"] = inputs["A"] >  inputs["B"]
		if("==") outputs["result"] = inputs["A"] == inputs["B"]
		if("!=") outputs["result"] = inputs["A"] != inputs["B"]
		if(">=") outputs["result"] = inputs["A"] >= inputs["B"]
		if("<=") outputs["result"] = inputs["A"] <= inputs["B"]


/datum/circuit_node/logic/if_else
	node_name     = "If/Else"
	node_category = "Logic"
	node_desc     = "Routes value_true or value_false based on condition."

/datum/circuit_node/logic/if_else/New()
	inputs  = list("condition" = FALSE, "value_true" = 1, "value_false" = 0)
	outputs = list("result" = 0)

/datum/circuit_node/logic/if_else/evaluate()
	outputs["result"] = inputs["condition"] ? inputs["value_true"] : inputs["value_false"]


// ====================================================
// CONVERTER NODES
// Replaces: converters.dm
// ====================================================

/datum/circuit_node/converter/num_to_text
	node_name     = "Number to Text"
	node_category = "Converter"
	node_desc     = "Converts a number to its text representation."

/datum/circuit_node/converter/num_to_text/New()
	inputs  = list("value" = 0)
	outputs = list("text" = "0")

/datum/circuit_node/converter/num_to_text/evaluate()
	outputs["text"] = "[inputs["value"]]"


/datum/circuit_node/converter/text_to_num
	node_name     = "Text to Number"
	node_category = "Converter"
	node_desc     = "Converts a text string to a number. Returns 0 if not numeric."

/datum/circuit_node/converter/text_to_num/New()
	inputs  = list("text" = "0")
	outputs = list("value" = 0)

/datum/circuit_node/converter/text_to_num/evaluate()
	outputs["value"] = text2num(inputs["text"]) || 0


/datum/circuit_node/converter/bool_to_num
	node_name     = "Bool to Number"
	node_category = "Converter"
	node_desc     = "Converts TRUE/FALSE to 1/0."

/datum/circuit_node/converter/bool_to_num/New()
	inputs  = list("bool" = FALSE)
	outputs = list("value" = 0)

/datum/circuit_node/converter/bool_to_num/evaluate()
	outputs["value"] = inputs["bool"] ? 1 : 0


/datum/circuit_node/converter/num_to_bool
	node_name     = "Number to Bool"
	node_category = "Converter"
	node_desc     = "Converts a number to TRUE (nonzero) or FALSE (zero)."

/datum/circuit_node/converter/num_to_bool/New()
	inputs  = list("value" = 0)
	outputs = list("bool" = FALSE)

/datum/circuit_node/converter/num_to_bool/evaluate()
	outputs["bool"] = inputs["value"] != 0


/datum/circuit_node/converter/constant
	node_name     = "Constant"
	node_category = "Converter"
	node_desc     = "Outputs a fixed constant value. Set it once at build time."
	var/const_value = 0
	var/const_type  = "number"

/datum/circuit_node/converter/constant/New()
	inputs  = list()
	outputs = list("value" = 0)
	config_defs = list(
		"const_value" = list("Constant Value", "text",   "0"),
		"const_type"  = list("Type (number/text/bool)", "list", "number")
	)

/datum/circuit_node/converter/constant/evaluate()
	switch(const_type)
		if("number") outputs["value"] = text2num(const_value) || 0
		if("bool")   outputs["value"] = const_value == "true" || const_value == "1"
		else         outputs["value"] = const_value


// ====================================================
// TEXT NODES
// Replaces: text.dm
// ====================================================

/datum/circuit_node/text/concat
	node_name     = "Concatenate"
	node_category = "Text"
	node_desc     = "Joins two strings together."

/datum/circuit_node/text/concat/New()
	inputs  = list("A" = "", "B" = "")
	outputs = list("result" = "")

/datum/circuit_node/text/concat/evaluate()
	outputs["result"] = "[inputs["A"]][inputs["B"]]"


/datum/circuit_node/text/length
	node_name     = "String Length"
	node_category = "Text"
	node_desc     = "Returns the character count of a string."

/datum/circuit_node/text/length/New()
	inputs  = list("text" = "")
	outputs = list("length" = 0)

/datum/circuit_node/text/length/evaluate()
	outputs["length"] = length(inputs["text"])


/datum/circuit_node/text/substring
	node_name     = "Substring"
	node_category = "Text"
	node_desc     = "Extracts a portion of a string from start to end index."

/datum/circuit_node/text/substring/New()
	inputs  = list("text" = "", "start" = 1, "end" = 5)
	outputs = list("result" = "")

/datum/circuit_node/text/substring/evaluate()
	var/t = inputs["text"]
	var/s = max(1, inputs["start"])
	var/e = min(length(t), inputs["end"])
	outputs["result"] = copytext(t, s, e + 1)


/datum/circuit_node/text/find
	node_name     = "Find in String"
	node_category = "Text"
	node_desc     = "Returns the position of needle in haystack, or 0 if not found."

/datum/circuit_node/text/find/New()
	inputs  = list("haystack" = "", "needle" = "")
	outputs = list("position" = 0, "found" = FALSE)

/datum/circuit_node/text/find/evaluate()
	var/pos = findtext(inputs["haystack"], inputs["needle"])
	outputs["position"] = pos
	outputs["found"]    = pos > 0


/datum/circuit_node/text/replace
	node_name     = "Replace in String"
	node_category = "Text"
	node_desc     = "Replaces all occurrences of needle in text with replacement."

/datum/circuit_node/text/replace/New()
	inputs  = list("text" = "", "needle" = "", "replacement" = "")
	outputs = list("result" = "")

/datum/circuit_node/text/replace/evaluate()
	outputs["result"] = replacetext(inputs["text"], inputs["needle"], inputs["replacement"])


/datum/circuit_node/text/uppercase
	node_name     = "Uppercase"
	node_category = "Text"
	node_desc     = "Converts a string to uppercase."

/datum/circuit_node/text/uppercase/New()
	inputs  = list("text" = "")
	outputs = list("result" = "")

/datum/circuit_node/text/uppercase/evaluate()
	outputs["result"] = uppertext(inputs["text"])


/datum/circuit_node/text/lowercase
	node_name     = "Lowercase"
	node_category = "Text"
	node_desc     = "Converts a string to lowercase."

/datum/circuit_node/text/lowercase/New()
	inputs  = list("text" = "")
	outputs = list("result" = "")

/datum/circuit_node/text/lowercase/evaluate()
	outputs["result"] = lowertext(inputs["text"])


// ====================================================
// TIMER NODES
// Replaces: time.dm
// ====================================================

/datum/circuit_node/timer/delay
	node_name     = "Delay"
	node_category = "Timer"
	node_desc     = "Passes through input after a configurable delay in deciseconds."
	var/delay_ds  = 10
	var/pending   = FALSE

/datum/circuit_node/timer/delay/New()
	inputs  = list("trigger" = FALSE, "delay_override" = 0)
	outputs = list("fired" = FALSE)
	config_defs = list(
		"delay_ds" = list("Delay (ds)", "number", 10)
	)

/datum/circuit_node/timer/delay/evaluate()
	outputs["fired"] = FALSE
	if(!inputs["trigger"] || pending)
		return
	var/actual_delay = inputs["delay_override"] > 0 ? inputs["delay_override"] : delay_ds
	pending = TRUE
	addtimer(CALLBACK(src, PROC_REF(_fire)), actual_delay)

/datum/circuit_node/timer/delay/proc/_fire()
	pending = FALSE
	outputs["fired"] = TRUE
	// Re-evaluate board so downstream nodes pick up the pulse
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(B)
		B.evaluate()
	outputs["fired"] = FALSE


/datum/circuit_node/timer/ticker
	node_name       = "Ticker"
	node_category   = "Timer"
	node_desc       = "Emits a pulse at a regular interval while enabled."
	var/interval_ds = 40
	var/is_running  = FALSE
	var/next_fire   = 0

/datum/circuit_node/timer/ticker/New()
	inputs  = list("enabled" = TRUE, "interval_override" = 0)
	outputs = list("tick" = FALSE)
	config_defs = list(
		"interval_ds" = list("Interval (ds)", "number", 40)
	)

/datum/circuit_node/timer/ticker/evaluate()
	var/should_run = inputs["enabled"]
	if(should_run && !is_running)
		is_running = TRUE
		next_fire  = world.time + interval_ds
		START_PROCESSING(SSfastprocess, src)
	else if(!should_run && is_running)
		is_running = FALSE
		STOP_PROCESSING(SSfastprocess, src)

/datum/circuit_node/timer/ticker/process()
	if(!is_running || world.time < next_fire)
		return
	var/actual_interval = inputs["interval_override"] > 0 ? inputs["interval_override"] : interval_ds
	next_fire = world.time + actual_interval
	outputs["tick"] = TRUE
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(B) B.evaluate()
	outputs["tick"] = FALSE

/datum/circuit_node/timer/ticker/Destroy()
	if(is_running)
		STOP_PROCESSING(SSfastprocess, src)
	return ..()


/datum/circuit_node/timer/stopwatch
	node_name     = "Stopwatch"
	node_category = "Timer"
	node_desc     = "Measures elapsed time since last reset. Outputs time in deciseconds."
	var/start_time = 0
	var/running    = FALSE

/datum/circuit_node/timer/stopwatch/New()
	inputs  = list("start" = FALSE, "reset" = FALSE)
	outputs = list("elapsed" = 0, "is_running" = FALSE)

/datum/circuit_node/timer/stopwatch/evaluate()
	if(inputs["reset"])
		start_time = 0
		running    = FALSE
	if(inputs["start"] && !running)
		start_time = world.time
		running    = TRUE
	outputs["elapsed"]    = running ? (world.time - start_time) : 0
	outputs["is_running"] = running


/datum/circuit_node/timer/cooldown
	node_name     = "Cooldown Gate"
	node_category = "Timer"
	node_desc     = "Passes trigger through once, then blocks it until cooldown expires."
	var/cooldown_ds = 30
	var/last_fire   = 0

/datum/circuit_node/timer/cooldown/New()
	inputs  = list("trigger" = FALSE)
	outputs = list("fired" = FALSE, "on_cooldown" = FALSE)
	config_defs = list(
		"cooldown_ds" = list("Cooldown (ds)", "number", 30)
	)

/datum/circuit_node/timer/cooldown/evaluate()
	outputs["on_cooldown"] = (world.time - last_fire) < cooldown_ds
	if(inputs["trigger"] && !outputs["on_cooldown"])
		last_fire = world.time
		outputs["fired"] = TRUE
	else
		outputs["fired"] = FALSE


/datum/circuit_node/timer/clock
	node_name     = "World Clock"
	node_category = "Timer"
	node_desc     = "Outputs current world time in deciseconds, and broken down into hours/minutes/seconds."

/datum/circuit_node/timer/clock/New()
	inputs  = list()
	outputs = list("time_ds" = 0, "hours" = 0, "minutes" = 0, "seconds" = 0)

/datum/circuit_node/timer/clock/evaluate()
	var/t = world.time
	outputs["time_ds"]  = t
	outputs["hours"]    = text2num(time2text(t, "hh"))
	outputs["minutes"]  = text2num(time2text(t, "mm"))
	outputs["seconds"]  = text2num(time2text(t, "ss"))


// ====================================================
// MEMORY NODES
// Replaces: memory.dm
// ====================================================

/datum/circuit_node/memory/register
	node_name     = "Register"
	node_category = "Memory"
	node_desc     = "Stores a single value when write is pulsed. Holds it until next write."
	var/stored = null

/datum/circuit_node/memory/register/New()
	inputs  = list("value" = 0, "write" = FALSE, "clear" = FALSE)
	outputs = list("stored" = 0, "has_value" = FALSE)

/datum/circuit_node/memory/register/evaluate()
	if(inputs["clear"])
		stored = null
	else if(inputs["write"])
		stored = inputs["value"]
	outputs["stored"]    = stored
	outputs["has_value"] = !isnull(stored)


/datum/circuit_node/memory/multi_register
	node_name     = "Multi-Register"
	node_category = "Memory"
	node_desc     = "Stores up to 4 values addressed by index (1-4)."
	var/list/slots = list(null, null, null, null)

/datum/circuit_node/memory/multi_register/New()
	inputs  = list("value" = 0, "address" = 1, "write" = FALSE, "read_address" = 1, "clear_all" = FALSE)
	outputs = list("read_value" = 0)

/datum/circuit_node/memory/multi_register/evaluate()
	if(inputs["clear_all"])
		slots = list(null, null, null, null)
	var/addr = clamp(round(inputs["address"]), 1, 4)
	if(inputs["write"])
		slots[addr] = inputs["value"]
	var/read_addr = clamp(round(inputs["read_address"]), 1, 4)
	outputs["read_value"] = slots[read_addr]


/datum/circuit_node/memory/constant_node
	node_name     = "Constant Value"
	node_category = "Memory"
	node_desc     = "A fixed value set at build time. Cannot be changed at runtime."
	var/value = 0
	var/value_type = "number"

/datum/circuit_node/memory/constant_node/New()
	inputs  = list()
	outputs = list("value" = 0)
	config_defs = list(
		"value"      = list("Value",                      "text", "0"),
		"value_type" = list("Type (number/text/bool)", "list",    "number")
	)

/datum/circuit_node/memory/constant_node/evaluate()
	switch(value_type)
		if("number") outputs["value"] = text2num("[value]") || 0
		if("bool")   outputs["value"] = value == "true" || value == "1"
		else         outputs["value"] = "[value]"


// ====================================================
// DATA ROUTER NODES
// Replaces: data_transfer.dm
// ====================================================

/datum/circuit_node/router/passthrough
	node_name     = "Passthrough"
	node_category = "Router"
	node_desc     = "Passes a value through unchanged. Useful for organizing long wire runs."

/datum/circuit_node/router/passthrough/New()
	inputs  = list("value" = 0)
	outputs = list("value" = 0)

/datum/circuit_node/router/passthrough/evaluate()
	outputs["value"] = inputs["value"]


/datum/circuit_node/router/mux
	node_name     = "Multiplexer"
	node_category = "Router"
	node_desc     = "Selects one of two inputs based on a selector boolean. A if FALSE, B if TRUE."

/datum/circuit_node/router/mux/New()
	inputs  = list("A" = 0, "B" = 0, "select" = FALSE)
	outputs = list("result" = 0)

/datum/circuit_node/router/mux/evaluate()
	outputs["result"] = inputs["select"] ? inputs["B"] : inputs["A"]


/datum/circuit_node/router/demux
	node_name     = "Demultiplexer"
	node_category = "Router"
	node_desc     = "Routes one input to output_a or output_b based on selector."

/datum/circuit_node/router/demux/New()
	inputs  = list("value" = 0, "select" = FALSE)
	outputs = list("output_a" = 0, "output_b" = 0)

/datum/circuit_node/router/demux/evaluate()
	if(inputs["select"])
		outputs["output_a"] = 0
		outputs["output_b"] = inputs["value"]
	else
		outputs["output_a"] = inputs["value"]
		outputs["output_b"] = 0


/datum/circuit_node/router/gate
	node_name     = "Gate"
	node_category = "Router"
	node_desc     = "Passes value through only when gate is TRUE. Outputs 0 when blocked."

/datum/circuit_node/router/gate/New()
	inputs  = list("value" = 0, "gate" = FALSE)
	outputs = list("result" = 0, "blocked" = FALSE)

/datum/circuit_node/router/gate/evaluate()
	if(inputs["gate"])
		outputs["result"]  = inputs["value"]
		outputs["blocked"] = FALSE
	else
		outputs["result"]  = 0
		outputs["blocked"] = TRUE


/datum/circuit_node/router/latch
	node_name     = "Latch"
	node_category = "Router"
	node_desc     = "Set/Reset latch. Output is TRUE after set pulse, FALSE after reset pulse."
	var/state = FALSE

/datum/circuit_node/router/latch/New()
	inputs  = list("set" = FALSE, "reset" = FALSE)
	outputs = list("state" = FALSE)

/datum/circuit_node/router/latch/evaluate()
	if(inputs["set"])
		state = TRUE
	if(inputs["reset"])
		state = FALSE
	outputs["state"] = state


// ====================================================
// LIST NODES
// Replaces: lists.dm
// ====================================================

/datum/circuit_node/list_node/create
	node_name     = "Create List"
	node_category = "List"
	node_desc     = "Creates a list from up to 4 input values."
	var/list/stored_list = list()

/datum/circuit_node/list_node/create/New()
	inputs  = list("item1" = null, "item2" = null, "item3" = null, "item4" = null, "build" = FALSE)
	outputs = list("list_ref" = null, "length" = 0)

/datum/circuit_node/list_node/create/evaluate()
	if(inputs["build"])
		stored_list = list()
		for(var/key in list("item1","item2","item3","item4"))
			if(!isnull(inputs[key]))
				stored_list += inputs[key]
		outputs["list_ref"] = stored_list
		outputs["length"]   = stored_list.len


/datum/circuit_node/list_node/get_index
	node_name     = "Get by Index"
	node_category = "List"
	node_desc     = "Retrieves the item at a specified index from a list."

/datum/circuit_node/list_node/get_index/New()
	inputs  = list("list_ref" = null, "index" = 1)
	outputs = list("value" = null, "valid" = FALSE)

/datum/circuit_node/list_node/get_index/evaluate()
	var/list/L = inputs["list_ref"]
	if(!islist(L))
		outputs["valid"] = FALSE
		return
	var/idx = clamp(round(inputs["index"]), 1, L.len)
	outputs["value"] = L.len >= idx ? L[idx] : null
	outputs["valid"] = L.len >= idx


/datum/circuit_node/list_node/length
	node_name     = "List Length"
	node_category = "List"
	node_desc     = "Returns the number of items in a list."

/datum/circuit_node/list_node/length/New()
	inputs  = list("list_ref" = null)
	outputs = list("length" = 0)

/datum/circuit_node/list_node/length/evaluate()
	var/list/L = inputs["list_ref"]
	outputs["length"] = islist(L) ? L.len : 0


/datum/circuit_node/list_node/contains
	node_name     = "List Contains"
	node_category = "List"
	node_desc     = "Returns TRUE if the list contains the given value."

/datum/circuit_node/list_node/contains/New()
	inputs  = list("list_ref" = null, "value" = null)
	outputs = list("found" = FALSE, "index" = 0)

/datum/circuit_node/list_node/contains/evaluate()
	var/list/L = inputs["list_ref"]
	if(!islist(L))
		outputs["found"] = FALSE
		outputs["index"] = 0
		return
	var/idx = L.Find(inputs["value"])
	outputs["found"] = idx > 0
	outputs["index"] = idx


/datum/circuit_node/list_node/pick_random
	node_name     = "Pick Random"
	node_category = "List"
	node_desc     = "Picks a random item from the list."

/datum/circuit_node/list_node/pick_random/New()
	inputs  = list("list_ref" = null, "trigger" = FALSE)
	outputs = list("value" = null, "valid" = FALSE)

/datum/circuit_node/list_node/pick_random/evaluate()
	if(!inputs["trigger"])
		return
	var/list/L = inputs["list_ref"]
	if(!islist(L) || !L.len)
		outputs["valid"] = FALSE
		return
	outputs["value"] = pick(L)
	outputs["valid"] = TRUE


/datum/circuit_node/list_node/filter
	node_name     = "Filter List"
	node_category = "List"
	node_desc     = "Returns a new list containing only items matching a threshold comparison."
	var/operator = ">"
	var/list/stored_result = list()

/datum/circuit_node/list_node/filter/New()
	inputs  = list("list_ref" = null, "threshold" = 0, "build" = FALSE)
	outputs = list("result_list" = null, "count" = 0)
	config_defs = list(
		"operator" = list("Operator (< > == !=)", "list", ">")
	)

/datum/circuit_node/list_node/filter/evaluate()
	if(!inputs["build"])
		return
	var/list/L = inputs["list_ref"]
	if(!islist(L))
		return
	stored_result = list()
	var/thresh = inputs["threshold"]
	for(var/item in L)
		var/passes = FALSE
		switch(operator)
			if("<")  passes = item <  thresh
			if(">")  passes = item >  thresh
			if("==") passes = item == thresh
			if("!=") passes = item != thresh
		if(passes)
			stored_result += item
	outputs["result_list"] = stored_result
	outputs["count"]       = stored_result.len


// ====================================================
// ROBOT READER NODES
// These nodes read live values from the installed robot.
// No SS13 equivalent - F13 native.
// Allow circuit_board logic to react to robot state.
// ====================================================

/datum/circuit_node/robot_reader/health
	node_name     = "Robot Health"
	node_category = "Robot Reader"
	node_desc     = "Outputs the robot's current health and health percentage."

/datum/circuit_node/robot_reader/health/New()
	inputs  = list()
	outputs = list("health" = 0, "max_health" = 0, "health_pct" = 0)

/datum/circuit_node/robot_reader/health/evaluate()
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(!B) return
	var/mob/living/silicon/robot/R = B.get_robot()
	if(!R) return
	outputs["health"]     = R.health
	outputs["max_health"] = R.maxHealth
	outputs["health_pct"] = (R.health / max(R.maxHealth, 1)) * 100


/datum/circuit_node/robot_reader/position
	node_name     = "Robot Position"
	node_category = "Robot Reader"
	node_desc     = "Outputs the robot's current X/Y/Z coordinates."

/datum/circuit_node/robot_reader/position/New()
	inputs  = list()
	outputs = list("x" = 0, "y" = 0, "z" = 0)

/datum/circuit_node/robot_reader/position/evaluate()
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(!B) return
	var/mob/living/silicon/robot/R = B.get_robot()
	if(!R) return
	outputs["x"] = R.x
	outputs["y"] = R.y
	outputs["z"] = R.z


/datum/circuit_node/robot_reader/enemy_count
	node_name     = "Nearby Enemy Count"
	node_category = "Robot Reader"
	node_desc     = "Counts hostile mobs within a configurable radius."
	var/scan_radius = 10

/datum/circuit_node/robot_reader/enemy_count/New()
	inputs  = list()
	outputs = list("count" = 0, "enemies_present" = FALSE)
	config_defs = list(
		"scan_radius" = list("Scan Radius", "number", 10)
	)

/datum/circuit_node/robot_reader/enemy_count/evaluate()
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(!B) return
	var/mob/living/silicon/robot/R = B.get_robot()
	if(!R) return
	var/count = 0
	for(var/mob/living/M in range(scan_radius, R))
		if(M == R || M.stat == DEAD) continue
		if(!R.faction_check_mob(M, FALSE))
			count++
	outputs["count"]           = count
	outputs["enemies_present"] = count > 0


/datum/circuit_node/robot_reader/world_time
	node_name     = "World Time"
	node_category = "Robot Reader"
	node_desc     = "Outputs the current world time in deciseconds."

/datum/circuit_node/robot_reader/world_time/New()
	inputs  = list()
	outputs = list("time_ds" = 0)

/datum/circuit_node/robot_reader/world_time/evaluate()
	outputs["time_ds"] = world.time


/datum/circuit_node/robot_reader/power
	node_name     = "Robot Power"
	node_category = "Robot Reader"
	node_desc     = "Outputs the robot's current cell charge, max charge, charge percentage, and low-power flag."

/datum/circuit_node/robot_reader/power/New()
	inputs  = list()
	outputs = list("charge" = 0, "max_charge" = 0, "charge_pct" = 0, "low_power" = FALSE)

/datum/circuit_node/robot_reader/power/evaluate()
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(!B) return
	var/mob/living/silicon/robot/R = B.get_robot()
	if(!R) return
	var/obj/item/stock_parts/cell/C = R.cell
	if(!C)
		outputs["charge"]     = 0
		outputs["max_charge"] = 0
		outputs["charge_pct"] = 0
		outputs["low_power"]  = TRUE
		return
	outputs["charge"]     = C.charge
	outputs["max_charge"] = C.maxcharge
	outputs["charge_pct"] = (C.charge / max(1, C.maxcharge)) * 100
	outputs["low_power"]  = R.low_power_mode


/datum/circuit_node/robot_reader/combat_state
	node_name     = "Combat State"
	node_category = "Robot Reader"
	node_desc     = "Outputs whether the robot is in combat mode and how long since it last took damage."

/datum/circuit_node/robot_reader/combat_state/New()
	inputs  = list()
	outputs = list("in_combat" = FALSE, "time_since_damage" = 0)

/datum/circuit_node/robot_reader/combat_state/evaluate()
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(!B) return
	var/mob/living/silicon/robot/R = B.get_robot()
	if(!R) return
	outputs["in_combat"] = (R.a_intent == INTENT_HARM)
	if(R.last_damage_time)
		outputs["time_since_damage"] = world.time - R.last_damage_time
	else
		outputs["time_since_damage"] = 0


/datum/circuit_node/robot_reader/friendly_count
	node_name     = "Nearby Friend Count"
	node_category = "Robot Reader"
	node_desc     = "Counts friendly mobs within a configurable radius. Skips neutral/silicon false-positives."
	var/scan_radius = 10

/datum/circuit_node/robot_reader/friendly_count/New()
	inputs  = list()
	outputs = list("count" = 0, "friendlies_present" = FALSE)
	config_defs = list(
		"scan_radius" = list("Scan Radius", "number", 10)
	)

/datum/circuit_node/robot_reader/friendly_count/evaluate()
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(!B) return
	var/mob/living/silicon/robot/R = B.get_robot()
	if(!R) return
	var/count = 0
	for(var/mob/living/M in range(scan_radius, R))
		if(M == R || M.stat == DEAD) continue
		if(_is_faction_friend(R, M))
			count++
	outputs["count"]             = count
	outputs["friendlies_present"] = count > 0


/datum/circuit_node/robot_reader/nav_state
	node_name     = "Nav State"
	node_category = "Robot Reader"
	node_desc     = "Reads the installed nav_computer state: patrol mode, current waypoint index, and total waypoints."

/datum/circuit_node/robot_reader/nav_state/New()
	inputs  = list()
	outputs = list("has_nav" = FALSE, "patrol_mode" = "none", "current_waypoint" = 0, "waypoint_count" = 0)

/datum/circuit_node/robot_reader/nav_state/evaluate()
	var/datum/robot_hardware/nav_computer/NAV = get_robot_hardware(/datum/robot_hardware/nav_computer)
	if(!NAV)
		outputs["has_nav"]          = FALSE
		outputs["patrol_mode"]      = "none"
		outputs["current_waypoint"] = 0
		outputs["waypoint_count"]   = 0
		return
	outputs["has_nav"]          = TRUE
	outputs["patrol_mode"]      = NAV.patrol_mode
	outputs["current_waypoint"] = NAV.current_waypoint
	outputs["waypoint_count"]   = NAV.waypoints ? NAV.waypoints.len : 0


/datum/circuit_node/robot_reader/memory_key
	node_name     = "Memory Key"
	node_category = "Robot Reader"
	node_desc     = "Reads a named key from the robot's memory_core. Outputs the value as both a number and text."
	var/key_name  = "key"

/datum/circuit_node/robot_reader/memory_key/New()
	inputs  = list()
	outputs = list("num_value" = 0, "text_value" = "", "has_value" = FALSE)
	config_defs = list(
		"key_name" = list("Memory Key Name", "text", "key")
	)

/datum/circuit_node/robot_reader/memory_key/evaluate()
	var/datum/robot_hardware/memory_core/MEM = get_robot_hardware(/datum/robot_hardware/memory_core)
	if(!MEM || !MEM.memory || !(key_name in MEM.memory))
		outputs["num_value"]  = 0
		outputs["text_value"] = ""
		outputs["has_value"]  = FALSE
		return
	var/val = MEM.memory[key_name]
	outputs["has_value"]  = TRUE
	outputs["num_value"]  = isnull(val) ? 0 : text2num("[val]") || 0
	outputs["text_value"] = isnull(val) ? "" : "[val]"


/datum/circuit_node/robot_reader/robot_status
	node_name     = "Robot Status"
	node_category = "Robot Reader"
	node_desc     = "Outputs boolean flags for robot operational state: alive, locked down, emagged, ion-pulsed."

/datum/circuit_node/robot_reader/robot_status/New()
	inputs  = list()
	outputs = list("is_alive" = FALSE, "locked_down" = FALSE, "emagged" = FALSE, "ionpulse_active" = FALSE)

/datum/circuit_node/robot_reader/robot_status/evaluate()
	var/datum/robot_hardware/circuit_board/B = get_board()
	if(!B) return
	var/mob/living/silicon/robot/R = B.get_robot()
	if(!R) return
	outputs["is_alive"]       = (R.stat != DEAD)
	outputs["locked_down"]    = R.locked_down
	outputs["emagged"]        = R.emagged
	outputs["ionpulse_active"] = R.ionpulse_on


// ====================================================
// NODE CATALOG
// All available node types grouped by category.
// Used by the workshop circuit editor picker.
// ====================================================

/datum/circuit_node_catalog
	var/static/list/all_types = list(
		// Math
		/datum/circuit_node/math/add,
		/datum/circuit_node/math/subtract,
		/datum/circuit_node/math/multiply,
		/datum/circuit_node/math/divide,
		/datum/circuit_node/math/modulo,
		/datum/circuit_node/math/abs,
		/datum/circuit_node/math/clamp,
		/datum/circuit_node/math/min_node,
		/datum/circuit_node/math/max_node,
		/datum/circuit_node/math/round_node,
		/datum/circuit_node/math/exponent,
		/datum/circuit_node/math/sign,
		/datum/circuit_node/math/average,
		/datum/circuit_node/math/pi_const,
		/datum/circuit_node/math/random_node,
		// Trig
		/datum/circuit_node/math/trig/sin,
		/datum/circuit_node/math/trig/cos,
		/datum/circuit_node/math/trig/tan,
		/datum/circuit_node/math/trig/arctan,
		/datum/circuit_node/math/trig/sqrt,
		// Logic
		/datum/circuit_node/logic/and,
		/datum/circuit_node/logic/or,
		/datum/circuit_node/logic/not,
		/datum/circuit_node/logic/xor,
		/datum/circuit_node/logic/equals,
		/datum/circuit_node/logic/compare,
		/datum/circuit_node/logic/if_else,
		// Converter
		/datum/circuit_node/converter/num_to_text,
		/datum/circuit_node/converter/text_to_num,
		/datum/circuit_node/converter/bool_to_num,
		/datum/circuit_node/converter/num_to_bool,
		/datum/circuit_node/converter/constant,
		// Text
		/datum/circuit_node/text/concat,
		/datum/circuit_node/text/length,
		/datum/circuit_node/text/substring,
		/datum/circuit_node/text/find,
		/datum/circuit_node/text/replace,
		/datum/circuit_node/text/uppercase,
		/datum/circuit_node/text/lowercase,
		// Timer
		/datum/circuit_node/timer/delay,
		/datum/circuit_node/timer/ticker,
		/datum/circuit_node/timer/stopwatch,
		/datum/circuit_node/timer/cooldown,
		/datum/circuit_node/timer/clock,
		// Memory
		/datum/circuit_node/memory/register,
		/datum/circuit_node/memory/multi_register,
		/datum/circuit_node/memory/constant_node,
		// Router
		/datum/circuit_node/router/passthrough,
		/datum/circuit_node/router/mux,
		/datum/circuit_node/router/demux,
		/datum/circuit_node/router/gate,
		/datum/circuit_node/router/latch,
		// List
		/datum/circuit_node/list_node/create,
		/datum/circuit_node/list_node/get_index,
		/datum/circuit_node/list_node/length,
		/datum/circuit_node/list_node/contains,
		/datum/circuit_node/list_node/pick_random,
		/datum/circuit_node/list_node/filter,
		// Robot Reader
		/datum/circuit_node/robot_reader/health,
		/datum/circuit_node/robot_reader/position,
		/datum/circuit_node/robot_reader/enemy_count,
		/datum/circuit_node/robot_reader/world_time,
		/datum/circuit_node/robot_reader/power,
		/datum/circuit_node/robot_reader/combat_state,
		/datum/circuit_node/robot_reader/friendly_count,
		/datum/circuit_node/robot_reader/nav_state,
		/datum/circuit_node/robot_reader/memory_key,
		/datum/circuit_node/robot_reader/robot_status
	)
