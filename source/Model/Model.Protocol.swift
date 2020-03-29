import CoreData

/// - todo: Perhaps we should allow models to be structs, i.e., remove class conformance?

public protocol ModelProtocol: class {
    var id: Object.Id? { get set }
}

extension ModelProtocol {
    public var identified: Bool {
        self.id != nil
    }
}

// MARK: -

public protocol BatchConstructableModelProtocol: ModelProtocol {
    init(id: Object.Id?)
}
