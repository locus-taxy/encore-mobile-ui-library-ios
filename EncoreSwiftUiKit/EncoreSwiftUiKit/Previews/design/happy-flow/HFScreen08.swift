import SwiftUI

// Screen 08 — Navigation hand-off to Google Maps (route overview). There is no in-app map, so
// this is a faithful full-bleed placeholder of Google Maps' dark route-preview screen: a
// destination search card, a stylised map with the route + ETA pills, floating map controls,
// and the directions bottom sheet (mode row + Start / Add stops / Save).
//
// This file hosts the shared HFMaps* placeholder chrome reused by screen 10.
struct HFScreen08: View {
    var onPrimary: () -> Void = {}
    var onSecondary: (Int) -> Void = { _ in }
    var onClose: () -> Void = {}
    var body: some View {
        HFMapsHandoff(
            onStart: onPrimary,
            onClose: onClose,
            originLabel: "IKEA Nagasandra Bengaluru",
            originIsMyLocation: false,
            destinationLabel: "Locus - Logistics Optimization & D…",
            etaPills: [HFMapsEta(text: "1 hr 27 min", primary: true),
                       HFMapsEta(text: "1 hr 22 min", primary: false)],
            zoomed: false,
            modes: [
                HFMapsMode(icon: "car.fill", time: "1 hr 31", active: false),
                HFMapsMode(icon: "bicycle", time: "1 hr 27", active: true),
                HFMapsMode(icon: "tram.fill", time: "1 hr 42", active: false),
                HFMapsMode(icon: "figure.walk", time: "6 hr", active: false),
                HFMapsMode(icon: "airplane", time: "", active: false),
            ],
            etaBig: "1h 27m",
            arriveText: "Arrive 8:51PM",
            detailText: "fastest route now due to traffic conditions",
            distanceText: "25 km",
            noteText: "This route has restricted usage or private…"
        )
    }
}

// MARK: - Shared Google Maps hand-off placeholder

struct HFMapsEta: Identifiable {
    let id = UUID()
    let text: String
    let primary: Bool
}

struct HFMapsMode: Identifiable {
    let id = UUID()
    let icon: String
    let time: String
    let active: Bool
}

struct HFMapsHandoff: View {
    var onStart: () -> Void = {}
    var onClose: () -> Void = {}
    let originLabel: String
    let originIsMyLocation: Bool
    let destinationLabel: String
    let etaPills: [HFMapsEta]
    let zoomed: Bool
    let modes: [HFMapsMode]
    let etaBig: String
    let arriveText: String
    let detailText: String
    let distanceText: String
    let noteText: String

