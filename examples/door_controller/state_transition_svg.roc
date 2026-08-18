app [main!] {
	spec42: platform "../../platform/main.roc",
	layout: "https://github.com/lukewilliamboswell/roc-graph-layout/releases/download/0.1.0/2xyQdrf7DWirDTNyDySCGS8euQm8U7aBumTPnqhQgSSF.tar.zst",
}

import spec42.StateTransition
import layout.Geom
import layout.Layered

padding = 28
frame_header = 34

escape = |text|
	text
		.replace_each("&", "&amp;")
		.replace_each("<", "&lt;")
		.replace_each(">", "&gt;")
		.replace_each("\"", "&quot;")
		.replace_each("'", "&apos;")

semantic_text = |SemanticId(value)| value

source_attributes = |source|
	\\data-source-uri="${escape(source.uri)}" data-source-start-line="${source.range.start_line.to_str()}" data-source-start-character="${source.range.start_character.to_str()}" data-source-end-line="${source.range.end_line.to_str()}" data-source-end-character="${source.range.end_character.to_str()}"

node_size = |node|
	match node.kind {
		Initial => { width: 18, height: 18 }
		Final => { width: 22, height: 22 }
		State => { width: (node.label.count_utf8_bytes().to_f64() * 8 + 30).max(96), height: 48 }
	}

node_index = |nodes, SemanticId(wanted)|
	nodes.fold_with_index(
		None,
		|found, node, index| {
			SemanticId(actual) = node.semantic_id
			match found {
				Some(_) => found
				None => if actual == wanted Some(index) else None
			}
		},
	)

layout_edge = |nodes, edge|
	match (node_index(nodes, edge.source), node_index(nodes, edge.target)) {
		(Some(from), Some(to)) => Ok({ from, to })
		_ => Err("transition ${semantic_text(edge.semantic_id)} refers to a node outside its typed projection")
	}

transition_label = |edge|
	match (edge.label, edge.trigger) {
		(_, UnsupportedTrigger(reason)) => Err("unsupported trigger ${reason.code}: ${reason.message}")
		(Labelled(label), _) => Ok(label)
		(Unlabelled, AcceptTrigger(accept)) => Ok(accept.label)
		(Unlabelled, NoTrigger) => Ok("")
		_ => Err("unknown transition trigger variant")
	}

reject_feature = |role, feature|
	match feature {
		Absent => Ok({})
		Unsupported(reason) => Err("unsupported ${role} ${reason.code}: ${reason.message}")
		Supported(_) => Err("${role} notation is outside this spike")
		Unresolved => Err("unresolved ${role}")
		Ambiguous => Err("ambiguous ${role}")
		Recovery => Err("parser recovery affects ${role}")
	}

validate_transition = |edge| {
	_ = reject_feature("guard", edge.guard)?
	_ = reject_feature("effect", edge.effect)?
	_ = transition_label(edge)?
	Ok({})
}

route_path = |route|
	match route {
		Line(from, to) => "M ${from.x.to_str()} ${from.y.to_str()} L ${to.x.to_str()} ${to.y.to_str()}"
		Polyline(points) =>
			Str.join_with(points.map_with_index(|point, i| "${if i == 0 "M" else "L"} ${point.x.to_str()} ${point.y.to_str()}"), " ")
		Curves(segments) =>
			Str.join_with(segments.map_with_index(
				|segment, i| "${if i == 0 "M ${segment.from.x.to_str()} ${segment.from.y.to_str()} " else ""}C ${segment.ctl_a.x.to_str()} ${segment.ctl_a.y.to_str()} ${segment.ctl_b.x.to_str()} ${segment.ctl_b.y.to_str()} ${segment.to.x.to_str()} ${segment.to.y.to_str()}",
			), " ")
	}

