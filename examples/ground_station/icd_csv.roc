app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model

display_name : Model.ElementSummary -> Str
display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

direction_name : Model.Direction -> Str
direction_name = |direction|
	match direction {
		DirectionUnspecified => "unspecified"
		Directed(value) => value
	}

port_row! : Model.ElementSummary => Try(Str, Str)
port_row! = |port| {
	detail = Model.element!(port.handle)?
	type_binding = Model.typed_by!(port.handle)?
	type_name = match type_binding {
		Untyped => "untyped"
		TypedBy(port_type) => display_name(port_type)
	}
	owner_name = match detail.owner {
		RootElement => "root"
		OwnedBy(owner) => display_name(owner)
	}
	Ok("\"${owner_name}\",\"${display_name(port)}\",\"${type_name}\",\"${direction_name(detail.direction)}\",\"${port.qualified_name}\"")
}

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
main! = |_args| {
	ports = Model.find!(ByMetaclass(Metaclass("PortUsage")))?
	rows = ports.map_try!(port_row!)?
	csv =
		\\system,interface,type,direction,qualified_name
		\\${Str.join_with(rows, "\n")}
	Diagnostics.log!(Info, "generated interface-control register for ${ports.len().to_str()} ports")
	Ok([{ file_path: "ground-station-icd.csv", contents: csv.to_utf8() }])
}

## Interface directions preserve modelled values and name the unspecified state.
expect {
	actual =
		\\specified: ${direction_name(Directed("out"))}
		\\unspecified: ${direction_name(DirectionUnspecified)}

	expected =
		\\specified: out
		\\unspecified: unspecified

	actual == expected
}
