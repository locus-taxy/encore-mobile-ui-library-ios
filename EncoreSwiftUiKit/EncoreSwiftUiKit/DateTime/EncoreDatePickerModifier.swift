import SwiftUI

/// Presents the shared Encore graphical date picker (the same bottom sheet used
/// by `EncoreDateView`) when `isPresented` becomes true. Attach it to any view
/// so a custom control — e.g. a calendar icon — can open the picker on tap.
///
/// Prefer the `View.encoreDatePicker(...)` convenience over instantiating this
/// directly.
public struct EncoreDatePickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let initialDate: Date
    var dateRange: ClosedRange<Date>?
    var showTodayShortcut: Bool
    var showYesterdayShortcut: Bool
    let onDateSelected: (Date) -> Void

    @State private var isSheetVisible = false
    @State private var selectedDate = Date()

    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                ZStack(alignment: .bottom) {
                    Color.encore("Backdrop/Fill")
                        .opacity(isSheetVisible ? 0.5 : 0)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.22), value: isSheetVisible)
                    pickerSheet
                        .background(Color.encore("Background/Default"))
                        .offset(y: isSheetVisible ? 0 : 1000)
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isSheetVisible)
                        .allowsHitTesting(isSheetVisible)
                }
                .modifier(EncoreDatePickerClearPresentationBackground())
                .onAppear {
                    selectedDate = initialDate
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        isSheetVisible = true
                    }
                }
            }
    }

    // MARK: - Shortcut visibility

    private var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var yesterdayDate: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }

    private var canShowToday: Bool {
        showTodayShortcut && (dateRange?.contains(todayDate) ?? true)
    }

    private var canShowYesterday: Bool {
        showYesterdayShortcut && (dateRange?.contains(yesterdayDate) ?? true)
    }

    // MARK: - Helpers

    private func closeSheet() {
        isSheetVisible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.none) { isPresented = false }
        }
    }

    // MARK: - Picker sheet

    private var pickerSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 0) {
                Button {
                    closeSheet()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.encore("Text/Primary"))
                        .frame(width: 48, height: 48)
                }
                Spacer()
                Text("Pick a date")
                    .typography(Typography.h5)
                    .foregroundColor(Color.encore("Text/Primary"))
                Spacer()
                // Mirror for optical centering
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 48, height: 48)
                    .opacity(0)
                    .allowsHitTesting(false)
            }
            .padding(8)

            // Calendar + shortcuts
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    if let dateRange {
                        DatePicker(
                            "Pick a date",
                            selection: $selectedDate,
                            in: dateRange,
                            displayedComponents: .date
                        )
                    } else {
                        DatePicker(
                            "Pick a date",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                    }
                }
                .datePickerStyle(.graphical)
                .tint(Color.encore("Primary/Main"))
                .padding(.vertical, -8)

                if canShowToday || canShowYesterday {
                    HStack(spacing: 8) {
                        if canShowToday {
                            EncoreButton(
                                label: "Today",
                                startIconName: nil,
                                endIconName: nil,
                                color: .primary,
                                variant: .text,
                                size: .medium,
                                action: { selectedDate = todayDate }
                            )
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        if canShowYesterday {
                            EncoreButton(
                                label: "Yesterday",
                                startIconName: nil,
                                endIconName: nil,
                                color: .primary,
                                variant: .text,
                                size: .medium,
                                action: { selectedDate = yesterdayDate }
                            )
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
            }
            .padding(16)

            // Actions
            VStack(spacing: 0) {
                EncoreButton(label: "Apply",
                             endIconName: nil,
                             size: .large) {
                    onDateSelected(selectedDate)
                    closeSheet()
                }
                .padding(16)
            }
            .background(Color.encore("Background/Default"))
            .shadow(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 0)
        }
    }
}

public extension View {
    /// Opens the shared Encore graphical date picker (identical to the one in
    /// `EncoreDateView`) as a bottom sheet when `isPresented` becomes true.
    ///
    /// - Parameters:
    ///   - isPresented: Drives presentation. Set to `true` (e.g. from a tap) to open.
    ///   - selectedDate: The date the picker opens on.
    ///   - dateRange: Optional selectable range; also gates the shortcut links.
    ///   - showTodayShortcut: Show a "Today" quick-select link.
    ///   - showYesterdayShortcut: Show a "Yesterday" quick-select link.
    ///   - onDateSelected: Called with the chosen date when "Apply" is tapped.
    func encoreDatePicker(
        isPresented: Binding<Bool>,
        selectedDate: Date,
        dateRange: ClosedRange<Date>? = nil,
        showTodayShortcut: Bool = false,
        showYesterdayShortcut: Bool = true,
        onDateSelected: @escaping (Date) -> Void
    ) -> some View {
        modifier(EncoreDatePickerModifier(
            isPresented: isPresented,
            initialDate: selectedDate,
            dateRange: dateRange,
            showTodayShortcut: showTodayShortcut,
            showYesterdayShortcut: showYesterdayShortcut,
            onDateSelected: onDateSelected
        ))
    }
}

// MARK: - Transparent presentation background

/// Makes the `fullScreenCover` platter transparent from the first frame.
///
/// On iOS 16.4+ `presentationBackground(.clear)` is applied synchronously as
/// part of the presentation — so there's no opaque frame (the "flash"). Below
/// 16.4 it falls back to clearing the host view's background, which happens a
/// frame late.
private struct EncoreDatePickerClearPresentationBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackground(.clear)
        } else {
            content.background(EncoreDatePickerTransparentBackground())
        }
    }
}

/// Pre-16.4 fallback: clears the presented container's background asynchronously.
private struct EncoreDatePickerTransparentBackground: UIViewRepresentable {
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}
}
