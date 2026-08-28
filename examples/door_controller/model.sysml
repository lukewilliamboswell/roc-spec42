package DoorController {
    private import StandardViewDefinitions::*;
    private import ScalarValues::String;

    attribute controllerId : String = "door-controller-01";

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

    item def InspectionRequested;
    item def ServiceCompleted;

    state def MaintenanceLifecycle {
        then operational;
        state operational;
        state inspection;
        state servicing;
        final withdrawn;

        transition inspect first operational accept InspectionRequested then inspection;
        transition service first inspection then servicing;
        transition return_to_service first servicing accept ServiceCompleted then operational;
        transition withdraw first inspection then withdrawn;
    }

    view maintenanceLifecycle : StateTransitionView {
        expose MaintenanceLifecycle;
    }
}
