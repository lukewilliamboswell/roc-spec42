//! Adapter between Roc's platform ABI and Spec42's generator ABI.

#![allow(improper_ctypes_definitions)]

#[cfg(not(target_arch = "wasm32"))]
compile_error!("roc-spec42-host must be built for wasm32-unknown-unknown");

use core::ffi::c_void;
use spec42_generator_sdk::{artifacts, diagnostics, export, model, Guest};

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

fn option_string_17(value: Option<String>) -> NoneOrSomeType17 {
    match value {
        None => NoneOrSomeType17 {
            _payload_alignment: [],
            payload: [0; 12],
            tag: NoneOrSomeType17Tag::None,
        },
        Some(value) => NoneOrSomeType17 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(roc_str(&value)) },
            tag: NoneOrSomeType17Tag::Some,
        },
    }
}

fn option_string_24(value: Option<String>) -> NoneOrSomeType24 {
    match value {
        None => NoneOrSomeType24 {
            _payload_alignment: [],
            payload: [0; 12],
            tag: NoneOrSomeType24Tag::None,
        },
        Some(value) => NoneOrSomeType24 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(roc_str(&value)) },
            tag: NoneOrSomeType24Tag::Some,
        },
    }
}

fn option_bool(value: Option<bool>) -> NoneOrSomeType23 {
    match value {
        None => NoneOrSomeType23 {
            _payload_alignment: [],
            payload: [0; 1],
            tag: NoneOrSomeType23Tag::None,
        },
        Some(value) => NoneOrSomeType23 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(value) },
            tag: NoneOrSomeType23Tag::Some,
        },
    }
}

fn summary(value: model::ElementSummary) -> HostModelChildrenOk {
    HostModelChildrenOk {
        handle: roc_str(&value.handle),
        metaclass: roc_str(&value.metaclass),
        name: option_string_17(value.name),
        qualified_name: roc_str(&value.qualified_name),
        semantic_id: roc_str(&value.semantic_id),
        library_element: value.library_element,
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

fn option_summary_33(value: Option<model::ElementSummary>) -> NoneOrSomeType33 {
    match value {
        None => NoneOrSomeType33 {
            _payload_alignment: [],
            payload: [0; 68],
            tag: NoneOrSomeType33Tag::None,
        },
        Some(value) => NoneOrSomeType33 {
            _payload_alignment: [],
            payload: unsafe { payload_bytes(summary(value)) },
            tag: NoneOrSomeType33Tag::Some,
        },
    }
}

fn option_multiplicity(value: Option<model::Multiplicity>) -> NoneOrSomeType25 {
    match value {
        None => NoneOrSomeType25 {
            _payload_alignment: [],
            payload: [0; 36],
            tag: NoneOrSomeType25Tag::None,
        },
        Some(value) => {
            let multiplicity = NoneOrSomeSome {
                lower: option_string_24(value.lower),
                upper: option_string_24(value.upper),
                implied: value.implied,
                ordered: value.ordered,
                unique: option_bool(value.unique),
            };
            NoneOrSomeType25 {
                _payload_alignment: [],
                payload: unsafe { payload_bytes(multiplicity) },
                tag: NoneOrSomeType25Tag::Some,
            }
        }
    }
}

fn detail(value: model::ElementDetail) -> HostModelElementOk {
    HostModelElementOk {
        declared_name: option_string_24(value.declared_name),
        direction: option_string_24(value.direction),
        documentation: option_string_24(value.documentation),
        effective_name: option_string_24(value.effective_name),
        evaluated_value: option_string_24(value.evaluated_value),
        multiplicity: option_multiplicity(value.multiplicity),
        owner: option_summary_27(value.owner),
        short_name: option_string_24(value.short_name),
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
        kind: roc_str(&value.kind),
        source: summary(value.source),
        target: summary(value.target),
        implied: value.implied,
    }
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

fn take_optional_string_9(value: NoneOrSomeType9) -> Option<String> {
    let result = match value.tag {
        NoneOrSomeType9Tag::None => None,
        NoneOrSomeType9Tag::Some => Some(value.payload_some().as_str().to_owned()),
    };
    unsafe { value.decref(roc_host()) };
    result
}

fn take_optional_string_18(value: NoneOrSomeType18) -> Option<String> {
    let result = match value.tag {
        NoneOrSomeType18Tag::None => None,
        NoneOrSomeType18Tag::Some => Some(value.payload_some().as_str().to_owned()),
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
pub extern "C" fn roc_artifacts_emit(
    path: RocStr,
    content: RocListWith<u8, false>,
) -> ArtifactsEmitResult {
    let result = artifacts::emit(path.as_str(), content.as_slice());
    unsafe {
        path.decref(roc_host());
        content.decref(roc_host());
    }
    match result {
        Ok(()) => ArtifactsEmitResult {
            _payload_alignment: [],
            payload: [0; 12],
            tag: ArtifactsEmitResultTag::Ok,
        },
        Err(message) => ArtifactsEmitResult {
            _payload_alignment: [],
            payload: error_string(message),
            tag: ArtifactsEmitResultTag::Err,
        },
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
    element: NoneOrSomeType9,
) {
    let message_value = message.as_str().to_owned();
    let element_value = take_optional_string_9(element);
    diagnostics::report(
        level(diagnostic_level),
        &message_value,
        element_value.as_deref(),
    );
    unsafe { message.decref(roc_host()) };
}

#[no_mangle]
pub extern "C" fn roc_model_info() -> HostModelInfo {
    let value = model::info();
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
pub extern "C" fn roc_model_find(metaclass: NoneOrSomeType18) -> HostModelFindResult {
    summaries_result(model::find(take_optional_string_18(metaclass).as_deref()))
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
            payload: unsafe { payload_bytes(option_summary_33(value)) },
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
    fn generate(args: Vec<String>) -> Result<(), String> {
        let mut host = make_roc_host(core::ptr::null_mut());
        unsafe { ROC_HOST = &mut host };

        let roc_args =
            unsafe { roc_list(args.iter().map(|arg| roc_str(arg)).collect::<Vec<RocStr>>()) };
        let result = unsafe { roc_generate(roc_args) };
        let output = match result.tag {
            GenerateForHostResultTag::Ok => Ok(()),
            GenerateForHostResultTag::Err => Err(result.payload_err().as_str().to_owned()),
        };
        unsafe {
            result.decref(&host);
            ROC_HOST = core::ptr::null_mut();
        }
        output
    }
}

export!(RocGenerator);
