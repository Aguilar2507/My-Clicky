import Foundation
import Observation
import MyClickyCore

/// What one display's notch panel shows. Owned by NotchController, read by the SwiftUI views.
@MainActor
@Observable
final class NotchPanelUI {
    var geometry: NotchGeometry
    var isExpanded = false
    var onPopOut: () -> Void = {}
    var onClose: () -> Void = {}

    init(geometry: NotchGeometry) { self.geometry = geometry }
}
