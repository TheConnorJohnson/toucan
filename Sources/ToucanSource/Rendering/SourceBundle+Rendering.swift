//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2025. 02. 11..
//

import Foundation
import FileManagerKit
import ToucanModels
import ToucanCodable
import Mustache

struct ContextBundle {

    struct Destination {
        let path: String
        let file: String
        let ext: String
    }

    let context: [String: AnyCodable]
    let template: String?
    let destination: Destination
}

extension SourceBundle {

    func getDates(
        for timeInterval: Double,
        using formatter: DateFormatter,
        formats: [String: String] = [:]
    ) -> DateFormats {
        let date = Date(timeIntervalSince1970: timeInterval)

        let styles: [(String, DateFormatter.Style)] = [
            ("full", .full),
            ("long", .long),
            ("medium", .medium),
            ("short", .short),
        ]

        var dateFormats: [String: String] = [:]
        var timeFormats: [String: String] = [:]

        for (key, style) in styles {
            formatter.dateStyle = style
            formatter.timeStyle = .none
            dateFormats[key] = formatter.string(from: date)

            formatter.dateStyle = .none
            formatter.timeStyle = style
            timeFormats[key] = formatter.string(from: date)
        }

        let standard: [String: String] = [
            "iso8601": "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "rss": "EEE, dd MMM yyyy HH:mm:ss Z",
            "sitemap": "yyyy-MM-dd",
        ]
        var custom: [String: String] = [:]
        for (k, f) in formats.recursivelyMerged(with: standard) {
            formatter.dateFormat = f
            custom[k] = formatter.string(from: date)
        }

        return .init(
            date: .init(
                full: dateFormats["full"]!,
                long: dateFormats["long"]!,
                medium: dateFormats["medium"]!,
                short: dateFormats["short"]!
            ),
            time: .init(
                full: timeFormats["full"]!,
                long: timeFormats["long"]!,
                medium: timeFormats["medium"]!,
                short: timeFormats["short"]!
            ),
            timestamp: timeInterval,
            formats: custom
        )
    }

    func getContextObject(
        slug: String?,
        for content: Content,
        context: RenderPipeline.Scope.Context,
        using source: SourceBundle,
        allowSubQueries: Bool = true  // allow top level queries only
    ) -> [String: AnyCodable] {

        var result: [String: AnyCodable] = [:]
        if context.contains(.properties) {

            let formatter = DateFormatter()
            formatter.locale = .init(identifier: "en_US")
            formatter.timeZone = .init(secondsFromGMT: 0)
            // TODO: validate locale
            if let rawLocale = source.settings.locale {
                formatter.locale = .init(identifier: rawLocale)
            }
            if let rawTimezone = source.settings.timeZone,
                let timeZone = TimeZone(identifier: rawTimezone)
            {
                formatter.timeZone = timeZone
            }

            for (k, v) in content.properties {
                if let p = content.definition.properties[k],
                    case .date(_) = p.type,
                    let rawDate = v.value(as: Double.self)
                {
                    result[k] = .init(
                        getDates(
                            for: rawDate,
                            using: formatter,
                            formats: source.config.dateFormats.output
                                .recursivelyMerged(with: [
                                    "test": "Y"
                                ])
                        )
                    )
                }
                else {
                    result[k] = .init(v.value)
                }
            }

            result["slug"] = .init(content.slug)
            result["permalink"] = .init(
                content.slug.permalink(baseUrl: source.settings.baseUrl)
            )
            result["isCurrentURL"] = .init(content.slug == slug)
        }
        if allowSubQueries, context.contains(.relations) {
            for (key, relation) in content.definition.relations {
                var orderBy: [Order] = []
                if let order = relation.order {
                    orderBy.append(order)
                }
                let relationContents = source.run(
                    query: .init(
                        contentType: relation.references,
                        scope: "properties",
                        filter: .field(
                            key: "id",
                            operator: .in,
                            value: .init(
                                content.relations[key]?.identifiers ?? []
                            )
                        ),
                        orderBy: orderBy
                    )
                )
                result[key] = .init(
                    relationContents.map {
                        getContextObject(
                            slug: content.slug,
                            for: $0,
                            context: .properties,
                            using: self,
                            allowSubQueries: false
                        )
                    }
                )
            }

        }
        if context.contains(.contents) {
            // TODO: render using renderer.
            result["contents"] = .init(content.rawValue.markdown)
        }
        if allowSubQueries, context.contains(.queries) {
            for (key, query) in content.definition.queries {
                // TODO: replace {{}} variables in query filter values...
                let queryContents = source.run(
                    query: query.resolveFilterParameters(
                        with: content.queryFields
                    )
                )

                result[key] = .init(
                    queryContents.map {
                        getContextObject(
                            slug: content.slug,
                            for: $0,
                            context: .all,
                            using: self,
                            allowSubQueries: false
                        )
                    }
                )
            }
        }
        return result
    }

