//
//  File.swift
//  toucan
//
//  Created by Viasz-Kádi Ferenc on 2025. 02. 20..
//

import Foundation
import Testing
import ToucanModels
import ToucanContent
import ToucanTesting
import Logging
@testable import ToucanSource

@Suite
struct SourceBundlePageLinkTestSuite {

    @Test
    func testPageLink() throws {
        let logger = Logger(label: "SourceBundlePageLinkTestSuite")
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US")
        formatter.timeZone = .init(secondsFromGMT: 0)

        let pipelines: [Pipeline] = [
            .init(
                id: "html",
                scopes: [
                    "*": [
                        "detail": Pipeline.Scope(
                            context: Pipeline.Scope.Context(rawValue: 31),
                            fields: []
                        ),
                        "list": Pipeline.Scope(
                            context: Pipeline.Scope.Context(rawValue: 11),
                            fields: []
                        ),
                        "reference": Pipeline.Scope(
                            context: Pipeline.Scope.Context(rawValue: 3),
                            fields: []
                        ),
                    ]
                ],
                queries: [
                    "featured": .init(
                        contentType: "post",
                        scope: "list"
                    )
                ],
                dataTypes: .defaults,
                contentTypes: .init(
                    include: [],
                    exclude: [],
                    lastUpdate: []
                ),
                iterators: [
                    "post.pagination": Query(
                        contentType: "post",
                        scope: "detail",
                        limit: 9,
                        offset: nil,
                        filter: nil,
                        orderBy: [
                            Order(
                                key: "publication",
                                direction: ToucanModels.Direction.desc
                            )
                        ]
                    )
                ],
                transformers: [:],
                engine: .init(
                    id: "mustache",
                    options: [:]
                ),
                output: .init(
                    path: "{{slug}}",
                    file: "index",
                    ext: "html"
                )
            )
        ]

        let postContent = Content(
            id: "post",
            slug: "post",
            rawValue: RawContent(
                origin: Origin(path: "", slug: "post"),
                frontMatter: [
                    "publication": .init("2025-01-10 01:02:03")
                ],
                markdown: "",
                lastModificationDate: 1742843632.8373249,
                assets: []
            ),
            definition: ContentDefinition(
                id: "post",
                default: false,
                paths: ["posts"],
                properties: [:],
                relations: [:],
                queries: [:]
            ),
            properties: [:],
            relations: [:],
            userDefined: [:]
        )

        let content = Content(
            id: "{{post.pagination}}",
            slug: "posts/page/{{post.pagination}}",
            rawValue: RawContent(
                origin: Origin(
                    path: "posts/{{post.pagination}}/index.md",
                    slug: "{{post.pagination}}"
                ),
                frontMatter: [
                    "home": .init("posts/page"),
                    "title": .init("Posts - {{number}} / {{total}}"),
                    "slug": .init("posts/page/{{post.pagination}}"),
                    "description": .init("Posts page - {{number}} / {{total}}"),
                    "css": .init([]),
                    "js": .init([]),
                    "type": .init("page"),
                    "template": .init("posts"),
                    "image": nil,
                ],
                markdown: "",
                lastModificationDate: 1742843632.8373249,
                assets: []
            ),
            definition: ContentDefinition(
                id: "page",
                default: true,
                paths: ["home", "about", "authors", "tags", "search"],
                properties: [
                    "title": Property(
                        type: PropertyType.string,
                        required: true,
                        default: nil
                    )
                ],
                relations: [:],
                queries: [:]
            ),
            properties: ["title": AnyCodable("Posts - {{number}} / {{total}}")],
            relations: [:],
            userDefined: [
                "home": .init("posts/page"),
                "description": .init("Posts page - {{number}} / {{total}}"),
                "css": .init([]),
                "js": .init([]),
                "template": .init("posts"),
                "image": nil,
            ]
        )

        let contents: [Content] = [postContent, content]
        let templates: [String: String] = [
            "posts": Templates.Mocks.pageLink()
        ]

        let config = Config.defaults
        let sourceConfig = SourceConfig(
            sourceUrl: .init(fileURLWithPath: ""),
            config: config
        )

        let sourceBundle = SourceBundle(
            location: .init(filePath: ""),
            config: config,
            sourceConfig: sourceConfig,
            settings: .defaults,
            pipelines: pipelines,
            contents: contents,
            blockDirectives: [],
            templates: templates,
            baseUrl: "http://localhost:3000/"
        )

        var renderer = SourceBundleRenderer(
            sourceBundle: sourceBundle,
            dateFormatter: formatter,
            fileManager: FileManager.default,
            logger: logger
        )
        
        let results = try renderer.renderPipelineResults(now: now)

        #expect(results.count == 1)
        #expect(results[0].contents.contains("<title>Posts - 1 / 1 - </title>"))
        #expect(results[0].destination.path == "posts/page/1")
    }

}
