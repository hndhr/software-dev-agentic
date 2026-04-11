---
name: data-create-datasource
description: |
  Create a DataSource protocol and RemoteDataSourceImpl for a new feature.
user-invocable: false
---

Create a DataSource following `.claude/reference/data-layer.md §4.2`.

## Steps

1. **Read** `.claude/reference/data-layer.md §4.2`
2. **Locate** module paths:
   - Protocol: `Talenta/Module/[Module]/Data/DataSource/[Feature]DataSource.swift`
   - Impl: `Talenta/Module/[Module]/Data/DataSource/[Feature]RemoteDataSourceImpl.swift`
3. **Create** both files

## DataSource Pattern

```swift
// Protocol
protocol [Feature]DataSourceProtocol {
    func methodName(params: [UseCase].Params,
                    completion: @escaping (Result<[Feature]Response, BaseErrorModel>) -> Void)
}

// Remote Implementation
final class [Feature]RemoteDataSourceImpl: [Feature]DataSourceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func methodName(params: [UseCase].Params,
                    completion: @escaping (Result<[Feature]Response, BaseErrorModel>) -> Void) {
        let request = [Feature]Request(params: params)
        apiClient.request(request, completion: completion)
    }
}
```

Rules:
- DataSource works with Response types — not Entities
- One DataSource protocol per feature module (can have multiple methods)
- Remote impl uses the project's `APIClient` — check existing patterns for the correct API client class
- Mark impl class `final`

## Output

Confirm both file paths and list all declared method signatures.
