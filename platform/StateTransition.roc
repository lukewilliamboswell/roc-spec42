import HostStateTransition

## A typed, bounded projection of model-authored SysML state-transition views.
##
## Spec42 owns view selection, state-machine membership, resolved endpoints,
## display labels, and completeness. Generator applications own notation and
## rendering and must not reconstruct these semantics with generic model scans.
StateTransition := [].{
	ViewHandle := [ViewHandle(Str)]
	SemanticId := [SemanticId(Str)]

	SourceRange : {
		start_line : U32,
		start_character : U32,
		end_line : U32,
		end_character : U32,
	}

	SourceReference : { uri : Str, range : SourceRange }

	ElementIdentity : { semantic_id : SemanticId, label : Str }

	UnsupportedReason : { code : Str, message : Str }

	ViewSummary : {
		handle : ViewHandle,
		semantic_id : SemanticId,
		name : Str,
		exposed_machine : ElementIdentity,
		source : SourceReference,
	}

	MachineSummary : {
		semantic_id : SemanticId,
		label : Str,
		source : SourceReference,
	}

	NodeKind := [Initial, State, Final]

	Node : {
		semantic_id : SemanticId,
		label : Str,
		kind : NodeKind,
		source : SourceReference,
	}

	Trigger := [
		NoTrigger,
		AcceptTrigger({ label : Str, target : [NoTarget, Target(ElementIdentity)], source : SourceReference }),
		UnsupportedTrigger(UnsupportedReason),
	]

	Feature := [
		Absent,
		Supported({ label : Str, source : SourceReference }),
		Unsupported(UnsupportedReason),
		Unresolved,
		Ambiguous,
		Recovery,
	]

	Provenance := [Authored, Implied]

	Completeness := [Complete, Incomplete(List(UnsupportedReason))]

	Transition : {
		semantic_id : SemanticId,
		label : [Unlabelled, Labelled(Str)],
		source : SemanticId,
		target : SemanticId,
		trigger : Trigger,
		guard : Feature,
		effect : Feature,
		provenance : Provenance,
		source_reference : SourceReference,
	}

	View : {
		schema_version : U32,
		model_digest : Str,
		view : ViewSummary,
		machine : MachineSummary,
		nodes : List(Node),
		transitions : List(Transition),
		completeness : Completeness,
	}

	## List model-authored state-transition views in canonical publication order.
	views! : () => Try(List(ViewSummary), Str)
	views! = ||
		match HostStateTransition.views!() {
			Ok(values) => Ok(values.map(to_view_summary))
			Err(message) => Err(message)
		}

	## Resolve one catalog handle into a complete typed projection.
	view! : ViewHandle => Try(View, Str)
	view! = |ViewHandle(handle)|
		match HostStateTransition.view!(handle) {
			Ok(value) => Ok(to_view(value))
			Err(message) => Err(message)
		}
}

to_source : HostStateTransition.SourceReference -> StateTransition.SourceReference
to_source = |value| { uri: value.uri, range: value.range }

to_identity : HostStateTransition.ElementIdentity -> StateTransition.ElementIdentity
to_identity = |value| { semantic_id: SemanticId(value.semantic_id), label: value.label }

to_view_summary : HostStateTransition.ViewSummary -> StateTransition.ViewSummary
to_view_summary = |value| {
	handle: ViewHandle(value.handle),
	semantic_id: SemanticId(value.semantic_id),
	name: value.name,
	exposed_machine: to_identity(value.exposed_machine),
	source: to_source(value.source),
}

to_machine : HostStateTransition.MachineSummary -> StateTransition.MachineSummary
to_machine = |value| {
	semantic_id: SemanticId(value.semantic_id),
	label: value.label,
	source: to_source(value.source),
}

to_node : HostStateTransition.Node -> StateTransition.Node
to_node = |value| {
	semantic_id: SemanticId(value.semantic_id),
	label: value.label,
	kind: if value.kind == 0 Initial else if value.kind == 1 State else Final,
	source: to_source(value.source),
}

to_optional_identity : [None, Some(HostStateTransition.ElementIdentity)] -> [NoTarget, Target(StateTransition.ElementIdentity)]
to_optional_identity = |value|
	match value {
		None => NoTarget
		Some(identity) => Target(to_identity(identity))
	}

to_trigger : HostStateTransition.Trigger -> StateTransition.Trigger
to_trigger = |value|
	if value.kind == 0 {
		NoTrigger
	} else if value.kind == 1 {
		AcceptTrigger({
			label: match value.label { Some(label) => label None => "" },
			target: to_optional_identity(value.target),
			source: match value.source { Some(source) => to_source(source) None => { uri: "", range: { start_line: 0, start_character: 0, end_line: 0, end_character: 0 } } },
		})
	} else {
		UnsupportedTrigger(match value.unsupported { Some(reason) => reason None => { code: "invalid-trigger", message: "invalid trigger projection" } })
	}

to_feature : HostStateTransition.Feature -> StateTransition.Feature
to_feature = |value|
	if value.kind == 0 Absent else if value.kind == 1 {
		Supported({ label: match value.label { Some(label) => label None => "" }, source: match value.source { Some(source) => to_source(source) None => { uri: "", range: { start_line: 0, start_character: 0, end_line: 0, end_character: 0 } } } })
	} else if value.kind == 2 {
		Unsupported(match value.unsupported { Some(reason) => reason None => { code: "invalid-feature", message: "invalid feature projection" } })
	} else if value.kind == 3 Unresolved else if value.kind == 4 Ambiguous else Recovery

to_label : [None, Some(Str)] -> [Unlabelled, Labelled(Str)]
to_label = |value|
	match value {
		None => Unlabelled
		Some(label) => Labelled(label)
	}

to_transition : HostStateTransition.Transition -> StateTransition.Transition
to_transition = |value| {
	semantic_id: SemanticId(value.semantic_id),
	label: to_label(value.label),
	source: SemanticId(value.source),
	target: SemanticId(value.target),
	trigger: to_trigger(value.trigger),
	guard: to_feature(value.guard),
	effect: to_feature(value.effect),
	provenance: if value.implied Implied else Authored,
	source_reference: to_source(value.source_reference),
}

to_view : HostStateTransition.View -> StateTransition.View
to_view = |value| {
	schema_version: value.schema_version,
	model_digest: value.model_digest,
	view: to_view_summary(value.view),
	machine: to_machine(value.machine),
	nodes: value.nodes.map(to_node),
	transitions: value.transitions.map(to_transition),
	completeness: if value.completeness.complete Complete else Incomplete(value.completeness.reasons),
}
