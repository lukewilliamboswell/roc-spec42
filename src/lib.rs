//! Adapter between Roc's platform ABI and Spec42's generator ABI.

#![allow(improper_ctypes_definitions)]

#[cfg(not(target_arch = "wasm32"))]
compile_error!("roc-spec42-host must be built for wasm32-unknown-unknown");

use core::ffi::c_void;
use spec42_generator_sdk::{diagnostics, export, model, Artifact, Guest};

mod roc_platform_abi;

use roc_platform_abi::*;

static mut ROC_HOST: *mut RocHost = core::ptr::null_mut();

fn roc_host_ptr() -> *mut RocHost {
    unsafe {
        assert!(!ROC_HOST.is_null(), "Roc host used outside generate");
        ROC_HOST
    }
}

fn roc_host() -> &'static RocHost {
    unsafe { &*roc_host_ptr() }
}

unsafe fn payload_bytes<const N: usize, T>(value: T) -> [u8; N] {
    assert!(core::mem::size_of::<T>() <= N);
    let mut bytes = [0; N];
    unsafe { (bytes.as_mut_ptr() as *mut T).write(value) };
    bytes
}

fn roc_str(value: &str) -> RocStr {
    RocStr::from_str(value, roc_host())
}

unsafe fn roc_list<T>(values: Vec<T>) -> RocList<T> {
    let list: RocList<T> = unsafe { RocList::allocate(values.len(), roc_host()) };
    for (index, value) in values.into_iter().enumerate() {
        unsafe { list.elements.add(index).write(value) };
    }
    list
}

fn option_string_11(value: Option<String>) -> NoneOrSomeType11 {
    match value {
        None => NoneOrSomeType11 {
            _payload_alignment: [],
            payload: [0; 12],
            tag: NoneOrSomeType11Tag::None,
        },
        Some(value) => NoneOrSomeType11 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(roc_str(&value)) },
            tag: NoneOrSomeType11Tag::Some,
        },
    }
}

fn option_string_18(value: Option<String>) -> NoneOrSomeType18 {
    match value {
        None => NoneOrSomeType18 {
            _payload_alignment: [],
            payload: [0; 12],
            tag: NoneOrSomeType18Tag::None,
        },
        Some(value) => NoneOrSomeType18 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(roc_str(&value)) },
            tag: NoneOrSomeType18Tag::Some,
        },
    }
}

fn option_bool(value: Option<bool>) -> NoneOrSomeType17 {
    match value {
        None => NoneOrSomeType17 {
            _payload_alignment: [],
            payload: [0; 1],
            tag: NoneOrSomeType17Tag::None,
        },
        Some(value) => NoneOrSomeType17 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(value) },
            tag: NoneOrSomeType17Tag::Some,
        },
    }
}

fn summary(value: model::ElementSummary) -> HostModelChildrenOk {
    HostModelChildrenOk {
        handle: roc_str(&value.handle),
        metaclass: roc_str(value.metaclass.as_str()),
        name: option_string_11(value.name),
        qualified_name: roc_str(&value.qualified_name),
        semantic_id: roc_str(&value.semantic_id),
        library_element: value.library_element,
    }
}

fn option_summary_21(value: Option<model::ElementSummary>) -> NoneOrSomeType21 {
    match value {
        None => NoneOrSomeType21 {
            _payload_alignment: [],
            payload: [0; 68],
            tag: NoneOrSomeType21Tag::None,
        },
        Some(value) => NoneOrSomeType21 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(summary(value)) },
            tag: NoneOrSomeType21Tag::Some,
        },
    }
}

fn option_summary_27(value: Option<model::ElementSummary>) -> NoneOrSomeType27 {
    match value {
        None => NoneOrSomeType27 {
            _payload_alignment: [],
            payload: [0; 68],
            tag: NoneOrSomeType27Tag::None,
        },
        Some(value) => NoneOrSomeType27 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(summary(value)) },
            tag: NoneOrSomeType27Tag::Some,
        },
    }
}

