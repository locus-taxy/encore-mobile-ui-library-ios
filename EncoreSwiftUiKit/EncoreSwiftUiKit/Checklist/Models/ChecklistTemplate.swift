import Foundation

/// A parsed checklist: an ordered list of groups. Mirrors Android's `ChecklistTemplate`.
public struct ChecklistTemplate: Equatable {
    public let groups: [ChecklistGroup]

    public init(groups: [ChecklistGroup]) {
        self.groups = groups
    }

    /// Every item across all groups, in template order.
    public var allItems: [ChecklistItem] { groups.flatMap { $0.items } }
}

/// One checklist group: gated by an optional `show` expression, declaring the child groups it
/// re-evaluates when a controller inside it changes. Mirrors Android's `ChecklistGroup`.
public struct ChecklistGroup: Equatable, Identifiable {
    public let groupId: String
    /// Visibility expression (evalex tree as a JSON string). nil ⇒ always visible.
    public let show: String?
    /// Group ids re-evaluated when a controller in this group changes (HLD §3.3).
    public let childGroups: [String]
    public let items: [ChecklistItem]

    public var id: String { groupId }

    public init(groupId: String, show: String?, childGroups: [String], items: [ChecklistItem]) {
        self.groupId = groupId
        self.show = show
        self.childGroups = childGroups
        self.items = items
    }
}
