import SwiftUI

/// Stateful checklist entry point (HLD §9). Give it the parsed `template` and an `evaluator`; it
/// owns the visibility engine, dynamic-options resolution, and answer state, and renders the visible
/// rows — resolving/re-resolving options and resetting stale selections as controllers change.
/// Mirrors Android's `ChecklistTemplateView`.
///
/// For a pre-resolved static item list (no groups / no expressions), use `ChecklistView` instead.
public struct ChecklistTemplateView<Header: View>: View {
    private let header: Header
    private let submitButtonText: String
    private let itemCallbacks: ChecklistItemCallbackProvider?
    private let onSubmit: ([String: ChecklistItemValue]) -> Void

    @StateObject private var driver: ChecklistTemplateDriver

    public init(
        template: ChecklistTemplate,
        evaluator: ChecklistExpressionEvaluator,
        initialValues: [String: Any] = [:],
        onValueChange: (([String: Any]) -> Void)? = nil,
        onSubmit: @escaping ([String: ChecklistItemValue]) -> Void,
        onGroupEvaluationFailed: @escaping (String) -> Void = { _ in },
        onDynamicOptionsUnresolved: @escaping (String) -> Void = { _ in },
        submitButtonText: String = "Submit",
        itemCallbacks: ChecklistItemCallbackProvider? = nil,
        @ViewBuilder header: () -> Header
    ) {
        self.header = header()
        self.submitButtonText = submitButtonText
        self.itemCallbacks = itemCallbacks
        self.onSubmit = onSubmit
        _driver = StateObject(wrappedValue: ChecklistTemplateDriver(
            template: template,
            evaluator: evaluator,
            initialValues: initialValues,
            onValueChanged: onValueChange,
            onGroupEvaluationFailed: onGroupEvaluationFailed,
            onDynamicOptionsUnresolved: onDynamicOptionsUnresolved
        ))
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(driver.visibleItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Color.encore("Background/ColumnHeading")
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity)
                            }
                            ChecklistItemRenderer(
                                item: item,
                                itemIndex: index + 1,
                                totalItems: driver.visibleItems.count,
                                stateManager: driver.stateManager,
                                itemCallbacks: itemCallbacks
                            )
                            .transition(.checklistReveal)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: Spacing.spacing4) {
                        SlidingButtonView(label: submitButtonText, onSlideComplete: {
                            onSubmit(driver.submissionMap())
                        })
                        .disabled(!driver.canSubmit())

                        if !driver.canSubmit() {
                            Text("Finish mandatory (*) checklist items to complete task")
                                .typography(Typography.Input.helper)
                                .foregroundColor(Color.encore("Text/Secondary"))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard let id = driver.firstInvalidRequiredItemID() else { return }
                                    withAnimation { proxy.scrollTo(id, anchor: .top) }
                                }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.encore("Background/Default"))
                }
            }
        }
    }
}

// MARK: - Convenience initializer with String header

public extension ChecklistTemplateView where Header == AnyView {
    init(
        headerText: String,
        template: ChecklistTemplate,
        evaluator: ChecklistExpressionEvaluator,
        initialValues: [String: Any] = [:],
        onValueChange: (([String: Any]) -> Void)? = nil,
        onSubmit: @escaping ([String: ChecklistItemValue]) -> Void,
        onGroupEvaluationFailed: @escaping (String) -> Void = { _ in },
        onDynamicOptionsUnresolved: @escaping (String) -> Void = { _ in },
        submitButtonText: String = "Submit",
        itemCallbacks: ChecklistItemCallbackProvider? = nil
    ) {
        self.init(
            template: template,
            evaluator: evaluator,
            initialValues: initialValues,
            onValueChange: onValueChange,
            onSubmit: onSubmit,
            onGroupEvaluationFailed: onGroupEvaluationFailed,
            onDynamicOptionsUnresolved: onDynamicOptionsUnresolved,
            submitButtonText: submitButtonText,
            itemCallbacks: itemCallbacks,
            header: {
                AnyView(
                    Text(headerText)
                        .font(.system(size: 20, weight: .bold))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
            }
        )
    }
}
