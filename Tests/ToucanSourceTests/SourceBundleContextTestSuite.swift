//
//  File.swift
//  toucan
//
//  Created by Viasz-Kádi Ferenc on 2025. 02. 20..
//

import Foundation
import Testing
import ToucanModels
import ToucanTesting
@testable import ToucanSource

@Suite
struct SourceBundleContextTestSuite {

    @Test
    func isCurrentUrl() throws {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US")
        formatter.timeZone = .init(secondsFromGMT: 0)

        //        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        //        let nowString = formatter.string(from: now)

        let pipelines: [Pipeline] = [
            .init(
                scopes: [:],
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
                iterators: [:],
                transformers: [:],
                engine: .init(
                    id: "json",
                    options: [:]
                ),
                output: .init(
                    path: "",
                    file: "context",
                    ext: "json"
                )
            )
        ]

        // posts
        let postDefinition = ContentDefinition.Mocks.post()
        let rawPostContents = RawContent.Mocks.posts(
            max: 1,
            now: now,
            formatter: formatter
        )
        let postContents = rawPostContents.map {
            postDefinition.convert(rawContent: $0, using: formatter)
        }
        // pages
        let pageDefinition = ContentDefinition.Mocks.page()
        let rawPageContents: [RawContent] = [
            .init(
                origin: .init(
                    path: "",
                    slug: ""
                ),
                frontMatter: [
                    "title": "Home",
                    "description": "Home description",
                    "foo": ["bar": "baz"],
                ],
                markdown: """
                    # Home

                    Lorem ipsum dolor sit amet
                    """,
                lastModificationDate: Date().timeIntervalSince1970,
                assets: []
            )
        ]
        let pageContents = rawPageContents.map {
            pageDefinition.convert(rawContent: $0, using: formatter)
        }

        let contents =
            postContents +
            pageContents

        let sourceBundle = SourceBundle(
            location: .init(filePath: ""),
            config: .defaults,
            settings: .defaults,
            pipelines: pipelines,
            contents: contents
        )

        let results = try sourceBundle.generatePipelineResults(
            templates: [:]
        )

        #expect(results.count == 2)

        let decoder = JSONDecoder()

        struct Exp0: Decodable {
            struct Item: Decodable {
                let isCurrentURL: Bool
                let slug: String
            }
            struct Post: Decodable {
                let isCurrentURL: Bool
                let slug: String
            }
            let post: Post
            let featured: [Item]
        }

        let data0 = try #require(results[0].contents.data(using: .utf8))
        let exp0 = try decoder.decode(Exp0.self, from: data0)

        #expect(exp0.post.isCurrentURL)
        for item in exp0.featured {
            #expect(item.isCurrentURL == (exp0.post.slug == item.slug))
        }

        struct Exp1: Decodable {
            struct Item: Decodable {
                let isCurrentURL: Bool
            }
            struct Page: Decodable {
                let isCurrentURL: Bool
            }
            let page: Page
            let featured: [Item]
        }

        let data1 = try #require(results[1].contents.data(using: .utf8))
        let exp1 = try decoder.decode(Exp1.self, from: data1)

        #expect(exp1.page.isCurrentURL)
        #expect(exp1.featured.allSatisfy { !$0.isCurrentURL })
    }

}
