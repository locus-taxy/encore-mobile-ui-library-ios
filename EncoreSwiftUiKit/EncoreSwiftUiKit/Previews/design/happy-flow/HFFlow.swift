import SwiftUI

// MARK: - Happy Flow — stitched interactive prototype (V1)
//
// Replaces the flat "screen number" gallery with a real tappable walkthrough:
// Home → Trip → (hub-validate) → Customer Stop → Task(s) → completion → Home.
// Each screen exposes onPrimary / onSecondary(index) / onClose; this coordinator
// maps those to the next screen per the V1 flow graph (single task at a time,
// no failed case — those are parked). Drill-ins push a level; X/back pops one.
//
// Interaction rules honoured (per ui-decisions):
//  • tap the trip card / a task card to drill in (no Next/Prev buttons)
//  • swipe CTAs advance state; a *disabled* swipe is tappable here as a test shortcut
//  • X abandons to the base of the current level; back returns to −1
//
// Flow graph (current → primary | secondary(i) | close):
//  01 Home        sec0→02
//  02 Trip start  pri→05 (swipe start → hub validate)        · close→01
//  05 Checklist   pri→06 (validate LUs → in-transit)         · close→02
//  06 Trip transit sec0→07 (tap the stop)                    · close→01
//  07 Stop (pre)  pri→09 (start / disabled-swipe tap)        · close→06
//  09 En route    pri→11                                     · close→06
//  11 Reached     pri→12 (swipe to arrive)                   · close→06
//  12 Arrived     pri→13 (reveal tasks)                      · close→06
//  13 Tasks       sec0→16 (delivery) · sec1→22 (pickup)      · close→06
//  16 Delivery    pri→17 (swipe to start task)               · close→13
//  17 In progress pri→18 (proof of delivery)                 · close→13
//  18 POD         pri→19 (submit)                            · close→13
//  19 Completed   pri→21 (back to stop, task 1 done)         · close→21
//  21 Stop (1 done) sec1→22 (pickup) · sec0→noop             · close→06
//  22 Pickup      pri→23 (swipe to start task)               · close→21
//  23 In progress pri→24 (proof)                             · close→21
//  24 POD         pri→26 (both tasks done → stop complete)   · close→21
//  26 Stop done   pri→27 (→ trip complete)                   · close→27
//  27 Trip done   pri→28 (swipe to end trip)                 · close→06
//  28 Home done   sec0→02 (loop)

public struct HFFlow: View {
    @State private var current: String = "01"
    public init() {}

    public var body: some View {
        screen(for: current)
            .id(current)
            .transition(.asymmetric(insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)))
            .animation(.easeInOut(duration: 0.22), value: current)
    }

    private func go(_ next: String) {
        withAnimation(.easeInOut(duration: 0.22)) { current = next }
    }

    // MARK: transition graph

    private func primary(from n: String) {
        switch n {
        case "02": go("05")   // swipe to start trip → hub-validate
        case "05": go("06")   // validate LUs → in-transit
        case "07": go("09")   // start work → en route
        case "09": go("11")   // en route → reached
        case "11": go("12")   // swipe to arrive → arrived
        case "16": go("17")   // swipe to start delivery task
        case "17": go("18")   // in progress → proof of delivery
        case "18": go("19")   // submit POD → delivery complete
        case "19": go("21")   // back to stop, task 1 done
        case "22": go("23")   // swipe to start pickup task
        case "23": go("24")   // in progress → proof
        case "24": go("26")   // submit → both tasks done, stop complete
        case "26": go("27")   // stop complete → trip complete
        case "27": go("28")   // swipe to end trip → home
        default: break
        }
    }

    private func secondary(from n: String, _ i: Int) {
        switch n {
        case "01": go("02")                    // tap Trip 1 card
        case "06": go("07")                    // tap the customer stop
        case "12": go(i == 1 ? "22" : "16")    // arrived: pick pickup (1) or delivery (0)
        case "21": if i == 1 { go("22") }      // remaining pickup task
        case "28": go("02")                    // loop
        default: break
        }
    }

    private func close(from n: String) {
        switch n {
        case "02": go("01")
        case "05": go("02")
        case "06": go("01")
        case "07", "09", "11", "12", "21", "27": go("06")
        case "16", "17", "18": go("12")
        case "19": go("21")
        case "22", "23", "24": go("21")
        case "26": go("27")
        default: go("01")
        }
    }

    // MARK: screen renderer

    @ViewBuilder
    private func screen(for n: String) -> some View {
        let onP = { primary(from: n) }
        let onS: (Int) -> Void = { i in secondary(from: n, i) }
        let onC = { close(from: n) }
        switch n {
        case "01": HFHome(onSecondary: onS)
        case "02": HFScreen02(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "05": HFScreen05(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "06": HFScreen06(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "07": HFScreen07(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "09": HFScreen09(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "11": HFScreen11(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "12": HFScreen12(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "13": HFScreen13(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "16": HFScreen16(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "17": HFScreen17(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "18": HFScreen18(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "19": HFScreen19(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "21": HFScreen21(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "22": HFScreen22(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "23": HFScreen23(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "24": HFScreen24(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "26": HFScreen26(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "27": HFScreen27(onPrimary: onP, onSecondary: onS, onClose: onC)
        case "28": HFScreen28(onPrimary: onP, onSecondary: onS, onClose: onC)
        default: HFPlaceholder(n: n)
        }
    }
}
