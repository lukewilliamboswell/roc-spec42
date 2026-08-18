## Internal records and effects that mirror the low-level guest ABI for the
## bounded state-transition projection. Applications should use `StateTransition`.
HostStateTransition := [].{
	SourceRange : {
		start_line : U32,
		start_character : U32,
		end_line : U32,
		end_character : U32,
	}

	SourceReference : { uri : Str, range : SourceRange }

	ElementIdentity : { semantic_id : Str, label : Str }

	UnsupportedReason : { code : Str, message : Str }

	ViewSummary : {
		handle : Str,
		semantic_id : Str,
		name : Str,
		exposed_machine : ElementIdentity,
		source : SourceReference,
	}

	MachineSummary : {
		semantic_id : Str,
		label : Str,
		source : SourceReference,
	}

	Node : {
		semantic_id : Str,
		label : Str,
		kind : U8,
		source : SourceReference,
	}

	Trigger : {
		kind : U8,
		label : [None, Some(Str)],
		target : [None, Some(ElementIdentity)],
		source : [None, Some(SourceReference)],
		unsupported : [None, Some(UnsupportedReason)],
	}

	Feature : {
		kind : U8,
		label : [None, Some(Str)],
		source : [None, Some(SourceReference)],
		unsupported : [None, Some(UnsupportedReason)],
	}

	Completeness : { complete : Bool, reasons : List(UnsupportedReason) }

	Transition : {
		semantic_id : Str,
		label : [None, Some(Str)],
		source : Str,
		target : Str,
		trigger : Trigger,
		guard : Feature,
		effect : Feature,
		implied : Bool,
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

	views! : () => Try(List(ViewSummary), Str)

	view! : Str => Try(View, Str)
}
