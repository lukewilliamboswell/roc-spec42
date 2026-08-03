# roc-spec42

A Roc platform for building sandboxed core WebAssembly generator plugins for Spec42.

Plugin authors get typed access to Spec42's semantic model, artifact emission, and diagnostics.
The generated `.wasm` is a normal core module with three imports and no required custom metadata.

## Build a plugin

A release bundle includes the prebuilt platform host, so plugin authors only need Roc:

```sh
roc build generate_diagram.roc --output=plugin.wasm
spec42 generate plugin.wasm model.sysml --output generated -- target=my-generator
```

See [`examples/generate_summary.roc`](examples/generate_summary.roc) for a complete generator.
During platform development, its header points at the local [`platform/main.roc`](platform/main.roc).
A released example should replace that path with the release bundle URL.

## Roc API

- `Model.info!`, `roots!`, `find!`, `children!`, `element!`, `typed_by!`,
  `relationships!`, and `effective_features!` expose the read-only semantic model.
- The public model uses domain tags such as `Named`/`Unnamed`, `RootElement`/`OwnedBy`,
  `TypedBy`/`Untyped`, and `Ordered`/`Unordered`/`OrderingUnspecified`. Handles, semantic IDs,
  metaclasses, and relationship kinds are distinct tagged values rather than interchangeable
  strings.
- `Artifacts.emit!` stages a relative path and raw bytes.
- `Diagnostics.log!` and `report!` publish bounded diagnostics; `report!` takes the tagged context
  `General` or `ForElement(handle)`.
- An application provides `main! : List(Str) => Try({}, Str)`. Spec42 passes arguments following
  its CLI `--` marker.

For example, `Model.find!(ByMetaclass(Metaclass("PartDefinition")))` returns typed element
summaries, and `Model.element!(summary.handle)` returns detail whose optional semantics are named
domain states rather than `None`/`Some` values.

## Platform development

The Rust guest adapter currently uses the SDK from the sibling Spec42 checkout at `../spec42`.
This keeps both sides of the experimental ABI in lockstep until the Spec42 changes have a commit
that can be pinned as a Git dependency.

Requirements: Rust stable with `wasm32-unknown-unknown`, Zig 0.16, and Roc on `PATH`.
The expected Roc nightly is pinned in [`.roc-version`](.roc-version); CI reads the same tag.

```sh
rustup target add wasm32-unknown-unknown
scripts/build-host.sh
roc check examples/generate_summary.roc
roc build examples/generate_summary.roc --output=plugin.wasm
scripts/test.sh
```

`scripts/test.sh` builds the release archive, serves it from an ephemeral loopback HTTP server,
rewrites every example header to that URL in a temporary directory, and runs the resulting plugin
through Spec42. It also generates the public API documentation and rejects leaked internal model
conversion helpers.

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
messages. Artifact contents cross the boundary as raw bytes. Spec42 loads the final module directly
with Wasmtime and provides no filesystem, network, environment, clock, random, or subprocess
imports.

Licensed under the [MIT License](LICENSE).