fn option_multiplicity(value: Option<model::Multiplicity>) -> NoneOrSomeType19 {
    match value {
        None => NoneOrSomeType19 {
            _payload_alignment: [],
            payload: [0; 36],
            tag: NoneOrSomeType19Tag::None,
        },
        Some(value) => {
            let multiplicity = NoneOrSomeSome {
                lower: option_string_18(value.lower),
                upper: option_string_18(value.upper),
                implied: value.implied,
                ordered: value.ordered,
                unique: option_bool(value.unique),
            };
            NoneOrSomeType19 {
                _payload_alignment: [],
                payload: unsafe { payload_bytes(multiplicity) },
                tag: NoneOrSomeType19Tag::Some,
            }
        }
    }
}

fn detail(value: model::ElementDetail) -> HostModelElementOk {
    HostModelElementOk {
        declared_name: option_string_18(value.declared_name),
        direction: option_string_18(value.direction),
        documentation: option_string_18(value.documentation),
        effective_name: option_string_18(value.effective_name),
        evaluated_value: option_string_18(value.evaluated_value),
        multiplicity: option_multiplicity(value.multiplicity),
        owner: option_summary_21(value.owner),
        short_name: option_string_18(value.short_name),
        source_uri: roc_str(&value.source_uri),
        summary: summary(value.summary),
        source_range: HostModelElementOkSourceRange {
            end_character: value.source_range.end_character,
            end_line: value.source_range.end_line,
            start_character: value.source_range.start_character,
            start_line: value.source_range.start_line,
        },
        abstract_flag: value.abstract_flag,
        composite: option_bool(value.composite),
        conjugated: value.conjugated,
        constant: value.constant,
        definition: value.definition,
        derived: value.derived,
        end: value.end,
        individual: value.individual,
        ordered: option_bool(value.ordered),
        reference: option_bool(value.reference),
        unique: option_bool(value.unique),
        variation: value.variation,
    }
}

fn relationship(value: model::Relationship) -> HostModelRelationshipsOk {
    HostModelRelationshipsOk {
        kind: roc_str(value.kind.as_str()),
        source: summary(value.source),
        target: summary(value.target),
        implied: value.implied,
    }
}

fn source_reference(value: model::SourceReference) -> HostStateTransitionViewOkMachineSource {
    HostStateTransitionViewOkMachineSource {
        uri: roc_str(&value.uri),
        range: HostStateTransitionViewOkMachineSourceRange {
            end_character: value.range.end_character,
            end_line: value.range.end_line,
            start_character: value.range.start_character,
            start_line: value.range.start_line,
        },
    }
}

fn state_identity(value: model::StateMachineIdentity) -> HostStateTransitionViewsOkExposedMachine {
    HostStateTransitionViewsOkExposedMachine {
        label: roc_str(&value.label),
        semantic_id: roc_str(&value.semantic_id),
    }
}

fn element_identity(value: model::ElementIdentity) -> HostStateTransitionViewsOkExposedMachine {
    HostStateTransitionViewsOkExposedMachine {
        label: roc_str(&value.label),
        semantic_id: roc_str(&value.semantic_id),
    }
}

fn unsupported_reason(
    value: model::UnsupportedReason,
) -> HostStateTransitionViewOkCompletenessReasons {
    HostStateTransitionViewOkCompletenessReasons {
        code: roc_str(&value.code),
        message: roc_str(&value.message),
    }
}

fn state_transition_summary(
    value: model::DiagramViewSummary,
    machine: &model::StateMachineSummary,
) -> HostStateTransitionViewsOk {
    let semantic_id = match &value.reference {
        model::DiagramSemanticReference::Qualified { qualified_name, .. } => qualified_name,
        model::DiagramSemanticReference::ToolingElementId { element_id, .. } => element_id,
        model::DiagramSemanticReference::SourceAnchor { .. }
        | model::DiagramSemanticReference::Relationship { .. } => &value.handle,
    };
    HostStateTransitionViewsOk {
        exposed_machine: state_identity(model::StateMachineIdentity {
            semantic_id: machine.semantic_id.clone(),
            label: machine.label.clone(),
        }),
        handle: roc_str(&value.handle),
        name: roc_str(&value.name),
        semantic_id: roc_str(semantic_id),
        source: source_reference(value.source),
    }
}

