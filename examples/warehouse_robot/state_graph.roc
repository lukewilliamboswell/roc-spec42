app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Artifacts
import spec42.Diagnostics
import spec42.Model

display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

collect_relationships! = |elements| {
	groups = elements.map_try!(|element| Model.relationships!(element.handle))?
	Ok(groups.join())
}

is_transition = |relationship|
	match relationship.kind {
		RelationshipKind(kind) => kind == "transition"
	}

transition_edge = |relationship|
	"  \"${display_name(relationship.source)}\" -> \"${display_name(relationship.target)}\";"

state_node = |state|
	"  \"${display_name(state)}\" [label=\"${display_name(state)}\"]"

main! = |_args| {
	states = Model.find!(ByMetaclass(Metaclass("StateUsage")))?
	relationships = collect_relationships!(states)?
	transitions = relationships.keep_if(is_transition)
	dot =
		\\digraph WarehouseRobotMission {
		\\  rankdir=LR;
		\\  graph [fontname="Helvetica", bgcolor="#f8fafc"];
		\\  node [fontname="Helvetica", shape=box, style="rounded,filled", fillcolor="#dbeafe", color="#2563eb"];
		\\  edge [fontname="Helvetica", color="#475569"];
		\\${Str.join_with(states.map(state_node), "\n")}
		\\${Str.join_with(transitions.map(transition_edge), "\n")}
		\\}
	Artifacts.emit!("warehouse-robot-state-machine.dot", dot.to_utf8())?
	Diagnostics.log!(Info, "generated Graphviz state-machine view with ${transitions.len().to_str()} transitions")
	Ok({})
}
