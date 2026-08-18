# Normative state-transition SVG generator spike

Status: implemented exploratory spike; paired with
[`spec42/planning/GENERATOR_STATE_TRANSITION_VIEW_SPIKE.md`](../spec42/planning/GENERATOR_STATE_TRANSITION_VIEW_SPIKE.md).

## Purpose

Build one complete Roc generator that turns a small SysML v2 model-authored
`StateTransitionView` into a deterministic SVG using the normative graphical notation in SysML v2
Language clause 8.2.3.18. The spike validates the boundary from Spec42's immutable published model,
through a typed generator query and the Roc Wasm ABI, into notation selection, graph layout, and a
generated artifact, then displays that same artifact in the Spec42 VS Code extension.

This is a walking skeleton, not a claim of complete graphical-notation conformance. It should expose
missing semantic facts, ABI ergonomics, layout capabilities, and testing seams while establishing the
architecture used by later view families.

## Normative basis

The notation owner is the adopted OMG SysML v2 Language specification, especially:

- clause 8.2.3.18, States Graphical Notation;
- clause 8.2.3.26, Views and Viewpoints Graphical Notation; and
- the `StateTransitionView` definition in the normative Systems Library.

Implementation aids are the release's extracted graphical BNF and SVG productions. The adopted PDF
remains authoritative if they disagree. Node coordinates, spacing, font metrics, SVG structure, and
route shapes are implementation choices rather than standardized notation.

Local reference material:

- `../sysml-v2-parser/sysml-v2-release/doc/2a-OMG_Systems_Modeling_Language.pdf`
- `../sysml-v2-parser/sysml-v2-release/bnf/SysML-graphical-bnf.kgbnf`
- `../sysml-v2-parser/sysml-v2-release/sysml.library/Systems Library/StandardViewDefinitions.sysml`

## Spike outcome

Given the exemplar model and a view selector, the plugin generates one self-contained SVG containing:

- a view frame naming the selected view and exposed state machine;
- one filled initial pseudostate;
- two rounded state nodes;
- one final-state bullseye;
- directed transition edges;
- a trigger label on the triggered transition; and
- provenance attributes that associate rendered objects with semantic identities and source ranges.
- a VS Code command that selects the authored view, runs the plugin, and opens the SVG in a readonly
  webview editor; and
- click-to-source navigation for rendered elements carrying source provenance.

The artifact is deterministic for the same model digest, view projection version, plugin version, and
layout settings.

## Exemplar

Add a self-contained directory `examples/door_controller/` with `model.sysml`,
`state_transition_svg.roc`, and the committed output `output/door-controller.svg`.

The model should express this semantic shape using syntax accepted by the pinned parser:

```sysml
package DoorController {
    private import StandardViewDefinitions::*;

    item def OpenRequested;

    state def DoorLifecycle {
        then closed;
        state closed;
        state open;
        final retired;
        transition open_door first closed accept OpenRequested then open;
        transition retire first open then retired;
    }

    view lifecycle : StateTransitionView {
        expose DoorLifecycle;
    }
}
```

The checked-in source is authoritative; adjust spelling only if the standalone Spec42 snapshot path
shows the pinned parser requires it. The model deliberately omits nested/parallel states, state
entry/do/exit actions, guards, effects, forks, joins, decisions, merges, termination, and annotations.
Those are later conformance increments, not silent support claims.

Spike discovery: the normative type must be explicitly imported, and `then closed;` is the accepted
initial-state syntax. A redundant standalone `entry;` put the publication into parser recovery without
an accompanying diagnostic, so it was removed. That silent-recovery diagnostic is a parser follow-up.

## Architecture

```text
model.sysml
  -> Spec42 PublishedModel
  -> typed StateTransitionView projection
  -> generator protocol/Postcard
  -> roc-spec42 host adapter
  -> public Roc StateTransition module
  -> notation scene with measured boxes
  -> roc-graph-layout Layered geometry
  -> SVG serializer
  -> door-controller.svg
  -> VS Code readonly webview
```