    // Google Maps dark theme (external app — raw colours, not the Encore design system).
    private let mapBg = Color(.sRGB, red: 0.11, green: 0.15, blue: 0.21, opacity: 1)
    private let sheetBg = Color(.sRGB, red: 0.12, green: 0.13, blue: 0.14, opacity: 1)
    private let cardBg = Color(.sRGB, red: 0.17, green: 0.18, blue: 0.20, opacity: 1)
    private let controlBg = Color(.sRGB, red: 0.20, green: 0.21, blue: 0.23, opacity: 1)
    private let accent = Color(.sRGB, red: 0.54, green: 0.71, blue: 0.98, opacity: 1)
    private let etaBlue = Color(.sRGB, red: 0.15, green: 0.45, blue: 0.95, opacity: 1)
    private let teal = Color(.sRGB, red: 0.07, green: 0.55, blue: 0.53, opacity: 1)
    private let pillDark = Color(.sRGB, red: 0.10, green: 0.30, blue: 0.30, opacity: 1)
    private let subtle = Color.white.opacity(0.6)

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                searchCard
                    .padding(.horizontal, Spacing.spacing12)
                    .padding(.top, Spacing.spacing8)
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                bottomSheet
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(mapBg.ignoresSafeArea())
    }

    // Stylised map: faint roads, a route line, markers and ETA pills.
    private var mapLayer: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                mapBg
                // faint roads
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: w * 1.4, height: 10)
                        .rotationEffect(.degrees(Double(i) * 37 - 20))
                        .offset(x: CGFloat(i) * 30 - 40, y: CGFloat(i) * 90 - 60)
                }
                // route
                Path { p in
                    p.move(to: CGPoint(x: w * 0.30, y: h * 0.80))
                    p.addQuadCurve(to: CGPoint(x: w * 0.45, y: h * 0.55),
                                   control: CGPoint(x: w * 0.28, y: h * 0.66))
                    p.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.30),
                                   control: CGPoint(x: w * 0.62, y: h * 0.44))
                }
                .stroke(etaBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))

                if zoomed {
                    Circle()
                        .fill(accent.opacity(0.18))
                        .overlay(Circle().stroke(accent.opacity(0.5), lineWidth: 2))
                        .frame(width: w * 0.62, height: w * 0.62)
                    Circle().fill(Color.white).frame(width: 20, height: 20)
                        .overlay(Circle().fill(etaBlue).frame(width: 12, height: 12))
                }

                // destination marker
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(.sRGB, red: 0.85, green: 0.26, blue: 0.22, opacity: 1))
                    .position(x: w * 0.60, y: h * 0.30)

                // ETA pills
                VStack(alignment: .trailing, spacing: Spacing.spacing8) {
                    ForEach(etaPills) { pill in
                        HStack(spacing: Spacing.spacing4) {
                            Text(pill.text)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            if pill.primary {
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, Spacing.spacing8)
                        .padding(.vertical, Spacing.spacing4)
                        .background(pill.primary ? etaBlue : Color.white)
                        .foregroundColor(pill.primary ? .white : .black)
                        .clipShape(Capsule())
                    }
                }
                .position(x: w * 0.66, y: h * 0.42)

                // floating controls (layers + recenter)
                VStack {
                    HStack {
                        Spacer()
                        control("square.3.stack.3d")
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        control("location.north.fill")
                    }
                }
                .padding(Spacing.spacing12)
                .padding(.top, 120)     // intentional, off-scale: Google-Maps chrome inset
                .padding(.bottom, 200)  // intentional, off-scale: Google-Maps chrome inset
            }
        }
    }

    private func control(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(Circle().fill(controlBg))
    }

    private var searchCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.spacing12) {
                Image(systemName: originIsMyLocation ? "location.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(originIsMyLocation ? accent : subtle)
                Text(originLabel)
                    .font(.system(size: 15))
                    .foregroundColor(originIsMyLocation ? accent : .white)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(subtle)
            }
            .padding(.horizontal, Spacing.spacing12)
            .padding(.vertical, Spacing.spacing12)

            Divider().overlay(Color.white.opacity(0.12))

            HStack(spacing: Spacing.spacing12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(.sRGB, red: 0.85, green: 0.26, blue: 0.22, opacity: 1))
                Text(destinationLabel)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(subtle)
            }
            .padding(.horizontal, Spacing.spacing12)
            .padding(.vertical, Spacing.spacing12)
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(cardBg))
    }

    private var bottomSheet: some View {
        VStack(spacing: Spacing.spacing16) {
            Capsule().fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, Spacing.spacing8)

            HStack {
                Text("Two-wheeler")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: Spacing.spacing8) {
                    sheetControl("slider.horizontal.3")
                    sheetControl("square.and.arrow.up")
                    sheetControl("xmark")
                        .contentShape(Rectangle())
                        .onTapGesture { onClose() }
                }
            }

            HStack(spacing: 0) {
                ForEach(modes) { m in
                    VStack(spacing: Spacing.spacing4) {
                        Image(systemName: m.icon)
                            .font(.system(size: 18))
                            .foregroundColor(m.active ? accent : .white)
                        if !m.time.isEmpty {
                            Text(m.time)
                                .font(.system(size: 12))
                                .foregroundColor(m.active ? accent : subtle)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, m.active ? Spacing.spacing6 : 0)
                    .overlay(alignment: .bottom) {
                        if m.active {
                            Rectangle().fill(accent).frame(height: 2)
                        }
                    }
                }
            }

            HStack(alignment: .top, spacing: Spacing.spacing12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(etaBig)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(.sRGB, red: 0.95, green: 0.55, blue: 0.35, opacity: 1))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(arriveText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Text(detailText)
                        .font(.system(size: 13))
                        .foregroundColor(subtle)
                    Text(distanceText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Text(noteText)
                        .font(.system(size: 13))
                        .foregroundColor(subtle)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(accent))
            }

            HStack(spacing: Spacing.spacing12) {
                sheetButton("location.north.fill", "Start", fill: teal, text: .white)
                    .contentShape(Rectangle())
                    .onTapGesture { onStart() }
                // Add stops / Save (directions chrome) stay no-op for V1.
                sheetButton("shield.lefthalf.filled", "Add stops", fill: pillDark, text: accent)
                sheetButton("bookmark", "Save", fill: pillDark, text: accent)
            }
        }
        .padding(.horizontal, Spacing.spacing16)
        .padding(.bottom, Spacing.spacing32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(sheetBg)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func sheetControl(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 15))
            .foregroundColor(.white)
            .frame(width: 34, height: 34)
            .background(Circle().fill(controlBg))
    }

    private func sheetButton(_ icon: String, _ label: String, fill: Color, text: Color) -> some View {
        HStack(spacing: Spacing.spacing6) {
            Image(systemName: icon).font(.system(size: 14))
            Text(label).font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(text)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(Capsule().fill(fill))
    }
}
