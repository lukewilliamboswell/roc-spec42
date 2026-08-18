package OrderFulfillmentExample {
    private import StandardViewDefinitions::*;
    private import ScalarValues::Integer;

    attribute packingStations : Integer = 4;

    item def PaymentConfirmed;
    item def PackingCompleted;
    item def CarrierCollected;

    state def OrderLifecycle {
        then awaitingPayment;
        state awaitingPayment;
        state readyToPack;
        state packed;
        state inTransit;
        final delivered;

        transition confirm_payment first awaitingPayment accept PaymentConfirmed then readyToPack;
        transition finish_packing first readyToPack accept PackingCompleted then packed;
        transition dispatch first packed accept CarrierCollected then inTransit;
        transition complete first inTransit then delivered;
    }

    view orderLifecycle : StateTransitionView {
        expose OrderLifecycle;
    }
}