render_node = |node, position| {
	id = escape(semantic_text(node.semantic_id))
	common = "data-semantic-id=\"${id}\" ${source_attributes(node.source)}"
	match node.kind {
		Initial =>
			\\<g data-kind="initial" ${common}><circle cx="${position.x.to_str()}" cy="${position.y.to_str()}" r="9" fill="#111827" /></g>
		Final =>
			\\<g data-kind="final" ${common}><circle cx="${position.x.to_str()}" cy="${position.y.to_str()}" r="10" fill="#fff" stroke="#111827" stroke-width="2" /><circle cx="${position.x.to_str()}" cy="${position.y.to_str()}" r="5" fill="#111827" /></g>
		State => {
			size = node_size(node)
			x = position.x - size.width / 2
			y = position.y - size.height / 2
			\\<g data-kind="state" ${common}><rect x="${x.to_str()}" y="${y.to_str()}" width="${size.width.to_str()}" height="${size.height.to_str()}" rx="8" fill="#fff" stroke="#111827" stroke-width="1.5" /><text x="${position.x.to_str()}" y="${position.y.to_str()}" text-anchor="middle" dominant-baseline="middle">${escape(node.label)}</text></g>
		}
	}
}

render_edge = |edge, route| {
	label = match transition_label(edge) { Ok(value) => value Err(_) => "" }
	anchor = match route {
		Line(from, to) => { x: (from.x + to.x) / 2, y: (from.y + to.y) / 2 - 8 }
		Polyline(points) => points.get(points.len() / 2) ?? Geom.point(0, 0)
		Curves(segments) => match segments.get(0) { Ok(segment) => { x: (segment.from.x + segment.to.x) / 2, y: (segment.from.y + segment.to.y) / 2 - 8 } Err(_) => Geom.point(0, 0) }
	}
	label_svg = if label.is_empty() "" else "<text class=\"transition-label\" x=\"${anchor.x.to_str()}\" y=\"${anchor.y.to_str()}\" text-anchor=\"middle\">${escape(label)}</text>"
	\\<g data-kind="transition" data-semantic-id="${escape(semantic_text(edge.semantic_id))}" ${source_attributes(edge.source_reference)}><path d="${route_path(route)}" fill="none" stroke="#374151" stroke-width="1.5" marker-end="url(#transition-arrow)" />${label_svg}</g>
}

render = |view| {
	match view.completeness {
		Incomplete(reasons) => Err("state-transition projection is incomplete: ${Str.join_with(reasons.map(|r| "${r.code}: ${r.message}"), "; ")}")
		Complete => {
			edges = view.transitions.map_try!(|edge| {
				_ = validate_transition(edge)?
				layout_edge(view.nodes, edge)
			})?
			input = { ..Layered.default_input, graph: { nodes: view.nodes.map(node_size), edges } }
			settings = { ..Layered.default_settings, direction: Right, node_gap: 36, layer_gap: 76 }
			result = match Layered.layout(input, settings, Layered.default_run) {
				Ok(value) => value
				Err(_) => return Err("layout rejected typed projection")
			}
			geometry = result.layout
			width = geometry.bounds.width + padding * 2
			height = geometry.bounds.height + padding * 2 + frame_header
			nodes_svg = Str.join_with(view.nodes.map_with_index(|node, i| render_node(node, geometry.positions.get(i) ?? Geom.point(0, 0))), "\n")
			edges_svg = Str.join_with(view.transitions.map_with_index(|edge, i| render_edge(edge, geometry.routes.get(i) ?? Line(Geom.point(0, 0), Geom.point(0, 0)))), "\n")
			Ok(
				\\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width.to_str()} ${height.to_str()}" data-artifact-version="1" data-model-digest="${escape(view.model_digest)}" data-view-name="${escape(view.view.name)}" data-view-semantic-id="${escape(semantic_text(view.view.semantic_id))}">
				\\<title>${escape(view.view.name)}</title><desc>SysML state-transition view of ${escape(view.machine.label)}</desc>
				\\<defs><marker id="transition-arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#374151" /></marker></defs>
				\\<style>text { font-family: sans-serif; font-size: 14px; fill: #111827; } .transition-label { font-size: 12px; }</style>
				\\<rect x="0.75" y="0.75" width="${(width - 1.5).to_str()}" height="${(height - 1.5).to_str()}" fill="#fff" stroke="#111827" stroke-width="1.5" />
				\\<g data-kind="frame"><text x="${padding.to_str()}" y="22" font-weight="600">state transition view ${escape(view.view.name)} [${escape(view.machine.label)}]</text></g>
				\\<g transform="translate(${padding.to_str()} ${(padding + frame_header).to_str()})"><g data-layer="edges">${edges_svg}</g><g data-layer="nodes">${nodes_svg}</g></g>
				\\</svg>
			)
		}
	}
}

