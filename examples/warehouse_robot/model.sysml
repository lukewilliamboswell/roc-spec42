package WarehouseRobot {
    attribute def Text;
    attribute def Number;

    action def BootComplete;
    action def MissionAssigned;
    action def PathBlocked;
    action def PathCleared;
    action def PickConfirmed;
    action def DropConfirmed;
    action def BatteryLow;
    action def ChargeComplete;
    action def FaultDetected;
    action def ResetApproved;

    part def SafetyScanner {
        doc /* Monitors the protective field around the mobile robot. */
        attribute scanRangeM : Number = 8;
        attribute safetyRating : Text = "PL-d";
    }

    part def DriveBase {
        doc /* Differential-drive base with wheel odometry. */
        attribute maxSpeedMps : Number = 1.8;
        attribute payloadKg : Number = 650;
    }

    part def LiftModule {
        doc /* Raises and lowers pallets at storage locations. */
        attribute liftHeightM : Number = 1.6;
        attribute ratedLoadKg : Number = 500;
    }

    part def WarehouseRobotSystem {
        part scanner : SafetyScanner;
        part drive : DriveBase;
        part lift : LiftModule;
    }

    state def RobotMissionStateMachine {
        state booting;
        state idle;
        state navigatingToPick;
        state blocked;
        state picking;
        state navigatingToDrop;
        state dropping;
        state charging;
        state faulted;

        then booting;

        transition boot_completed first booting accept BootComplete then idle;
        transition mission_assigned first idle accept MissionAssigned then navigatingToPick;
        transition obstacle_detected first navigatingToPick accept PathBlocked then blocked;
        transition route_recovered first blocked accept PathCleared then navigatingToPick;
        transition arrived_at_pick first navigatingToPick then picking;
        transition load_secured first picking accept PickConfirmed then navigatingToDrop;
        transition arrived_at_drop first navigatingToDrop then dropping;
        transition load_released first dropping accept DropConfirmed then idle;
        transition low_battery_idle first idle accept BatteryLow then charging;
        transition charging_complete first charging accept ChargeComplete then idle;
        transition drive_fault first navigatingToPick accept FaultDetected then faulted;
        transition reset_after_fault first faulted accept ResetApproved then booting;
    }

    requirement def ProtectiveStopRequirement {
        doc /* The robot shall stop before entering an occupied protective field. */
        attribute id : Text = "AMR-SAF-001";
    }

    requirement def MissionRecoveryRequirement {
        doc /* The robot shall preserve its mission across a recoverable path obstruction. */
        attribute id : Text = "AMR-OPS-002";
    }

    satisfy SafetyScanner by ProtectiveStopRequirement;
    satisfy RobotMissionStateMachine by MissionRecoveryRequirement;
}
