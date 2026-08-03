app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model
import "state_explorer.html" as explorer_template : Str

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

json_edge : Model.Relationship -> Str
json_edge = |relationship|
	"{from:\"${display_name(relationship.source)}\",to:\"${display_name(relationship.target)}\"}"

render_state_explorer : Str -> Str
render_state_explorer = |edges| explorer_template.replace_each("{{EDGES}}", edges)

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
main! = |_args| {
	states = Model.find!(ByMetaclass(Metaclass("StateUsage")))?
	relationships = collect_relationships!(states)?
	transitions = relationships.keep_if(is_transition)
	edges = Str.join_with(transitions.map(json_edge), ",")
	html = render_state_explorer(edges)
	Diagnostics.log!(Info, "generated interactive state explorer")
	Ok([{ file_path: "warehouse-robot-state-explorer.html", contents: html.to_utf8() }])
}

## Transition relationships become state-explorer edge objects.
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
		\\is transition: ${Str.inspect(is_transition(transition))}
		\\json edge: ${json_edge(transition)}

	expected =
		\\is transition: True
		\\json edge: {from:"booting",to:"idle"}

	actual == expected
}
