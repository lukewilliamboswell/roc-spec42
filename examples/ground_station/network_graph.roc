app [main!] { spec42: platform "../../platform/main.roc" }

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

is_connection = |relationship|
	match relationship.kind {
		RelationshipKind(kind) => kind == "connection"
	}

connection_edge = |relationship|
	"  \"${relationship.source.qualified_name}\" -> \"${relationship.target.qualified_name}\" [dir=both, arrowhead=none, arrowtail=none];"

port_node = |port|
	"  \"${port.qualified_name}\" [label=\"${display_name(port)}\"]"

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
