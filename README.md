# roc-spec42

A Roc platform for building sandboxed core WebAssembly generator plugins for Spec42.

Plugin authors get typed access to Spec42's semantic model and diagnostics, and return generated
files as ordinary Roc values. The generated `.wasm` is a normal core module with two imports and
no required custom metadata.

## Build a plugin

A release bundle includes the prebuilt platform host, so plugin authors only need Roc:

```sh
roc build examples/electric_vehicle/vcrm_csv.roc --output=vcrm.wasm
spec42 --no-stdlib generate vcrm.wasm examples/electric_vehicle/model.sysml
```

The [example matrix](examples/README.md) contains three self-contained engineering models and
nine complete generators. Each model directory includes its own `model.sysml`; the scripts produce
CSV registers, Graphviz diagrams, simulation data, and standalone HTML tools. During platform
development, their headers point at the local [`platform/main.roc`](platform/main.roc). A released
example should replace that path with the release bundle URL.

## Roc API

- `Model.info!`, `roots!`, `find!`, `children!`, `element!`, `typed_by!`,
  `relationships!`, and `effective_features!` expose the read-only semantic model.
- The public model uses domain tags such as `Named`/`Unnamed`, `RootElement`/`OwnedBy`,
  `TypedBy`/`Untyped`, and `Ordered`/`Unordered`/`OrderingUnspecified`. Handles, semantic IDs,
  metaclasses, and relationship kinds are distinct tagged values rather than interchangeable
  strings.
- `Diagnostics.log!` and `report!` publish bounded diagnostics; `report!` takes the tagged context
  `General` or `ForElement(handle)`.
- An application provides
  `main! : List(Str) => Try(List({ file_path : Str, contents : List(U8) }), Str)`. Spec42 passes
  arguments following its CLI `--` marker, then validates every returned path and byte payload.

For example, `Model.find!(ByMetaclass(Metaclass("PartDefinition")))` returns typed element
summaries, and `Model.element!(summary.handle)` returns detail whose optional semantics are named
domain states rather than `None`/`Some` values.

## Platform development

The Rust guest adapter depends on `spec42-generator-sdk` as a git dependency pinned by revision in
[`Cargo.toml`](Cargo.toml), mirrored in [`.spec42-revision`](.spec42-revision) for CI. A sibling
checkout at `../spec42` is no longer required to build.

The pin matters: Spec42 verifies the wire schema at load time. Every guest exports
`spec42_abi_version` returning a structural fingerprint of the ABI types, and a host whose
fingerprint differs refuses the module with exit 11 rather than misreading its Postcard payloads.
Bumping the revision therefore means rebuilding the host adapter and re-running the examples.

Requirements: Bash, Python 3, `curl`, Rust stable with `wasm32-unknown-unknown`, Zig 0.16, and Roc on
`PATH`. The expected Roc nightly is pinned in [`.roc-version`](.roc-version); CI reads the same tag.

```sh
rustup target add wasm32-unknown-unknown
scripts/build-host.sh
roc check examples/electric_vehicle/vcrm_csv.roc
roc build examples/electric_vehicle/vcrm_csv.roc --output=plugin.wasm
scripts/test.sh
```

`scripts/test.sh` builds the release archive, serves it from an ephemeral loopback HTTP server,
rewrites every example header to that URL in a temporary directory, runs each example's top-level
`expect` tests, and executes all nine scripts against the model beside each script through Spec42.
Every generated artifact must match its committed golden file under the model's `output/` directory
byte-for-byte. The test also generates the public API documentation and rejects leaked internal
model conversion helpers.

Use `scripts/update-example-snapshots.sh` to regenerate golden outputs after an intentional change.
CI runs that command and fails if it leaves an uncommitted diff.

`scripts/build-host.sh` filters non-WebAssembly members from Rust's static library before creating
the relocatable `platform/targets/wasm32/host.wasm`. That generated file is intentionally ignored
by Git and included in release bundles.

When the platform API changes, regenerate [`src/roc_platform_abi.rs`](src/roc_platform_abi.rs):

```sh
ROC_RUST_GLUE=/path/to/roc/src/glue/src/RustGlue.roc scripts/regenerate-glue.sh
```

## Bundle

```sh
scripts/build-host.sh
scripts/bundle.sh
```

The bundle command refuses to run without the generated host so it cannot publish an unusable
platform package.

## Runtime boundary

The internal `HostModel` and `HostDiagnostics` modules mirror the low-level ABI records; their
public modules convert those records into tagged domain values. The linked Rust adapter translates
the boundary values to Spec42 generator SDK calls. The SDK uses Postcard for compact model-query
messages and the returned artifact list. Spec42 loads the final module directly with Wasmtime and
provides no filesystem, network, environment, clock, random, or subprocess imports.

Licensed under the [MIT License](LICENSE).