### Ownership boundaries

Spec42 owns selection and semantic meaning. The plugin must not infer state-machine membership by
scanning metaclass names or rediscover transition endpoints through generic relationships. It consumes
the typed projection described in the paired Spec42 design.

The Roc notation layer owns the exhaustive mapping from typed projection variants to clause 8.2.3.18
glyphs and labels. It does not resolve names or endpoints.

`roc-graph-layout` owns only geometry. It receives sized boxes and index-based edges and returns
positions, routes, and bounds. It does not know SysML.

The SVG layer owns escaping, numeric formatting, drawing order, accessibility text, theme tokens, and
semantic `data-*` attributes. It does not make semantic or layout decisions.

The VS Code extension owns command UX, saved-document policy, process lifecycle, webview security,
artifact display, and source navigation. It treats the SVG as an artifact and does not interpret model
semantics beyond the versioned provenance attributes required for navigation.

## Proposed public Roc API

Add a module named `StateTransition` rather than extending generic `Model` inspection:

```roc
StateTransition := [].{
    ViewHandle := [ViewHandle(Str)]
    ElementId := [ElementId(Str)]

    ViewSummary : {
        handle : ViewHandle,
        name : Str,
        exposed_machine : ElementId,
    }

    NodeKind := [Initial, State, Final]

    Node : {
        id : ElementId,
        label : Str,
        kind : NodeKind,
        source : SourceReference,
    }

    Trigger := [NoTrigger, AcceptTrigger({ label : Str, source : SourceReference })]

    Transition : {
        id : ElementId,
        source : ElementId,
        target : ElementId,
        trigger : Trigger,
        source_reference : SourceReference,
    }

    View : {
        schema_version : U32,
        model_digest : Str,
        view : ViewSummary,
        nodes : List(Node),
        transitions : List(Transition),
        completeness : Completeness,
    }

    views! : {} => Try(List(ViewSummary), Str)
    view! : ViewHandle => Try(View, Str)
}
```

The actual records must mirror the final generator-protocol types; this sketch establishes domain
shape. `SourceReference`, completeness, unsupported states, and ordering must remain explicit rather
than encoded as empty strings or omitted values.

## Plugin behavior

`main!` accepts an optional opaque view handle, view name, semantic ID, or source URI after the
Spec42 `--` separator. With no selector:

- exactly one available view selects it;
- zero views returns a clear error; and
- multiple views returns an error listing canonical names, avoiding an arbitrary first-view policy.

The plugin calls `StateTransition.view!` once after selection, converts the typed projection to a
notation scene, lays it out, and returns one SVG artifact. The file name is a sanitized presentation
name plus `.svg`; collision handling is deterministic. No filesystem, network, clock, randomness, or
subprocess capability is required.

The VS Code client first requests the typed catalog from `spec42/stateTransitionViews` for the current
immutable publication. It filters by active-file provenance, opens a sole match directly, or presents
a Quick Pick for multiple matches. Generation receives the chosen opaque handle and the catalog's
model digest; Spec42 rejects execution if the publication changed during selection.

## Notation scene

Keep a small internal renderer-neutral type between the query and layout:

```text
NotationScene
  nodes: semantic id, glyph, label lines, measured size
  edges: semantic id, endpoint indices, marker, label
  frame: title and optional metadata
```

The spike supports these glyphs only:

| Projection kind | Notation |
|---|---|
| `Initial` | filled circle |
| `State` | rounded rectangle with state name compartment |
| `Final` | filled circle inside an outer circle |
| transition | solid directed edge |
| accept trigger | trigger text on the transition |

Unsupported projection variants must fail explicitly. They must never fall back to an ordinary state
box or unlabeled relationship.

## Layout integration and expected gaps

