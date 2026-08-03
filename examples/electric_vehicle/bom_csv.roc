app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model

display_name : Model.ElementSummary -> Str
display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

is_attribute : Model.ElementSummary -> Bool
is_attribute = |element|
	match element.metaclass {
		Metaclass(name) => name == "AttributeUsage"
	}

attribute_cell! : Model.ElementSummary => Try(Str, Str)
attribute_cell! = |attribute| {
	detail = Model.element!(attribute.handle)?
	value = match detail.evaluation {
		Evaluated(text) => text
		NotEvaluated => "not evaluated"
	}
	Ok("${display_name(attribute)}=${value}")
}

part_row! : Model.ElementSummary => Try(Str, Str)
part_row! = |part| {
	features = Model.effective_features!(part.handle)?
	attributes = features.keep_if(is_attribute)
	cells = attributes.map_try!(attribute_cell!)?
	Ok("\"${display_name(part)}\",\"${part.qualified_name}\",\"${Str.join_with(cells, "; ")}\"")
}

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
main! = |_args| {
	parts = Model.find!(ByMetaclass(Metaclass("PartDefinition")))?
	rows = parts.map_try!(part_row!)?
	csv =
		\\part,qualified_name,modelled_attributes
		\\${Str.join_with(rows, "\n")}
	Diagnostics.log!(Info, "generated design bill of materials for ${parts.len().to_str()} part definitions")
	Ok([{ file_path: "electric-vehicle-bom.csv", contents: csv.to_utf8() }])
}

## Element helpers render names and identify attribute usages.
expect {
	element = {
		handle: ElementHandle("battery-capacity"),
		semantic_id: SemanticId("EV-BAT-82"),
		metaclass: Metaclass("AttributeUsage"),
		name: Named("capacity"),
		qualified_name: "ElectricVehicle::Battery::capacity",
		origin: WorkspaceElement,
	}

	actual =
		\\display name: ${display_name(element)}
		\\is attribute: ${Str.inspect(is_attribute(element))}

	expected =
		\\display name: capacity
		\\is attribute: True

	actual == expected
}
