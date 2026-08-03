import HostModel

to_summary = |value| {
	handle: ElementHandle(value.handle),
	semantic_id: SemanticId(value.semantic_id),
	metaclass: Metaclass(value.metaclass),
	name: to_name(value.name),
	qualified_name: value.qualified_name,
	origin: if value.library_element LibraryElement else WorkspaceElement,
}

map_summaries_result = |result|
	match result {
		Ok(values) => Ok(values.map(to_summary))
		Err(message) => Err(message)
	}

to_name = |value|
	match value {
		None => Unnamed
		Some(name) => Named(name)
	}

to_documentation = |value|
	match value {
		None => Undocumented
		Some(text) => Documented(text)
	}

to_direction = |value|
	match value {
		None => DirectionUnspecified
		Some(direction) => Directed(direction)
	}

to_bound = |value|
	match value {
		None => BoundUnspecified
		Some(bound) => SpecifiedBound(bound)
	}

to_ordering = |value|
	match value {
		None => OrderingUnspecified
		Some(True) => Ordered
		Some(False) => Unordered
	}

to_uniqueness = |value|
	match value {
		None => UniquenessUnspecified
		Some(True) => Unique
		Some(False) => NonUnique
	}

to_composition = |value|
	match value {
		None => CompositionUnspecified
		Some(True) => Composite
		Some(False) => NotComposite
	}

to_reference_kind = |value|
	match value {
		None => ReferenceUnspecified
		Some(True) => Reference
		Some(False) => NotReference
	}

to_multiplicity = |value|
	match value {
		None => NoMultiplicity
		Some(multiplicity) => HasMultiplicity({
			lower: to_bound(multiplicity.lower),
			upper: to_bound(multiplicity.upper),
			ordering: if multiplicity.ordered Ordered else Unordered,
			uniqueness: to_uniqueness(multiplicity.unique),
			implied: multiplicity.implied,
		})
	}

to_evaluation = |value|
	match value {
		None => NotEvaluated
		Some(evaluated) => Evaluated(evaluated)
	}

to_owner = |value|
	match value {
		None => RootElement
		Some(owner) => OwnedBy(to_summary(owner))
	}

to_detail = |value| {
	summary: to_summary(value.summary),
	owner: to_owner(value.owner),
	declared_name: to_name(value.declared_name),
	effective_name: to_name(value.effective_name),
	source_uri: value.source_uri,
	source_range: value.source_range,
	definition: value.definition,
	documentation: to_documentation(value.documentation),
	short_name: to_name(value.short_name),
	direction: to_direction(value.direction),
	derived: value.derived,
	constant: value.constant,
	abstract_flag: value.abstract_flag,
	variation: value.variation,
	individual: value.individual,
	conjugated: value.conjugated,
	composition: to_composition(value.composite),
	reference_kind: to_reference_kind(value.reference),
	end: value.end,
	ordering: to_ordering(value.ordered),
	uniqueness: to_uniqueness(value.unique),
	multiplicity: to_multiplicity(value.multiplicity),
	evaluation: to_evaluation(value.evaluated_value),
}

to_relationship = |value| {
	kind: RelationshipKind(value.kind),
	source: to_summary(value.source),
	target: to_summary(value.target),
	implied: value.implied,
}

