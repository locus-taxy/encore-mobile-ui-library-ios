import SnapshottingTests

class EncoreButtonSnapshotTest: SnapshotTest {
    override class func snapshotPreviews() -> [String]? {
        return [
            "EncoreButton-Contained",
            "EncoreButton-Outlined",
            "EncoreButton-Text",
        ]
    }
}
