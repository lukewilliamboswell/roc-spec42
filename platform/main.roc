platform ""
	requires {
		main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
	}
	exposes [Model, Diagnostics, StateTransition]
	packages {}
	provides { "roc_generate": generate_for_host! }
	hosted {
		"roc_diagnostics_log": HostDiagnostics.log!,
		"roc_diagnostics_report": HostDiagnostics.report!,
		"roc_model_children": HostModel.children!,
		"roc_model_effective_features": HostModel.effective_features!,
		"roc_model_element": HostModel.element!,
		"roc_model_find": HostModel.find!,
		"roc_model_info": HostModel.info!,
		"roc_model_relationships": HostModel.relationships!,
		"roc_model_roots": HostModel.roots!,
		"roc_model_typed_by": HostModel.typed_by!,
		"roc_state_transition_view": HostStateTransition.view!,
		"roc_state_transition_views": HostStateTransition.views!,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			output: Shared,
			exports: ["spec42_abi_version", "spec42_alloc", "spec42_generate"],
		},
	}

import Model
import HostModel
import Diagnostics
import HostDiagnostics
import StateTransition
import HostStateTransition

generate_for_host! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)
generate_for_host! = |args| main!(args)
