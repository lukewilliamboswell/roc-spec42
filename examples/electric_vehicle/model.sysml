package ElectricVehicle {
    attribute def Text;
    attribute def Number;

    port def HighVoltagePort;
    port def CoolantPort;
    port def TorqueCommandPort;

    part def BatteryPack {
        doc /* Stores traction energy and reports pack health. */
        attribute partNumber : Text = "EV-BAT-82";
        attribute massKg : Number = 486;
        attribute nominalEnergyKWh : Number = 82;
        port dcOutput : HighVoltagePort;
        port coolant : CoolantPort;
    }

    part def Inverter {
        doc /* Converts pack DC power into controlled three-phase traction power. */
        attribute partNumber : Text = "EV-INV-400";
        attribute massKg : Number = 18;
        attribute peakPowerKW : Number = 210;
        port dcInput : HighVoltagePort;
        port torqueCommand : TorqueCommandPort;
        port coolant : CoolantPort;
    }

    part def TractionMotor {
        doc /* Permanent-magnet traction motor driving the rear axle. */
        attribute partNumber : Text = "EV-MTR-210";
        attribute massKg : Number = 72;
        attribute peakTorqueNm : Number = 430;
        port electricalInput : HighVoltagePort;
        port coolant : CoolantPort;
    }

    part def VehicleControlUnit {
        doc /* Coordinates driver demand, torque limits, charging, and diagnostics. */
        attribute partNumber : Text = "EV-VCU-12";
        attribute massKg : Number = 3;
        attribute asilLevel : Text = "ASIL-D";
        port torqueRequest : TorqueCommandPort;
    }

    part def ThermalLoop {
        doc /* Conditions the battery, inverter, and motor coolant circuits. */
        attribute partNumber : Text = "EV-THM-09";
        attribute massKg : Number = 21;
        attribute coolingCapacityKW : Number = 12;
        port batteryCoolant : CoolantPort;
        port inverterCoolant : CoolantPort;
        port motorCoolant : CoolantPort;
    }

    part def ElectricVehicleSystem {
        doc /* Long-range battery electric passenger vehicle. */
        part battery : BatteryPack;
        part inverter : Inverter;
        part motor : TractionMotor;
        part controller : VehicleControlUnit;
        part thermalLoop : ThermalLoop;
        connect battery.dcOutput to inverter.dcInput;
        connect inverter.dcInput to motor.electricalInput;
        connect controller.torqueRequest to inverter.torqueCommand;
        connect battery.coolant to thermalLoop.batteryCoolant;
        connect inverter.coolant to thermalLoop.inverterCoolant;
        connect motor.coolant to thermalLoop.motorCoolant;
    }

    requirement def DrivingRangeRequirement {
        doc /* The vehicle shall achieve at least 480 km on the combined certification cycle. */
        attribute id : Text = "EV-REQ-001";
        attribute verificationMethod : Text = "Certification road test";
        attribute status : Text = "Approved";
    }

    requirement def AccelerationRequirement {
        doc /* The vehicle shall accelerate from 0 to 100 km/h within 7.0 seconds. */
        attribute id : Text = "EV-REQ-002";
        attribute verificationMethod : Text = "Track test";
        attribute status : Text = "Approved";
    }

    requirement def BatterySafetyRequirement {
        doc /* The traction battery shall isolate high voltage following a detected crash. */
        attribute id : Text = "EV-REQ-003";
        attribute verificationMethod : Text = "Hardware-in-the-loop test";
        attribute status : Text = "Approved";
    }

    requirement def ThermalDeratingRequirement {
        doc /* Propulsion shall derate without damage when coolant temperature exceeds its limit. */
        attribute id : Text = "EV-REQ-004";
        attribute verificationMethod : Text = "Thermal chamber test";
        attribute status : Text = "Draft";
    }

    satisfy ElectricVehicleSystem by DrivingRangeRequirement;
    satisfy ElectricVehicleSystem by AccelerationRequirement;
    satisfy BatteryPack by BatterySafetyRequirement;
    satisfy ThermalLoop by ThermalDeratingRequirement;
    satisfy Inverter by ThermalDeratingRequirement;

    verification def RangeCertificationTest {
        doc /* Instrumented certification-cycle range test at nominal payload. */
        subject vehicle : ElectricVehicleSystem;
        objective { verify DrivingRangeRequirement; }
    }

    verification def AccelerationTrackTest {
        doc /* Repeated launch test with production tyres and nominal state of charge. */
        subject vehicle : ElectricVehicleSystem;
        objective { verify AccelerationRequirement; }
    }

    verification def CrashIsolationHilTest {
        doc /* Inject crash signals and verify contactor opening time. */
        subject battery : BatteryPack;
        objective { verify BatterySafetyRequirement; }
    }

    verification def HotWeatherDeratingTest {
        doc /* Soak the vehicle and exercise controlled thermal derating. */
        subject thermalLoop : ThermalLoop;
        objective { verify ThermalDeratingRequirement; }
    }
}
