# Engineering example matrix

These examples start with a modeller's deliverable, not with an API feature. Each directory is a
self-contained SysML workspace with three Roc generators that can be built and run independently.

| Model | Modeller's need | Script | Deliverable |
| --- | --- | --- | --- |
| Electric vehicle | Maintain requirements-to-design-to-test traceability | `vcrm_csv.roc` | Verification cross-reference matrix (CSV) |
| Electric vehicle | Publish a design baseline from modelled part attributes | `bom_csv.roc` | Bill of materials (CSV) |
| Electric vehicle | Give reviewers a navigable architecture snapshot | `engineering_dashboard.roc` | Standalone HTML dashboard |
| Warehouse robot | Review behavioural topology | `state_graph.roc` | Graphviz state graph (DOT) |
| Warehouse robot | Walk operational and recovery paths without a simulator | `state_explorer.roc` | Interactive standalone HTML explorer |
| Warehouse robot | Configure a simulation or control adapter | `simulation_manifest.roc` | JSON manifest and nested controller properties |
| Ground station | Baseline system endpoints for an ICD | `icd_csv.roc` | Interface-control register (CSV) |
| Ground station | Review integration connectivity | `network_graph.roc` | Graphviz interface network (DOT) |
| Ground station | Brief operators and engineering stakeholders | `operations_dashboard.roc` | Standalone HTML dashboard |

For example, from the repository root:

```sh
roc build examples/electric_vehicle/vcrm_csv.roc --output=vcrm.wasm
spec42 --no-stdlib generate vcrm.wasm examples/electric_vehicle/model.sysml --output=generated
```

The simulation manifest demonstrates one plugin returning multiple files in different directories.
The HTML outputs have no external assets or network dependencies. DOT files can be rendered with
Graphviz, and CSV files open directly in spreadsheet and requirements-management workflows.

Each model's `output/` directory contains the committed result of every script so the examples can
be inspected without installing Roc or Spec42. The packaged end-to-end test compares regenerated
artifacts byte-for-byte with these golden files. After an intentional output change, refresh them
with:

```sh
scripts/update-example-snapshots.sh
git diff -- examples/*/output
```
