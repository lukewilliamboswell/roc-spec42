app [main!] { spec42: platform "../../platform/main.roc" }

import spec42.Artifacts
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

is_transition = |relationship|
	match relationship.kind {
		RelationshipKind(kind) => kind == "transition"
	}

json_edge = |relationship|
	"{from:\"${display_name(relationship.source)}\",to:\"${display_name(relationship.target)}\"}"

main! = |_args| {
	states = Model.find!(ByMetaclass(Metaclass("StateUsage")))?
	relationships = collect_relationships!(states)?
	transitions = relationships.keep_if(is_transition)
	edges = Str.join_with(transitions.map(json_edge), ",")
	html =
		\\<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Warehouse robot state explorer</title>
		\\<style>body{font:16px system-ui;margin:0;background:#f1f5f9;color:#172033}header{background:#172554;color:white;padding:2rem}main{max-width:850px;margin:auto;padding:2rem}.panel{background:white;border-radius:.8rem;padding:1.5rem;box-shadow:0 8px 30px #0f172a18}.state{font-size:2.2rem;color:#1d4ed8;margin:.5rem 0 1.5rem}button{display:block;width:100%;text-align:left;margin:.6rem 0;padding:.8rem;border:1px solid #93c5fd;background:#eff6ff;border-radius:.45rem;cursor:pointer}button:hover{background:#dbeafe}.history{font-family:monospace;color:#475569}</style>
		\\<header><h1>Autonomous warehouse robot</h1><p>Interactive state explorer generated from the mission state machine</p></header><main><section class="panel"><small>CURRENT STATE</small><div id="state" class="state"></div><h2>Legal transitions</h2><div id="choices"></div><h2>Execution history</h2><div id="history" class="history"></div><button id="reset">Reset to booting</button></section></main>
		\\<script>const edges=[${edges}];let current='booting',history=[];const state=document.querySelector('#state'),choices=document.querySelector('#choices'),trail=document.querySelector('#history');function render(){state.textContent=current;trail.textContent=history.length?history.join(' → '):'No transitions executed';choices.replaceChildren();const next=edges.filter(e=>e.from===current);if(!next.length){choices.textContent='No outgoing transition is modelled.';return}next.forEach(e=>{const b=document.createElement('button');b.textContent='Transition to '+e.to;b.onclick=()=>{history.push(current);current=e.to;render()};choices.appendChild(b)})}document.querySelector('#reset').onclick=()=>{current='booting';history=[];render()};render();</script></html>
	Artifacts.emit!("warehouse-robot-state-explorer.html", html.to_utf8())?
	Diagnostics.log!(Info, "generated interactive state explorer")
	Ok({})
}
