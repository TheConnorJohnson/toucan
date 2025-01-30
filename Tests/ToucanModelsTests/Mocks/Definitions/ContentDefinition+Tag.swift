import ToucanModels

extension ContentDefinition.Mocks {

    static func tag() -> ContentDefinition {
        .init(
            type: "tag",
            paths: [
                "blog/tags"
            ],
            properties: [
                .init(
                    key: "name",
                    type: .string,
                    required: true,
                    default: nil
                )
            ],
            relations: [],
            queries: [
                "posts": .init(
                    contentType: "post",
                    scope: "???",
                    limit: 100,
                    offset: 0,
                    filter: .field(
                        key: "tags",
                        operator: .contains,
                        value: "{{id}}"
                    ),
                    orderBy: [
                        .init(key: "publication", direction: .desc)
                    ]
                )
            ]
        )
    }
}
