app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model
import "operations_dashboard.html" as dashboard_template : Str

DashboardData : {
	model_digest : Str,
	systems : List(Model.ElementSummary),
	ports : List(Model.ElementSummary),
	activities : List(Model.ElementSummary),
	requirements : List(Model.ElementSummary),
}

display_name : Model.ElementSummary -> Str
display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

rows : List(Model.ElementSummary) -> Str
rows = |elements|
	Str.join_with(elements.map(|element| "<tr><td>${display_name(element)}</td><td><code>${element.qualified_name}</code></td></tr>"), "\n")

render_dashboard : DashboardData -> Str
render_dashboard = |{ model_digest, systems, ports, activities, requirements }|
	dashboard_template
		.replace_each("{{MODEL_DIGEST}}", model_digest)
		.replace_each("{{SYSTEM_COUNT}}", systems.len().to_str())
		.replace_each("{{PORT_COUNT}}", ports.len().to_str())
		.replace_each("{{ACTIVITY_COUNT}}", activities.len().to_str())
		.replace_each("{{REQUIREMENT_COUNT}}", requirements.len().to_str())
		.replace_each("{{ACTIVITY_ROWS}}", rows(activities))
		.replace_each("{{SYSTEM_ROWS}}", rows(systems))
		.replace_each("{{PORT_ROWS}}", rows(ports))

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
main! = |_args| {
	info = Model.info!()
	systems = Model.find!(ByMetaclass(Metaclass("PartDefinition")))?
	ports = Model.find!(ByMetaclass(Metaclass("PortUsage")))?
	activities = Model.find!(ByMetaclass(Metaclass("ActionDefinition")))?
	requirements = Model.find!(ByMetaclass(Metaclass("RequirementDefinition")))?
	html = render_dashboard({ model_digest: info.model_digest, systems, ports, activities, requirements })
	Diagnostics.log!(Info, "generated ground-station operations dashboard")
	Ok([{ file_path: "ground-station-operations.html", contents: html.to_utf8() }])
}

## Dashboard table rows include human and qualified element names.
expect {
	element = {
		handle: ElementHandle("publish-products"),
		semantic_id: SemanticId("GS-PUBLISH"),
		metaclass: Metaclass("ActionDefinition"),
		name: Named("PublishProducts"),
		qualified_name: "GroundStation::PublishProducts",
		origin: WorkspaceElement,
	}

	rows([element]) == "<tr><td>PublishProducts</td><td><code>GroundStation::PublishProducts</code></td></tr>"
}
