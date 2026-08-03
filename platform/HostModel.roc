## Internal records and effects that mirror the low-level guest ABI.
## Applications should use `Model`, which translates these shapes into domain types.
HostModel := [].{
	ModelInfo : {
		model_digest : Str,
		spec42_version : Str,
		semantic_api_version : Str,
	}

	ElementSummary : {
		handle : Str,
		semantic_id : Str,
		metaclass : Str,
		name : [None, Some(Str)],
		qualified_name : Str,
		library_element : Bool,
	}

	SourceRange : {
		start_line : U32,
		start_character : U32,
		end_line : U32,
		end_character : U32,
	}

	Multiplicity : {
		lower : [None, Some(Str)],
		upper : [None, Some(Str)],
		ordered : Bool,
		unique : [None, Some(Bool)],
		implied : Bool,
	}

	ElementDetail : {
		summary : ElementSummary,
		owner : [None, Some(ElementSummary)],
		declared_name : [None, Some(Str)],
		effective_name : [None, Some(Str)],
		source_uri : Str,
		source_range : SourceRange,
		definition : Bool,
		documentation : [None, Some(Str)],
		short_name : [None, Some(Str)],
		direction : [None, Some(Str)],
		derived : Bool,
		constant : Bool,
		abstract_flag : Bool,
		variation : Bool,
		individual : Bool,
		conjugated : Bool,
		composite : [None, Some(Bool)],
		reference : [None, Some(Bool)],
		end : Bool,
		ordered : [None, Some(Bool)],
		unique : [None, Some(Bool)],
		multiplicity : [None, Some(Multiplicity)],
		evaluated_value : [None, Some(Str)],
	}

	Relationship : {
		kind : Str,
		source : ElementSummary,
		target : ElementSummary,
		implied : Bool,
	}

	info! : () => ModelInfo

	roots! : () => Try(List(ElementSummary), Str)

	find! : [None, Some(Str)] => Try(List(ElementSummary), Str)

	children! : Str => Try(List(ElementSummary), Str)

	element! : Str => Try(ElementDetail, Str)

	typed_by! : Str => Try([None, Some(ElementSummary)], Str)

	relationships! : Str => Try(List(Relationship), Str)

	effective_features! : Str => Try(List(ElementSummary), Str)
}
