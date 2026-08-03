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

is_connection : Model.Relationship -> Bool
is_connection = |relationship|
	match relationship.kind {
		RelationshipKind(kind) => kind == "connection"
	}

connection_edge : Model.Relationship -> Str
connection_edge = |relationship|
	"  \"${relationship.source.qualified_name}\" -> \"${relationship.target.qualified_name}\" [dir=both, arrowhead=none, arrowtail=none];"

port_node : Model.ElementSummary -> Str
port_node = |port|
	"  \"${port.qualified_name}\" [label=\"${display_name(port)}\"]"

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
main! = |_args| {
	ports = Model.find!(ByMetaclass(Metaclass("PortUsage")))?
	relationships = collect_relationships!(ports)?
	connections = relationships.keep_if(is_connection)
	dot =
		\\digraph GroundStationInterfaces {
		\\  rankdir=LR;
		\\  graph [fontname="Helvetica", bgcolor="#071525"];
		\\  node [fontname="Helvetica", shape=component, style=filled, fillcolor="#dbeafe", color="#0284c7"];
		\\  edge [color="#38bdf8", penwidth=2];
		\\${Str.join_with(ports.map(port_node), "\n")}
		\\${Str.join_with(connections.map(connection_edge), "\n")}
		\\}
	Diagnostics.log!(Info, "generated interface network with ${connections.len().to_str()} connections")
	Ok([{ file_path: "ground-station-interface-network.dot", contents: dot.to_utf8() }])
}

## Connection relationships render as bidirectional Graphviz edges.
expect {
	source = {
		handle: ElementHandle("mission-control-port"),
		semantic_id: SemanticId("GS-MCS-PORT"),
		metaclass: Metaclass("PortUsage"),
		name: Named("MissionControlPort"),
		qualified_name: "GroundStation::MissionControlSystem::port",
		origin: WorkspaceElement,
	}
	target = {
		handle: ElementHandle("antenna-port"),
		semantic_id: SemanticId("GS-ANT-PORT"),
		metaclass: Metaclass("PortUsage"),
		name: Named("AntennaPort"),
		qualified_name: "GroundStation::AntennaSystem::port",
		origin: WorkspaceElement,
	}
	connection = {
		kind: RelationshipKind("connection"),
		source,
		target,
		implied: False,
	}

	actual =
		\\is connection: ${Str.inspect(is_connection(connection))}
		\\edge: ${connection_edge(connection)}

	expected =
		\\is connection: True
		\\edge:   "GroundStation::MissionControlSystem::port" -> "GroundStation::AntennaSystem::port" [dir=both, arrowhead=none, arrowtail=none];

	actual == expected
}
