app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model

display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

json_names = |elements|
	Str.join_with(elements.map(|element| "    \"${display_name(element)}\""), ",\n")

main! = |args| {
	info = Model.info!()
	states = Model.find!(ByMetaclass(Metaclass("StateUsage")))?
	transitions = Model.find!(ByMetaclass(Metaclass("transition")))?
	events = Model.find!(ByMetaclass(Metaclass("ActionDefinition")))?
	manifest =
		\\{
		\\  "schema": "roc-spec42/warehouse-robot-simulation-v1",
		\\  "modelDigest": "${info.model_digest}",
		\\  "arguments": [${Str.join_with(args.map(|arg| "\"${arg}\""), ", ")}],
		\\  "initialState": "booting",
		\\  "states": [
		\\${json_names(states)}
		\\  ],
		\\  "events": [
		\\${json_names(events)}
		\\  ],
		\\  "transitionDefinitions": [
		\\${json_names(transitions)}
		\\  ]
		\\}
	controller_properties =
		\\model.digest=${info.model_digest}
		\\initial.state=booting
		\\state.count=${states.len().to_str()}
		\\event.count=${events.len().to_str()}
		\\transition-definition.count=${transitions.len().to_str()}
	Diagnostics.log!(Info, "generated simulation/control manifest")
	Ok([
		{ file_path: "warehouse-robot-simulation.json", contents: manifest.to_utf8() },
		{ file_path: "simulation/warehouse-robot.properties", contents: controller_properties.to_utf8() },
	])
}
