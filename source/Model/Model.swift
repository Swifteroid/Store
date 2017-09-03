import CoreData

public protocol Model: class
{
    var id: Object.Id? { get set }
}

extension Model
{
    public var identified: Bool {
        return self.id != nil
    }
}

// MARK: -

public protocol BatchConstructableModel: Model
{
    init(id: Object.Id?)
}