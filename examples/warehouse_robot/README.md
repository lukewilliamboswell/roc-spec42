# Autonomous warehouse robot behaviour

This model captures the operational states of an autonomous pallet-moving robot, including
obstacle recovery, charging, and fault reset paths.

- `state_graph.roc` exports the transition topology as Graphviz DOT.
- `state_explorer.roc` generates a self-contained interactive HTML state explorer.
- `simulation_manifest.roc` generates a JSON contract for a simulation/control adapter.
