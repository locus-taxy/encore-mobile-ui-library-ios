import SwiftUI

// Screen 10 — Navigation hand-off to Google Maps (turn-by-turn, close to destination). Same
// external Google Maps placeholder as screen 08 but zoomed in: "Your location" origin, a short
// "1 min" ETA and a magnified navigation puck. Reuses HFMapsHandoff from HFScreen08.
struct HFScreen10: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        HFMapsHandoff(
            onStart: onPrimary,
            onClose: onClose,
            originLabel: "Your location",
            originIsMyLocation: true,
            destinationLabel: "Locus - Logistics Optimization & D…",
            etaPills: [HFMapsEta(text: "1 min", primary: true)],
            zoomed: true,
            modes: [
                HFMapsMode(icon: "car.fill", time: "1 min", active: false),
                HFMapsMode(icon: "bicycle", time: "1 min", active: true),
                HFMapsMode(icon: "tram.fill", time: "", active: false),
                HFMapsMode(icon: "figure.walk", time: "1 min", active: false),
                HFMapsMode(icon: "airplane", time: "", active: false),
            ],
            etaBig: "1 min",
            arriveText: "Arrive 7:28PM",
            detailText: "fastest route, the usual traffic",
            distanceText: "10 m",
            noteText: ""
        )
    }
}