fn machine_summary(value: model::StateMachineSummary) -> HostStateTransitionViewOkMachine {
    HostStateTransitionViewOkMachine {
        label: roc_str(&value.label),
        semantic_id: roc_str(&value.semantic_id),
        source: source_reference(value.source),
    }
}

fn state_node(value: model::StateTransitionNode) -> HostStateTransitionViewOkNodes {
    let kind = match value.kind {
        model::StateTransitionNodeKind::Initial => 0,
        model::StateTransitionNodeKind::State => 1,
        model::StateTransitionNodeKind::Final => 2,
    };
    HostStateTransitionViewOkNodes {
        label: roc_str(&value.label),
        semantic_id: roc_str(&value.semantic_id),
        source: source_reference(value.source),
        kind,
    }
}

fn completeness(value: model::ProjectionCompleteness) -> HostStateTransitionViewOkCompleteness {
    let (complete, reasons) = match value {
        model::ProjectionCompleteness::Complete => (true, Vec::new()),
        model::ProjectionCompleteness::Incomplete { reasons } => (false, reasons),
    };
    HostStateTransitionViewOkCompleteness {
        reasons: unsafe { roc_list(reasons.into_iter().map(unsupported_reason).collect()) },
        complete,
    }
}

fn optional_source(value: Option<model::SourceReference>) -> NoneOrSomeType64 {
    match value {
        None => NoneOrSomeType64 {
            _payload_alignment: [],
            payload: [0; 28],
            tag: NoneOrSomeType64Tag::None,
        },
        Some(value) => NoneOrSomeType64 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(source_reference(value)) },
            tag: NoneOrSomeType64Tag::Some,
        },
    }
}

fn optional_reason(value: Option<model::UnsupportedReason>) -> NoneOrSomeType65 {
    match value {
        None => NoneOrSomeType65 {
            _payload_alignment: [],
            payload: [0; 24],
            tag: NoneOrSomeType65Tag::None,
        },
        Some(value) => NoneOrSomeType65 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(unsupported_reason(value)) },
            tag: NoneOrSomeType65Tag::Some,
        },
    }
}

fn projection_feature(
    value: model::ProjectionFeature,
) -> HostStateTransitionViewOkTransitionsEffect {
    use model::ProjectionFeature::*;
    let (kind, label, source, unsupported) = match value {
        Absent => (0, None, None, None),
        Supported { label, source } => (1, Some(label), Some(source), None),
        Unsupported { reason } => (2, None, None, Some(reason)),
        Unresolved => (3, None, None, None),
        Ambiguous => (4, None, None, None),
        Recovery => (5, None, None, None),
    };
    HostStateTransitionViewOkTransitionsEffect {
        label: transition_label(label),
        source: optional_source(source),
        unsupported: optional_reason(unsupported),
        kind,
    }
}

fn transition_label(value: Option<String>) -> NoneOrSomeType63 {
    match value {
        None => NoneOrSomeType63 {
            _payload_alignment: [],
            payload: [0; 12],
            tag: NoneOrSomeType63Tag::None,
        },
        Some(value) => NoneOrSomeType63 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(roc_str(&value)) },
            tag: NoneOrSomeType63Tag::Some,
        },
    }
}

fn optional_identity(value: Option<model::ElementIdentity>) -> NoneOrSomeType67 {
    match value {
        None => NoneOrSomeType67 {
            _payload_alignment: [],
            payload: [0; 24],
            tag: NoneOrSomeType67Tag::None,
        },
        Some(value) => NoneOrSomeType67 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(element_identity(value)) },
            tag: NoneOrSomeType67Tag::Some,
        },
    }
}

