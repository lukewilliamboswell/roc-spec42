app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model

display_name : Model.ElementSummary -> Str
display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

collect_relationships! : List(Model.ElementSummary) => Try(List(Model.Relationship), Str)
collect_relationships! = |elements| {
	groups = elements.map_try!(|element| Model.relationships!(element.handle))?
	Ok(groups.join())
}

is_transition : Model.Relationship -> Bool
is_transition = |relationship|
	match relationship.kind {
		RelationshipKind(kind) => kind == "transition"
	}

transition_edge : Model.Relationship -> Str
transition_edge = |relationship|
	"  \"${display_name(relationship.source)}\" -> \"${display_name(relationship.target)}\";"

state_node : Model.ElementSummary -> Str
state_node = |state|
	"  \"${display_name(state)}\" [label=\"${display_name(state)}\"]"

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
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
	Diagnostics.log!(Info, "generated Graphviz state-machine view with ${transitions.len().to_str()} transitions")
	Ok([{ file_path: "warehouse-robot-state-machine.dot", contents: dot.to_utf8() }])
}

## States and transitions render as stable Graphviz statements.
expect {
	booting = {
		handle: ElementHandle("booting"),
		semantic_id: SemanticId("WR-BOOTING"),
		metaclass: Metaclass("StateUsage"),
		name: Named("booting"),
		qualified_name: "WarehouseRobot::Mission::booting",
		origin: WorkspaceElement,
	}
	idle = {
		handle: ElementHandle("idle"),
		semantic_id: SemanticId("WR-IDLE"),
		metaclass: Metaclass("StateUsage"),
		name: Named("idle"),
		qualified_name: "WarehouseRobot::Mission::idle",
		origin: WorkspaceElement,
	}
	transition = {
		kind: RelationshipKind("transition"),
		source: booting,
		target: idle,
		implied: False,
	}

	actual =
		\\state: ${state_node(booting)}
		\\transition: ${transition_edge(transition)}

	expected =
		\\state:   "booting" [label="booting"]
		\\transition:   "booting" -> "idle";

	actual == expected
}
