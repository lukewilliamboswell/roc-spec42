package TrafficLightExample {
    private import StandardViewDefinitions::*;
    private import ScalarValues::String;

    attribute intersectionId : String = "intersection-42";

    item def TimerExpired;

    state def TrafficLightCycle {
        then stopped;
        state stopped;
        state red;
        state green;
        state amber;
        final decommissioned;

        transition activate first stopped then red;
        transition allow_traffic first red accept TimerExpired then green;
        transition warn first green accept TimerExpired then amber;
        transition stop_traffic first amber accept TimerExpired then red;
        transition retire first red then decommissioned;
    }

    view trafficOperations : StateTransitionView {
        expose TrafficLightCycle;
    }
}
