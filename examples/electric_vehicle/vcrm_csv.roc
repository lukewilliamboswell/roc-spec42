app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model

display_name : Model.ElementSummary -> Str
display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

semantic_id : Model.SemanticId -> Str
semantic_id = |SemanticId(value)| value

relationship_kind : Model.RelationshipKind -> Str
relationship_kind = |RelationshipKind(value)| value

collect_relationships! : List(Model.ElementSummary) => Try(List(Model.Relationship), Str)
collect_relationships! = |elements| {
	groups = elements.map_try!(|element| Model.relationships!(element.handle))?
	Ok(groups.join())
}

sources_for : Model.ElementSummary, List(Model.Relationship), Str -> Str
sources_for = |requirement, relationships, kind|
	relationships
		.keep_if(|relationship|
			semantic_id(relationship.target.semantic_id) == semantic_id(requirement.semantic_id) and relationship_kind(relationship.kind) == kind)
		.map(|relationship| display_name(relationship.source))
		|> Str.join_with("; ")

attribute_pair! : Model.ElementSummary => Try(Str, Str)
attribute_pair! = |attribute| {
	detail = Model.element!(attribute.handle)?
	value = match detail.evaluation {
		Evaluated(text) => text
		NotEvaluated => "not evaluated"
	}
	Ok("${display_name(attribute)}=${value}")
}

requirement_row! : Model.ElementSummary, List(Model.Relationship) => Try(Str, Str)
requirement_row! = |requirement, relationships| {
	features = Model.effective_features!(requirement.handle)?
	pairs = features.map_try!(attribute_pair!)?
	satisfied_by = sources_for(requirement, relationships, "satisfy")
	verified_by = sources_for(requirement, relationships, "subject")
	Ok("\"${display_name(requirement)}\",\"${requirement.qualified_name}\",\"${Str.join_with(pairs, "; ")}\",\"${satisfied_by}\",\"${verified_by}\"")
}

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
main! = |_args| {
	all_elements = Model.find!(AllElements)?
	requirements = Model.find!(ByMetaclass(Metaclass("RequirementDefinition")))?
	relationships = collect_relationships!(all_elements)?
	rows = requirements.map_try!(|requirement| requirement_row!(requirement, relationships))?
	csv =
		\\requirement,qualified_name,modelled_attributes,satisfied_by,verified_by
		\\${Str.join_with(rows, "\n")}
	Diagnostics.log!(Info, "generated verification cross-reference matrix for ${requirements.len().to_str()} requirements")
	Ok([{ file_path: "electric-vehicle-vcrm.csv", contents: csv.to_utf8() }])
}

## Relationship lookup selects matching links and renders their source names.
expect {
	requirement = {
		handle: ElementHandle("range-requirement"),
		semantic_id: SemanticId("EV-RANGE"),
		metaclass: Metaclass("RequirementDefinition"),
		name: Named("DrivingRangeRequirement"),
		qualified_name: "ElectricVehicle::DrivingRangeRequirement",
		origin: WorkspaceElement,
	}
	source = {
		handle: ElementHandle("battery-system"),
		semantic_id: SemanticId("EV-BATTERY"),
		metaclass: Metaclass("PartDefinition"),
		name: Named("BatterySystem"),
		qualified_name: "ElectricVehicle::BatterySystem",
		origin: WorkspaceElement,
	}
	relationship = {
		kind: RelationshipKind("satisfy"),
		source,
		target: requirement,
		implied: False,
	}

	sources_for(requirement, [relationship], "satisfy") == "BatterySystem"
}
