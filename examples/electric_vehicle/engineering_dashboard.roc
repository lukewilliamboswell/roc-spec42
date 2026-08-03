app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Artifacts
import spec42.Diagnostics
import spec42.Model

display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

cards = |elements, accent|
	Str.join_with(
		elements.map(|element| "<article style=\"border-left:4px solid ${accent}\"><strong>${display_name(element)}</strong><small>${element.qualified_name}</small></article>"),
		"\n",
	)

main! = |_args| {
	info = Model.info!()
	parts = Model.find!(ByMetaclass(Metaclass("PartDefinition")))?
	requirements = Model.find!(ByMetaclass(Metaclass("RequirementDefinition")))?
	verifications = Model.find!(ByMetaclass(Metaclass("VerificationCaseDefinition")))?
	html =
		\\<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Electric vehicle engineering dashboard</title>
		\\<style>body{font:16px system-ui;margin:0;background:#f5f7fa;color:#172033}header{padding:2.5rem;background:#102a43;color:white}main{max-width:1100px;margin:auto;padding:2rem}.metrics,.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:1rem}.metric,article{background:white;padding:1rem;border-radius:.6rem;box-shadow:0 2px 10px #102a4314}.metric b{display:block;font-size:2rem;color:#00796b}small{display:block;color:#64748b;margin-top:.4rem}h2{margin-top:2.5rem}</style>
		\\<header><h1>Electric vehicle engineering dashboard</h1><p>Generated directly from model ${info.model_digest}</p></header><main>
		\\<section class="metrics"><div class="metric"><b>${parts.len().to_str()}</b>part definitions</div><div class="metric"><b>${requirements.len().to_str()}</b>requirements</div><div class="metric"><b>${verifications.len().to_str()}</b>verification cases</div></section>
		\\<h2>Propulsion architecture</h2><section class="grid">${cards(parts, "#00796b")}</section>
		\\<h2>Requirements baseline</h2><section class="grid">${cards(requirements, "#f59e0b")}</section>
		\\<h2>Verification campaign</h2><section class="grid">${cards(verifications, "#2563eb")}</section>
		\\</main></html>
	Artifacts.emit!("engineering-dashboard.html", html.to_utf8())?
	Diagnostics.log!(Info, "generated electric-vehicle engineering dashboard")
	Ok({})
}
