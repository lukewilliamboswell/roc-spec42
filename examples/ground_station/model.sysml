package GroundStation {
    attribute def Text;
    attribute def Number;

    item def TelecommandFrame;
    item def TelemetryFrame;
    item def TrackingMeasurement;
    item def MissionProduct;

    port def SpaceLinkPort;
    port def TrackingDataPort;
    port def MissionDataPort;

    part def AntennaSubsystem {
        doc /* Tracks the spacecraft and converts the RF space link to baseband. */
        attribute assetTag : Text = "GS-ANT-01";
        attribute diameterM : Number = 11;
        attribute availabilityTargetPct : Number = 99.5;
        port spaceLink : SpaceLinkPort;
        port tracking : TrackingDataPort;
    }

    part def BasebandProcessor {
        doc /* Encodes telecommands and decodes telemetry transfer frames. */
        attribute assetTag : Text = "GS-BBP-02";
        attribute maxDownlinkMbps : Number = 150;
        port rfLink : SpaceLinkPort;
        port trackingInput : TrackingDataPort;
        port missionOutput : MissionDataPort;
    }

    part def MissionControlSystem {
        doc /* Plans contacts, validates commands, and monitors spacecraft health. */
        attribute assetTag : Text = "GS-MCS-03";
        attribute operatorPositions : Number = 6;
        port commandAndTelemetry : SpaceLinkPort;
        port missionInput : MissionDataPort;
    }

    part def FlightDynamicsSystem {
        doc /* Estimates orbit state and produces tracking predictions. */
        attribute assetTag : Text = "GS-FDS-04";
        attribute propagationHorizonHours : Number = 72;
        port trackingInput : TrackingDataPort;
        port products : MissionDataPort;
    }

    part def GroundStationSystem {
        part antenna : AntennaSubsystem;
        part baseband : BasebandProcessor;
        part missionControl : MissionControlSystem;
        part flightDynamics : FlightDynamicsSystem;
        connect antenna.spaceLink to baseband.rfLink;
        connect antenna.tracking to baseband.trackingInput;
        connect antenna.tracking to flightDynamics.trackingInput;
        connect baseband.missionOutput to missionControl.missionInput;
        connect flightDynamics.products to missionControl.missionInput;
        connect baseband.rfLink to missionControl.commandAndTelemetry;
    }

    action def PlanContact {
        doc /* Build an executable contact plan from orbit predictions and station availability. */
    }

    action def AcquireSpacecraft {
        doc /* Slew, acquire carrier, and establish telemetry lock. */
    }

    action def ExecutePass {
        doc /* Exchange telemetry and approved telecommands during the contact window. */
    }

    action def PublishProducts {
        doc /* Deliver validated telemetry and orbit products to mission users. */
    }

    requirement def CommandAuthorizationRequirement {
        doc /* Every radiated telecommand shall have two-person authorization. */
        attribute id : Text = "GS-SEC-001";
    }

    requirement def ContactAvailabilityRequirement {
        doc /* The station shall provide at least 99.5 percent scheduled-contact availability. */
        attribute id : Text = "GS-OPS-002";
    }

    satisfy MissionControlSystem by CommandAuthorizationRequirement;
    satisfy AntennaSubsystem by ContactAvailabilityRequirement;
}
