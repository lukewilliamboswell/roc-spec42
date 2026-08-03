app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Diagnostics
import spec42.Model
import "engineering_dashboard.html" as dashboard_template : Str

DashboardData : {
	model_digest : Str,
	parts : List(Model.ElementSummary),
	requirements : List(Model.ElementSummary),
	verifications : List(Model.ElementSummary),
}

display_name : Model.ElementSummary -> Str
display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

cards : List(Model.ElementSummary), Str -> Str
cards = |elements, accent|
	Str.join_with(
		elements.map(|element| "<article style=\"border-left:4px solid ${accent}\"><strong>${display_name(element)}</strong><small>${element.qualified_name}</small></article>"),
		"\n",
	)

render_dashboard : DashboardData -> Str
render_dashboard = |{ model_digest, parts, requirements, verifications }|
	dashboard_template
		.replace_each("{{MODEL_DIGEST}}", model_digest)
		.replace_each("{{PART_COUNT}}", parts.len().to_str())
		.replace_each("{{REQUIREMENT_COUNT}}", requirements.len().to_str())
		.replace_each("{{VERIFICATION_COUNT}}", verifications.len().to_str())
		.replace_each("{{PART_CARDS}}", cards(parts, "#00796b"))
		.replace_each("{{REQUIREMENT_CARDS}}", cards(requirements, "#f59e0b"))
		.replace_each("{{VERIFICATION_CARDS}}", cards(verifications, "#2563eb"))

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
main! = |_args| {
	info = Model.info!()
	parts = Model.find!(ByMetaclass(Metaclass("PartDefinition")))?
	requirements = Model.find!(ByMetaclass(Metaclass("RequirementDefinition")))?
	verifications = Model.find!(ByMetaclass(Metaclass("VerificationCaseDefinition")))?
	html = render_dashboard({ model_digest: info.model_digest, parts, requirements, verifications })
	Diagnostics.log!(Info, "generated electric-vehicle engineering dashboard")
	Ok([{ file_path: "engineering-dashboard.html", contents: html.to_utf8() }])
}

## Dashboard cards include the display name, qualified name, and requested accent.
expect {
	element = {
		handle: ElementHandle("traction-motor"),
		semantic_id: SemanticId("EV-MOTOR"),
		metaclass: Metaclass("PartDefinition"),
		name: Named("TractionMotor"),
		qualified_name: "ElectricVehicle::TractionMotor",
		origin: WorkspaceElement,
	}

	cards([element], "#00796b") == "<article style=\"border-left:4px solid #00796b\"><strong>TractionMotor</strong><small>ElectricVehicle::TractionMotor</small></article>"
}