The exemplar pins the content-addressed `roc-graph-layout` 0.1.0 Roc package archive. It uses
`Layered` with a left-to-right direction, fixed node dimensions, and deterministic default run
settings. The layout implementation is compiled into the resulting plugin; the test and QA paths do
not vendor it or require a sibling checkout.

Spike discovery: the generator SDK dependency is temporarily a sibling path while the matching
Spec42 ABI work is uncommitted. That dependency must become an immutable revision before release
packaging; `roc-graph-layout` is already pinned to an immutable release archive.

Known or likely gaps to record during implementation:

- transition label placement may require a small plugin-side pass;
- self-loop quality is not exercised by the exemplar;
- parallel edges may require separation policy;
- glyph-sized initial/final nodes must route cleanly beside larger boxes;
- text measurement is outside `roc-graph-layout`;
- exact ELK coordinate parity is neither expected nor desirable;
- layout failures need conversion into bounded generator errors/diagnostics.

Spike discovery: representing the complete projection as deeply nested Roc tag unions at the hosted
function boundary triggered a Roc compiler specialization panic even in a minimized application that
only read `model_digest`. The public API remains exhaustive and typed, but the internal hosted ABI now
uses closed records with numeric discriminants for node kind, trigger, optional feature, completeness,
and provenance. `StateTransition.roc` performs the single exhaustive conversion into public tags. This
is not an opaque serialized graph and does not move semantic interpretation into the guest; it is a
compiler-compatible wire adapter that the Rust host controls and tests. Revisit the flattening when
the compiler can reliably specialize nested hosted tag payloads.

Do not extend `roc-graph-layout` with SysML concepts. A generally useful geometry deficiency may be
fixed upstream later, but the spike may use a deterministic local adapter and record the limitation.

## SVG contract

The SVG must be standalone, use a static light theme, and contain no script or remote resources. It
should include:

- `viewBox` derived from layout bounds plus fixed padding;
- `<title>` and `<desc>` for the view;
- reusable marker definitions;
- stable groups for frame, edges, labels, and nodes;
- `data-semantic-id`, `data-kind`, and source-location attributes where available;
- invariant numeric formatting; and
- XML escaping for all model-derived text.

The SVG DOM is an internal versioned artifact contract for this spike. Consumers must not infer SysML
semantics from CSS classes; semantic meaning remains in the typed projection and provenance metadata.

## VS Code viewer slice

Add a `Spec42: Open State Transition View` command to the existing VS Code extension. The command
uses the running language server's bounded generator request so the runtime, prepared module, and
immutable semantic publication can be reused:

```text
active SysML editor
  -> require saved workspace state
  -> discover/select authored StateTransitionView
  -> send bounded plugin bytes to the running Spec42 language server
  -> execute against the current immutable publication
  -> receive the generated SVG artifact bytes
  -> display it in a readonly WebviewPanel
```

The extension uses an explicitly packaged or configured plugin path. It reads that bounded module and
sends base64 bytes to the paired server; the server is not given arbitrary extension-controlled
filesystem paths. It must not download or compile the Roc plugin on command. Preview artifacts remain
in memory and are never written over the user's model workspace.

The command prompts to save dirty SysML documents before generation. Cancellation leaves the existing
preview unchanged. The server executes against the LSP's current `PublishedModel`, while the UI keeps
the first-slice save-all policy explicit. Intentional rendering from dirty buffers remains follow-up UX
and staleness policy, not a different semantic or transport path.

### Runtime preparation and caching

The QA setup builds the Spec42 host in release mode. The generator host enables Wasmtime's disposable
compiled-module cache for separate CLI/server processes; Wasmtime owns compatibility keys and rejects
corrupt or incompatible native artifacts by falling back to canonical compilation. The long-lived LSP
also owns one `GeneratorRuntime` and an in-memory prepared-module map keyed by the SHA-256 digest of
the exact core Wasm bytes. A changed plugin therefore cannot reuse a stale prepared module.

