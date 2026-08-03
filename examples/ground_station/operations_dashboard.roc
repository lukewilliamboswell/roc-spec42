app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Artifacts
import spec42.Diagnostics
import spec42.Model

display_name = |element|
	match element.name {
		Named(name) => name
		Unnamed => element.qualified_name
	}

rows = |elements|
	Str.join_with(elements.map(|element| "<tr><td>${display_name(element)}</td><td><code>${element.qualified_name}</code></td></tr>"), "\n")

main! = |_args| {
	info = Model.info!()
	systems = Model.find!(ByMetaclass(Metaclass("PartDefinition")))?
	ports = Model.find!(ByMetaclass(Metaclass("PortUsage")))?
	activities = Model.find!(ByMetaclass(Metaclass("ActionDefinition")))?
	requirements = Model.find!(ByMetaclass(Metaclass("RequirementDefinition")))?
	html =
		\\<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Ground station operations</title>
		\\<style>body{font:15px system-ui;margin:0;background:#071525;color:#dbeafe}header{padding:2rem 5vw;background:linear-gradient(120deg,#0f2f54,#075985)}main{max-width:1050px;margin:auto;padding:2rem}.kpis{display:flex;gap:1rem;flex-wrap:wrap}.kpi{background:#102a43;padding:1rem 1.5rem;border-radius:.6rem;min-width:130px}.kpi b{font-size:2rem;display:block;color:#38bdf8}section{margin-top:2rem;background:#0d2238;padding:1.2rem;border-radius:.7rem}table{width:100%;border-collapse:collapse}td{padding:.55rem;border-bottom:1px solid #284866}code{color:#7dd3fc}</style>
		\\<header><h1>Satellite ground-station operations</h1><p>Configuration snapshot ${info.model_digest}</p></header><main>
		\\<div class="kpis"><div class="kpi"><b>${systems.len().to_str()}</b>systems</div><div class="kpi"><b>${ports.len().to_str()}</b>interfaces</div><div class="kpi"><b>${activities.len().to_str()}</b>pass activities</div><div class="kpi"><b>${requirements.len().to_str()}</b>critical requirements</div></div>
		\\<section><h2>Operational sequence catalogue</h2><table>${rows(activities)}</table></section>
		\\<section><h2>Ground segment assets</h2><table>${rows(systems)}</table></section>
		\\<section><h2>External and internal interfaces</h2><table>${rows(ports)}</table></section>
		\\</main></html>
	Artifacts.emit!("ground-station-operations.html", html.to_utf8())?
	Diagnostics.log!(Info, "generated ground-station operations dashboard")
	Ok({})
}