    // TODO: return full context instead of complete render?
    func getContextBundles(
        pipelineContext: [String: AnyCodable],
        pipeline: RenderPipeline
    ) throws -> [ContextBundle] {

        var bundles: [ContextBundle] = []

        let engineOptions = pipeline.engine.options
        // TODO: This should be engine specific somehow...
        let contentTypesOptions = engineOptions.dict("contentTypes")

        for contentBundle in contentBundles {
            let bundleOptions = contentTypesOptions.dict(
                contentBundle.definition.type
            )

            let contentTypeTemplate = bundleOptions.string("template")

            for content in contentBundle.contents {
                let context: [String: AnyCodable] = [
                    //                        "global": pipelineContext,
                    "local": .init(
                        getContextObject(
                            slug: content.slug,
                            for: content,
                            context: .all,
                            using: self
                        )
                    )
                ]

                // TODO: more path arguments
                let outputArgs: [String: String] = [
                    "{{id}}": content.id,
                    "{{slug}}": content.slug,
                ]

                let path = pipeline.output.path.replacingOccurrences(outputArgs)
                let file = pipeline.output.file.replacingOccurrences(outputArgs)
                let ext = pipeline.output.ext.replacingOccurrences(outputArgs)

                let contentTemplate = content.rawValue.frontMatter.string(
                    "template"
                )

                let bundle = ContextBundle(
                    context: context,
                    template: contentTemplate ?? contentTypeTemplate,
                    destination: .init(
                        path: path,
                        file: file,
                        ext: ext
                    )
                )
                bundles.append(bundle)
            }
        }
        return bundles
    }

    func getPipelineContext(
        for pipeline: RenderPipeline
    ) -> [String: AnyCodable] {
        var rawContext: [String: AnyCodable] = [:]
        for (key, query) in pipeline.queries {
            let results = run(query: query)

            let scope = pipeline.getScope(
                keyedBy: query.scope ?? "list",  // TODO: list by default?
                for: query.contentType
            )

            rawContext[key] = .init(
                results.map {
                    getContextObject(
                        slug: nil,
                        for: $0,
                        context: scope.context,
                        using: self
                    )
                }
            )
        }
        return rawContext
    }

    func render(  // TODO: url input
        ) throws
    {
        let url = FileManager.default.homeDirectoryForCurrentUser.appending(
            path: "output"
        )

        if FileManager.default.exists(at: url) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.createDirectory(at: url)

        for pipeline in renderPipelines {
            let context = getPipelineContext(for: pipeline)
            let bundles = try getContextBundles(
                pipelineContext: context,
                pipeline: pipeline
            )

            switch pipeline.engine.id {
            case "json", "context":
                let encoder = JSONEncoder()
                encoder.outputFormatting = [
                    .prettyPrinted,
                    .withoutEscapingSlashes,
                    //.sortedKeys,
                ]

                for bundle in bundles {
                    let folder = url.appending(path: bundle.destination.path)
                    try FileManager.default.createDirectory(at: folder)

                    let outputUrl =
                        folder
                        .appending(path: bundle.destination.file)
                        .appendingPathExtension(bundle.destination.ext)

                    let data = try encoder.encode(context)
                    try data.write(to: outputUrl)
                    //                    prettyPrint(context)
                }
            case "mustache":

                let renderer = MockHTMLRenderer(templates: [
                    "post.default.template": """
                    <html>
                    <head>
                    </head>
                    <body>
                    {{title}}
                    {{publication}}
                    </body>
                    </html>
                    """,
                    "default": """
                    <html>
                    <head>
                    </head>
                    <body>
                    {{title}}
                    </body>
                    </html>
                    """,
                ])

                for bundle in bundles {
                    let folder = url.appending(path: bundle.destination.path)
                    try FileManager.default.createDirectory(at: folder)

                    let outputUrl =
                        folder
                        .appending(path: bundle.destination.file)
                        .appendingPathExtension(bundle.destination.ext)

                    try renderer.render(
                        template: bundle.template ?? "default",  // TODO
                        with: bundle.context,
                        to: outputUrl
                    )
                }

            default:
                print("ERROR - no such renderer \(pipeline.engine.id)")
            }
        }
    }

}

struct MockHTMLRenderer {

    var templates: [String: String]

    func replaceTopLevelKeys(
        in template: String,
        with dictionary: [String: AnyCodable]
    ) -> String {
        var output = template
        for (key, value) in dictionary {
            let token = "{{\(key)}}"
            let replacement: String = {
                if let v = value.value {
                    return String(describing: v)
                }
                return ""
            }()
            output = output.replacingOccurrences(of: token, with: replacement)
        }
        return output
    }

    func render(
        template: String,
        with object: [String: AnyCodable],
        to destination: URL
    ) throws {
        guard let tpl = templates[template] else {
            return
        }

        // TODO: remove local
        let output = replaceTopLevelKeys(in: tpl, with: object.dict("local"))

        try output.write(
            to: destination,
            atomically: true,
            encoding: .utf8
        )
    }
}