fn transition_trigger(
    value: model::TransitionTrigger,
) -> HostStateTransitionViewOkTransitionsTrigger {
    let (kind, label, target, source, unsupported) = match value {
        model::TransitionTrigger::None => (0, None, None, None, None),
        model::TransitionTrigger::Accept {
            label,
            target,
            source,
        } => (1, Some(label), target, Some(source), None),
        model::TransitionTrigger::Unsupported { reason } => (2, None, None, None, Some(reason)),
        model::TransitionTrigger::Unresolved => (
            2,
            None,
            None,
            None,
            Some(model::UnsupportedReason {
                code: "unresolved-trigger".to_owned(),
                message: "transition trigger could not be resolved".to_owned(),
            }),
        ),
        model::TransitionTrigger::Ambiguous => (
            2,
            None,
            None,
            None,
            Some(model::UnsupportedReason {
                code: "ambiguous-trigger".to_owned(),
                message: "transition trigger resolved to multiple targets".to_owned(),
            }),
        ),
    };
    HostStateTransitionViewOkTransitionsTrigger {
        label: transition_label(label),
        source: optional_source(source),
        target: optional_identity(target),
        unsupported: optional_reason(unsupported),
        kind,
    }
}

fn state_transition(value: model::StateTransitionEdge) -> HostStateTransitionViewOkTransitions {
    HostStateTransitionViewOkTransitions {
        effect: projection_feature(value.effect),
        guard: projection_feature(value.guard),
        label: transition_label(value.label),
        semantic_id: roc_str(&value.semantic_id),
        source: roc_str(&value.source),
        source_reference: source_reference(value.source_reference),
        target: roc_str(&value.target),
        trigger: transition_trigger(value.trigger),
        implied: matches!(value.provenance, model::RelationshipProvenance::Implied),
    }
}

fn state_transition_view(
    value: model::DiagramViewProjection,
) -> Result<HostStateTransitionViewOk, String> {
    let scene = match value.scene {
        model::DiagramScene::StateTransition(scene) => scene,
        _ => return Err("selected diagram is not a state-transition view".to_owned()),
    };
    let machine = scene
        .machine
        .ok_or_else(|| "state-transition view exposes no resolved state machine".to_owned())?;
    Ok(HostStateTransitionViewOk {
        completeness: completeness(value.completeness),
        machine: machine_summary(machine.clone()),
        model_digest: roc_str(&value.model_digest),
        nodes: unsafe { roc_list(scene.vertices.into_iter().map(state_node).collect()) },
        transitions: unsafe {
            roc_list(
                scene
                    .transitions
                    .into_iter()
                    .map(state_transition)
                    .collect(),
            )
        },
        view: state_transition_summary(value.view, &machine),
        schema_version: value.schema_version,
    })
}

fn error_string<const N: usize>(message: String) -> [u8; N] {
    unsafe { payload_bytes(roc_str(&message)) }
}

fn summaries_result(result: Result<Vec<model::ElementSummary>, String>) -> HostModelChildrenResult {
    match result {
        Ok(values) => HostModelChildrenResult {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(roc_list(values.into_iter().map(summary).collect())) },
            tag: HostModelChildrenResultTag::Ok,
        },
        Err(message) => HostModelChildrenResult {
            _payload_alignment: [],
            payload: error_string(message),
            tag: HostModelChildrenResultTag::Err,
        },
    }
}

fn take_string(value: RocStr) -> String {
    let result = value.as_str().to_owned();
    unsafe { value.decref(roc_host()) };
    result
}

fn take_optional_string_3(value: NoneOrSomeType3) -> Option<String> {
    let result = match value.tag {
        NoneOrSomeType3Tag::None => None,
        NoneOrSomeType3Tag::Some => Some(
            unsafe { value.borrow_payload_some_unchecked() }
                .as_str()
                .to_owned(),
        ),
    };
    unsafe { value.decref(roc_host()) };
    result
}

fn take_optional_string_12(value: NoneOrSomeType12) -> Option<String> {
    let result = match value.tag {
        NoneOrSomeType12Tag::None => None,
        NoneOrSomeType12Tag::Some => Some(
            unsafe { value.borrow_payload_some_unchecked() }
                .as_str()
                .to_owned(),
        ),
    };
    unsafe { value.decref(roc_host()) };
    result
}