select_view! = |selector| {
	views = StateTransition.views!()?
	selected = match selector {
		Some(wanted) => views.keep_if(|view| if view.name == wanted True else if semantic_text(view.semantic_id) == wanted True else view.source.uri == wanted)
		None => views
	}
	match selected {
		[only] => Ok(only)
		[] => Err(if views.is_empty() "no authored StateTransitionView is available" else "view selector did not match a view name, semantic ID, or source URI")
		_ => Err("multiple StateTransitionViews are available; pass a view name or semantic ID after --")
	}
}

main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
main! = |args| {
	selector = match args.get(0) { Ok(value) => Some(value) Err(_) => None }
	summary = select_view!(selector)?
	projection = StateTransition.view!(summary.handle)?
	svg = render(projection)?
	Ok([{ file_path: "door-controller.svg", contents: svg.to_utf8() }])
}

expect escape("a<&\"'") == "a&lt;&amp;&quot;&apos;"

expect transition_label({ label: Unlabelled, trigger: AcceptTrigger({ label: "OpenRequested", target: NoTarget, source: { uri: "model.sysml", range: { start_line: 0, start_character: 0, end_line: 0, end_character: 1 } } }) }) == Ok("OpenRequested")

expect node_size({ label: "closed", kind: State }).height == 48

fixture_source : StateTransition.SourceReference
fixture_source = { uri: "model.sysml", range: { start_line: 0, start_character: 0, end_line: 0, end_character: 1 } }

fixture_view : StateTransition.View
fixture_view = {
	schema_version: 1,
	model_digest: "digest<&",
	view: {
		handle: ViewHandle("view-1"),
		semantic_id: SemanticId("view-lifecycle"),
		name: "lifecycle",
		exposed_machine: { semantic_id: SemanticId("machine-door"), label: "DoorLifecycle" },
		source: fixture_source,
	},
	machine: { semantic_id: SemanticId("machine-door"), label: "DoorLifecycle", source: fixture_source },
	nodes: [
		{ semantic_id: SemanticId("initial"), label: "", kind: Initial, source: fixture_source },
		{ semantic_id: SemanticId("closed"), label: "closed", kind: State, source: fixture_source },
		{ semantic_id: SemanticId("open"), label: "open", kind: State, source: fixture_source },
		{ semantic_id: SemanticId("retired"), label: "retired", kind: Final, source: fixture_source },
	],
	transitions: [
		{ semantic_id: SemanticId("start"), label: Unlabelled, source: SemanticId("initial"), target: SemanticId("closed"), trigger: NoTrigger, guard: Absent, effect: Absent, provenance: Authored, source_reference: fixture_source },
		{ semantic_id: SemanticId("open-door"), label: Unlabelled, source: SemanticId("closed"), target: SemanticId("open"), trigger: AcceptTrigger({ label: "OpenRequested", target: NoTarget, source: fixture_source }), guard: Absent, effect: Absent, provenance: Authored, source_reference: fixture_source },
		{ semantic_id: SemanticId("retire"), label: Unlabelled, source: SemanticId("open"), target: SemanticId("retired"), trigger: NoTrigger, guard: Absent, effect: Absent, provenance: Authored, source_reference: fixture_source },
	],
	completeness: Complete,
}

## The notation and SVG boundary is deterministic and preserves supported
## normative glyphs, trigger text, provenance, and escaped model-derived text.
expect {
	svg = render(fixture_view)?
	svg.contains("data-kind=\"initial\"") and svg.contains("data-kind=\"state\"") and svg.contains("data-kind=\"final\"") and svg.contains("OpenRequested") and svg.contains("data-semantic-id=\"closed\"") and svg.contains("data-model-digest=\"digest&lt;&amp;\"") and !svg.contains("<script")
}

## Unsupported optional semantics cannot silently disappear from a diagram.
expect {
	bad = { ..fixture_view, transitions: [{ ..fixture_view.transitions.get(0)?, guard: Unresolved }] }
	match render(bad) {
		Err("unresolved guard") => True
		_ => False
	}
}
