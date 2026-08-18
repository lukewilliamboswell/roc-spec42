# Door controller state-transition view

This exploratory vertical slice renders the model-authored `lifecycle` view as
a standalone SVG using the typed `StateTransition` projection. Spec42 owns the
selected semantic graph and resolved labels; the Roc plugin maps that typed
projection to supported SysML notation, uses
[`roc-graph-layout` 0.1.0](https://github.com/lukewilliamboswell/roc-graph-layout/releases/tag/0.1.0)
for geometry, and emits deterministic, source-addressable SVG.

The spike deliberately supports only initial, ordinary-state, and final nodes,
directed transitions, and accept-trigger labels. Guards, effects, nested or
parallel states, control nodes, and annotations fail explicitly rather than
falling back to misleading notation.

## What is built and where it lives

The Roc source in `state_transition_svg.roc` is compiled ahead of time to the
core WebAssembly module `state-transition-view.wasm`. The layout library is a
build-time Roc dependency pinned to its immutable, content-addressed 0.1.0
release archive. Its code is therefore compiled into the plugin; no layout
source checkout or runtime download is needed by Spec42 or VS Code.

The plugin is **not embedded in the Spec42 executable**. The macOS QA setup
script builds it directly into Spec42's VS Code extension at
`vscode/generators/state-transition-view.wasm`, after which VSIX packaging
includes that prebuilt file. A user installing that VSIX receives the
TypeScript extension and the prebuilt Wasm plugin. An explicit extension
setting can override the packaged plugin path during development.

The separate `spec42` executable contains the language server, immutable model
publication machinery, typed query implementation, generator ABI host, and
Wasm runtime. It does not contain this diagram renderer or
`roc-graph-layout`.

## Runtime flow

When `Spec42: Open State Transition View` is invoked, the extension reads its
packaged Wasm plugin and sends the bytes, current model URI, and arguments to
the already-running Spec42 LSP process using the bounded `spec42/generate`
request. The server executes the plugin against its current immutable
`PublishedModel`; it does not launch another Spec42 process or reparse the model
from disk. The server also reuses the Wasmtime engine and prepared module for
later requests. The extension validates the returned SVG and displays it in a
restricted webview.

```text
VSIX: command + prebuilt plugin.wasm
                 |
                 | spec42/generate
                 v
Spec42 LSP: PublishedModel -> typed query ABI -> Roc plugin -> SVG
```

This is the intended extension pattern for future optional capabilities:
develop a generator against the stable typed query ABI, build it as a bounded
Wasm plugin, and package it with a client such as the VS Code extension. That
adds rendering or export behavior without adding feature-specific code to the
SysML parser or core compiler. New semantic information still belongs in
generic typed queries and may require a versioned generator ABI addition;
plugins should not inspect compiler internals or reconstruct semantics from
text.

## Local QA

From the `roc-spec42` repository:

```sh
./scripts/setup-macos-vscode-qa.sh
```

The script builds the plugin, builds an optimized Spec42 server, packages a
VSIX containing the plugin, installs it into an isolated extension directory,
and opens the exemplar workspace. Run `Spec42: Open State Transition View` in
that window. Use `--no-open` to prepare the environment without launching VS
Code.

The workspace contains four independent models for visual comparison:

| File | View | Shape exercised |
|---|---|---|
| `model.sysml` | `lifecycle` | minimal linear door lifecycle |
| `traffic_light.sysml` | `trafficOperations` | cycle plus a retirement branch |
| `order_fulfillment.sysml` | `orderLifecycle` | longer linear process with triggers |
| `media_player.sysml` | `playbackLifecycle` | cycles and multiple return paths |

Open or focus one of these files, then run `Spec42: Open State Transition
View`. The extension passes the active document URI to the plugin; the plugin
selects the authored view whose source provenance matches that URI. All files
remain part of the same workspace and immutable LSP publication.