fn level(value: DebugOrErrorOrInfoOrWarning) -> diagnostics::Level {
    match value {
        DebugOrErrorOrInfoOrWarning::Debug => diagnostics::Level::Debug,
        DebugOrErrorOrInfoOrWarning::Error => diagnostics::Level::Error,
        DebugOrErrorOrInfoOrWarning::Info => diagnostics::Level::Info,
        DebugOrErrorOrInfoOrWarning::Warning => diagnostics::Level::Warning,
    }
}

#[no_mangle]
pub extern "C" fn roc_diagnostics_log(
    diagnostic_level: DebugOrErrorOrInfoOrWarning,
    message: RocStr,
) {
    diagnostics::log(level(diagnostic_level), message.as_str());
    unsafe { message.decref(roc_host()) };
}

#[no_mangle]
pub extern "C" fn roc_diagnostics_report(
    diagnostic_level: DebugOrErrorOrInfoOrWarning,
    message: RocStr,
    element: NoneOrSomeType3,
) {
    let message_value = message.as_str().to_owned();
    let element_value = take_optional_string_3(element);
    diagnostics::report(
        level(diagnostic_level),
        &message_value,
        element_value.as_deref(),
    );
    unsafe { message.decref(roc_host()) };
}

#[no_mangle]
pub extern "C" fn roc_model_info() -> HostModelInfo {
    // The Roc-facing signature is still infallible, so an error here has nowhere to go.
    // The host cannot actually fail this query; if that ever changes, `info!` should become
    // a `Try` like every other Model function rather than being papered over here.
    let value = model::info().unwrap_or_else(|error| {
        panic!("Spec42 rejected the model info query: {error}");
    });
    HostModelInfo {
        model_digest: roc_str(&value.model_digest),
        semantic_api_version: roc_str(&value.semantic_api_version),
        spec42_version: roc_str(&value.spec42_version),
    }
}

#[no_mangle]
pub extern "C" fn roc_model_roots() -> HostModelRootsResult {
    summaries_result(model::roots())
}

#[no_mangle]
pub extern "C" fn roc_model_find(metaclass: NoneOrSomeType12) -> HostModelFindResult {
    summaries_result(model::find(take_optional_string_12(metaclass).as_deref()))
}

#[no_mangle]
pub extern "C" fn roc_model_children(owner: RocStr) -> HostModelChildrenResult {
    let owner = take_string(owner);
    summaries_result(model::children(&owner))
}

#[no_mangle]
pub extern "C" fn roc_model_effective_features(
    element: RocStr,
) -> HostModelEffectiveFeaturesResult {
    let element = take_string(element);
    summaries_result(model::effective_features(&element))
}

#[no_mangle]
pub extern "C" fn roc_model_element(handle: RocStr) -> HostModelElementResult {
    let handle = take_string(handle);
    match model::element(&handle) {
        Ok(value) => HostModelElementResult {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(detail(value)) },
            tag: HostModelElementResultTag::Ok,
        },
        Err(message) => HostModelElementResult {
            _payload_alignment: [],
            payload: error_string(message),
            tag: HostModelElementResultTag::Err,
        },
    }
}

#[no_mangle]
pub extern "C" fn roc_model_typed_by(feature: RocStr) -> HostModelTypedByResult {
    let feature = take_string(feature);
    match model::typed_by(&feature) {
        Ok(value) => HostModelTypedByResult {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(option_summary_27(value)) },
            tag: HostModelTypedByResultTag::Ok,
        },
        Err(message) => HostModelTypedByResult {
            _payload_alignment: [],
            payload: error_string(message),
            tag: HostModelTypedByResultTag::Err,
        },
    }
}

#[no_mangle]
pub extern "C" fn roc_model_relationships(element: RocStr) -> HostModelRelationshipsResult {
    let element = take_string(element);
    match model::relationships(&element) {
        Ok(values) => HostModelRelationshipsResult {
            _payload_alignment: [],
            payload: unsafe {
                payload_bytes(roc_list(values.into_iter().map(relationship).collect()))
            },
            tag: HostModelRelationshipsResultTag::Ok,
        },
        Err(message) => HostModelRelationshipsResult {
            _payload_alignment: [],
            payload: error_string(message),
            tag: HostModelRelationshipsResultTag::Err,
        },
    }
}