The CLI remains the independent cold/warm benchmark and automation path. The VS Code command does not
spawn it. The viewer displays module-preparation and guest-execution timings so cache behavior stays
observable during the spike.

The webview:

- applies a restrictive content-security policy with scripts disabled unless the minimal navigation
  bridge requires one nonce-scoped script;
- renders only SVG bytes returned by the expected generator invocation;
- supports fit-to-window and native scrolling, with optional deterministic client-only zoom;
- shows the model digest, view name, and stale/saved-state status;
- converts a click on an element with validated source metadata into a message to the extension; and
- lets the extension open the source URI and reveal the bounded range.

Do not allow SVG-provided URIs to open directly. The extension validates that navigation targets use an
allowed workspace/file scheme and that positions are finite non-negative integers before calling VS
Code APIs. Model-derived SVG text is inert and the SVG contains no scripts or external resources.

The panel retains the last successful artifact when regeneration fails and displays the new error
separately. It does not present stale output as current: compare the artifact model digest with the
digest reported by the successful invocation and label the panel accordingly.

Automatic regeneration on edit, multiple simultaneously live views, editable diagrams, persisted
coordinates, and a general plugin gallery are outside the first slice.

## Verification

Verification is layered so a failure identifies its owner:

1. The paired Spec42 work snapshots the exemplar's semantic state/view facts and typed projection.
2. Roc `expect` tests cover every supported projection-to-glyph and transition-label mapping.
3. `roc-graph-layout` retains its own geometry tests; the plugin tests layout invariants rather than
   coordinates where possible.
4. SVG structural tests parse or inspect stable markers: glyph counts, directed edges, labels,
   semantic IDs, escaping, bounds, and absence of scripts/external URLs.
5. The repository end-to-end script builds the packaged platform, compiles the plugin, runs Spec42,
   and compares the generated artifact byte-for-byte with the committed golden.
6. A negative fixture proves a missing, ambiguous, incomplete, or unsupported view is not reported as
   successful rendering.
7. VS Code extension tests cover command registration, dirty-document cancellation, process failure,
   SVG display, CSP construction, stale-result handling, and validated click-to-source navigation.
8. A VS Code integration test opens the exemplar, invokes the command with the packaged plugin, and
   observes the expected view identity and normative SVG markers in the panel.

Manual review compares the SVG with the relevant normative examples. Pixel identity with specification
figures is not a conformance criterion.

## Work sequence

This repository begins after the paired Spec42 query is available on a pinned revision:

1. Bump `.spec42-revision` and the SDK dependency together.
2. Extend the Rust adapter, hosted Roc functions, public Roc module, and generated glue.
3. Add the pinned `roc-graph-layout` package dependency to the exemplar app.
4. Implement the notation scene and minimal SVG serializer.
5. Add the exemplar and focused `expect` tests.
6. Extend `scripts/test.sh` and committed golden coverage.
7. Package the plugin for the VS Code development/release path and add the preview command/panel.
8. Add extension unit and integration coverage without duplicating semantic assertions in TypeScript.
9. Record discovered semantic, ABI, layout, notation, or editor-host gaps in the owning paired design
   while active.

## Exit criteria

The spike is successful when:

- the exemplar is accepted and semantically resolved by Spec42;
- the plugin uses only the typed state-transition query for diagram semantics;
- the generated SVG visibly and structurally uses the supported normative notation;
- the full packaged Wasm path runs without ambient capabilities;
- output is byte-deterministic across two clean executions;
- query, adapter, notation, layout, and SVG tests each cover their boundary; and
- VS Code can invoke the packaged generator for the saved exemplar, display its SVG in a readonly
  webview, and navigate a rendered state to its source range;
- generator or preview failure remains explicit and cannot make an older artifact appear current;
- unsupported notation and completeness limitations are documented and observable.

After these criteria pass, retain enduring API and architecture decisions in the owning documentation,
move unresolved limitations to active trackers, and remove this exploratory design when it has no live
decisions or work.
