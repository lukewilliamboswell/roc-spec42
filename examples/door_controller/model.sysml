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