#[no_mangle]
pub extern "C" fn roc_state_transition_views() -> HostStateTransitionViewsResult {
    let result = model::diagram_views().and_then(|values| {
        values
            .into_iter()
            .filter(|value| value.kind == model::DiagramViewKind::StateTransitionView)
            .map(|value| {
                let projection = model::diagram_view(&value.handle)?;
                let machine = match &projection.scene {
                    model::DiagramScene::StateTransition(scene) => scene.machine.as_ref(),
                    _ => None,
                }
                .ok_or_else(|| {
                    "state-transition view exposes no resolved state machine".to_owned()
                })?;
                Ok(state_transition_summary(value, machine))
            })
            .collect::<Result<Vec<_>, String>>()
    });
    match result {
        Ok(values) => HostStateTransitionViewsResult {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(roc_list(values)) },
            tag: HostStateTransitionViewsResultTag::Ok,
        },
        Err(message) => HostStateTransitionViewsResult {
            _payload_alignment: [],
            payload: error_string(message),
            tag: HostStateTransitionViewsResultTag::Err,
        },
    }
}

#[no_mangle]
pub extern "C" fn roc_state_transition_view(handle: RocStr) -> HostStateTransitionViewResult {
    let handle = take_string(handle);
    match model::diagram_view(&handle).and_then(state_transition_view) {
        Ok(value) => HostStateTransitionViewResult {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(value) },
            tag: HostStateTransitionViewResultTag::Ok,
        },
        Err(message) => HostStateTransitionViewResult {
            _payload_alignment: [],
            payload: error_string(message),
            tag: HostStateTransitionViewResultTag::Err,
        },
    }
}

#[no_mangle]
pub extern "C" fn roc_alloc(length: usize, alignment: usize) -> *mut c_void {
    DefaultAllocators::roc_alloc(roc_host_ptr(), length, alignment)
}

#[no_mangle]
pub extern "C" fn roc_dealloc(ptr: *mut c_void, alignment: usize) {
    DefaultAllocators::roc_dealloc(roc_host_ptr(), ptr, alignment)
}

#[no_mangle]
pub extern "C" fn roc_realloc(
    ptr: *mut c_void,
    new_length: usize,
    alignment: usize,
) -> *mut c_void {
    DefaultAllocators::roc_realloc(roc_host_ptr(), ptr, new_length, alignment)
}

#[no_mangle]
pub extern "C" fn roc_dbg(bytes: *const u8, len: usize) {
    DefaultHandlers::roc_dbg(roc_host_ptr(), bytes, len)
}

#[no_mangle]
pub extern "C" fn roc_expect_failed(bytes: *const u8, len: usize) {
    DefaultHandlers::roc_expect_failed(roc_host_ptr(), bytes, len)
}

#[no_mangle]
pub extern "C" fn roc_crashed(bytes: *const u8, len: usize) {
    DefaultHandlers::roc_crashed(roc_host_ptr(), bytes, len)
}

struct RocGenerator;

impl Guest for RocGenerator {
    fn generate(args: Vec<String>) -> Result<Vec<Artifact>, String> {
        let mut host = make_roc_host(core::ptr::null_mut());
        unsafe { ROC_HOST = &mut host };

        let roc_args =
            unsafe { roc_list(args.iter().map(|arg| roc_str(arg)).collect::<Vec<RocStr>>()) };
        let result = unsafe { roc_generate(roc_args) };
        let output = match result.tag {
            GenerateForHostResultTag::Ok => Ok(unsafe { result.borrow_payload_ok_unchecked() }
                .as_slice()
                .iter()
                .map(|artifact| Artifact {
                    file_path: artifact.file_path.as_str().to_owned(),
                    contents: artifact.contents.as_slice().to_vec(),
                })
                .collect()),
            GenerateForHostResultTag::Err => Err(unsafe { result.borrow_payload_err_unchecked() }
                .as_str()
                .to_owned()),
        };
        unsafe {
            result.decref(&host);
            ROC_HOST = core::ptr::null_mut();
        }
        output
    }
}

export!(RocGenerator);
