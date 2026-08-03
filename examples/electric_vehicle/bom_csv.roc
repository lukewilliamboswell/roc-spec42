app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model

display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

is_attribute = |element|
	match element.metaclass {
		Metaclass(name) => name == "AttributeUsage"
	}

attribute_cell! = |attribute| {
	detail = Model.element!(attribute.handle)?
	value = match detail.evaluation {
		Evaluated(text) => text
		NotEvaluated => "not evaluated"
	}
	Ok("${display_name(attribute)}=${value}")
}

part_row! = |part| {
	features = Model.effective_features!(part.handle)?
	attributes = features.keep_if(is_attribute)
	cells = attributes.map_try!(attribute_cell!)?
	Ok("\"${display_name(part)}\",\"${part.qualified_name}\",\"${Str.join_with(cells, "; ")}\"")
}

main! = |_args| {
	parts = Model.find!(ByMetaclass(Metaclass("PartDefinition")))?
	rows = parts.map_try!(part_row!)?
	csv =
		\\part,qualified_name,modelled_attributes
		\\${Str.join_with(rows, "\n")}
	Diagnostics.log!(Info, "generated design bill of materials for ${parts.len().to_str()} part definitions")
	Ok([{ file_path: "electric-vehicle-bom.csv", contents: csv.to_utf8() }])
}
