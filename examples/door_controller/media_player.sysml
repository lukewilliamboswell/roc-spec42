package MediaPlayerExample {
    private import StandardViewDefinitions::*;
    private import ScalarValues::Boolean;

    attribute supportsGaplessPlayback : Boolean = true;

    item def LoadRequested;
    item def PlayRequested;
    item def PauseRequested;
    item def StopRequested;

    state def PlaybackLifecycle {
        then empty;
        state empty;
        state stopped;
        state playing;
        state paused;
        final shutdown;

        transition load first empty accept LoadRequested then stopped;
        transition play first stopped accept PlayRequested then playing;
        transition pause first playing accept PauseRequested then paused;
        transition resume first paused accept PlayRequested then playing;
        transition stop_playing first playing accept StopRequested then stopped;
        transition stop_paused first paused accept StopRequested then stopped;
        transition power_off first stopped then shutdown;
    }

    view playbackLifecycle : StateTransitionView {
        expose PlaybackLifecycle;
    }
}