## Read-only access to the semantic model loaded by Spec42.
##
## The public types describe domain states explicitly. Raw optional records used by the
## WebAssembly boundary are translated by the platform before applications receive them.
Model := [].{

	## An opaque element reference valid for the current generator invocation.
	ElementHandle := [ElementHandle(Str)]

	## A deterministic semantic identity suitable for provenance and comparison.
	SemanticId := [SemanticId(Str)]

	## The normative metaclass name assigned to an element.
	Metaclass := [Metaclass(Str)]

	## An element's declared or effective name, including the explicitly unnamed state.
	Name := [Unnamed, Named(Str)]

	## Whether an element came from the input workspace or a loaded library.
	Origin := [WorkspaceElement, LibraryElement]

	## The ownership state of an element.
	Owner := [RootElement, OwnedBy(ElementSummary)]

	## Documentation attached to an element.
	Documentation := [Undocumented, Documented(Str)]

	## A direction value when the model defines one.
	Direction := [DirectionUnspecified, Directed(Str)]

	## A textual multiplicity bound when one is specified.
	Bound := [BoundUnspecified, SpecifiedBound(Str)]

	## Whether ordering is specified and, when specified, whether it is ordered.
	Ordering := [OrderingUnspecified, Ordered, Unordered]

	## Whether uniqueness is specified and, when specified, whether it is unique.
	Uniqueness := [UniquenessUnspecified, Unique, NonUnique]

	## Whether composition is specified for an element.
	Composition := [CompositionUnspecified, Composite, NotComposite]

	## Whether reference semantics are specified for an element.
	ReferenceKind := [ReferenceUnspecified, Reference, NotReference]

	## Whether an element has multiplicity information.
	MultiplicityState := [NoMultiplicity, HasMultiplicity(Multiplicity)]

	## Whether Spec42 produced an evaluated value for an element.
	Evaluation := [NotEvaluated, Evaluated(Str)]

	## The result of resolving a feature's type.
	TypeBinding := [Untyped, TypedBy(ElementSummary)]

	## A filter selecting every element or elements of one metaclass.
	ElementFilter := [AllElements, ByMetaclass(Metaclass)]

	## The normative kind name of a semantic relationship.
	RelationshipKind := [RelationshipKind(Str)]

	## Version and digest information for the immutable model snapshot.
	ModelInfo : {
		model_digest : Str,
		spec42_version : Str,
		semantic_api_version : Str,
	}

	## Stable identifying information for an element.
	ElementSummary : {
		handle : ElementHandle,
		semantic_id : SemanticId,
		metaclass : Metaclass,
		name : Name,
		qualified_name : Str,
		origin : Origin,
	}

	## A zero-based source span with an exclusive end position.
	SourceRange : {
		start_line : U32,
		start_character : U32,
		end_line : U32,
		end_character : U32,
	}

	## Multiplicity semantics resolved for an element.
	Multiplicity : {
		lower : Bound,
		upper : Bound,
		ordering : Ordering,
		uniqueness : Uniqueness,
		implied : Bool,
	}

	## Detailed declared properties and selected resolved semantics for an element.
	ElementDetail : {
		summary : ElementSummary,
		owner : Owner,
		declared_name : Name,
		effective_name : Name,
		source_uri : Str,
		source_range : SourceRange,
		definition : Bool,
		documentation : Documentation,
		short_name : Name,
		direction : Direction,
		derived : Bool,
		constant : Bool,
		abstract_flag : Bool,
		variation : Bool,
		individual : Bool,
		conjugated : Bool,
		composition : Composition,
		reference_kind : ReferenceKind,
		end : Bool,
		ordering : Ordering,
		uniqueness : Uniqueness,
		multiplicity : MultiplicityState,
		evaluation : Evaluation,
	}

	## A directed semantic relationship between two elements.
	Relationship : {
		kind : RelationshipKind,
		source : ElementSummary,
		target : ElementSummary,
		implied : Bool,
	}

	## Return version and digest information for the current model snapshot.
	info! : () => ModelInfo
	info! = || HostModel.info!()

	## Return the model's root elements in deterministic order.
	roots! : () => Try(List(ElementSummary), Str)
	roots! = || map_summaries_result(HostModel.roots!())

	## Find elements matching a domain filter in deterministic order.
	find! : ElementFilter => Try(List(ElementSummary), Str)
	find! = |filter| {
		host_filter = match filter {
			AllElements => None
			ByMetaclass(Metaclass(value)) => Some(value)
		}
		map_summaries_result(HostModel.find!(host_filter))
	}

	## Return the direct children of an element in deterministic order.
	children! : ElementHandle => Try(List(ElementSummary), Str)
	children! = |ElementHandle(owner)| map_summaries_result(HostModel.children!(owner))

	## Load detailed information for an element handle.
	element! : ElementHandle => Try(ElementDetail, Str)
	element! = |ElementHandle(handle)|
		match HostModel.element!(handle) {
			Ok(value) => Ok(to_detail(value))
			Err(message) => Err(message)
		}

	## Resolve the type associated with a feature.
	typed_by! : ElementHandle => Try(TypeBinding, Str)
	typed_by! = |ElementHandle(feature)|
		match HostModel.typed_by!(feature) {
			Ok(None) => Ok(Untyped)
			Ok(Some(value)) => Ok(TypedBy(to_summary(value)))
			Err(message) => Err(message)
		}

	## Return semantic relationships involving an element.
	relationships! : ElementHandle => Try(List(Relationship), Str)
	relationships! = |ElementHandle(element)|
		match HostModel.relationships!(element) {
			Ok(values) => Ok(values.map(to_relationship))
			Err(message) => Err(message)
		}

	## Return direct and inherited effective features in semantic precedence order.
	effective_features! : ElementHandle => Try(List(ElementSummary), Str)
	effective_features! = |ElementHandle(element)| map_summaries_result(HostModel.effective_features!(element))
}
