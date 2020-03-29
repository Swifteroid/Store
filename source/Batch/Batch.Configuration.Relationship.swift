public protocol BatchRelationshipConfiguration {
    var relationship: RelationshipConfiguration? { get }
}

/// Relationship configuration tells batch how it should retrieve relationship models – can be used during loading
/// to pass into object relationship accessor corresponding configuration. Useful with interrelated models when
/// child refers to parents and shouldn't load any new ones. Todo: clear up this documentation and outline that
/// todo: this is not model's relationship, but when the model is the relationship itself…

public struct RelationshipConfiguration: OptionSet {
    public init(rawValue: Int) { self.rawValue = rawValue }

    public let rawValue: Int

    /// Construct relationships if they are not available within cache.
    public static let construct = RelationshipConfiguration(rawValue: 1 << 0)

    /// Update cached relationships.
    public static let update = RelationshipConfiguration(rawValue: 1 << 1)
}
