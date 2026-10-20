import Foundation

/// Which audio devices the Microphone page lists (spec 007 US3).
public enum AudioDeviceFilter {
    /// CoreAudio creates private aggregate devices for an app's own audio ("CADefaultDeviceAggregate-76427-0"); they
    /// aren't microphones the user can pick.
    public static func isUserFacing(name: String, uid: String) -> Bool {
        !(name.hasPrefix("CADefaultDeviceAggregate") || uid.hasPrefix("CADefaultDeviceAggregate"))
    }
}
