//
//  rendererconfig.swift
//  TestApp
//
//  Created by Tibor Bodecs on 2025. 01. 16..
//

import ToucanModels

public struct RenderPipeline {

    // content type -> scope key -> scope
    public var scopes: [String: [String: Scope]]
    public var queries: [String: Query]
    public var dataTypes: DataTypes
    public var contentTypes: [String]
    public var iterators: [String: Query]
    public var engine: Engine
    public var output: Output

    public init(
        scopes: [String: [String: Scope]],
        queries: [String: Query],
        dataTypes: DataTypes,
        contentTypes: [String],
        iterators: [String: Query],
        engine: RenderPipeline.Engine,
        output: Output
    ) {
        self.scopes = scopes
        self.queries = queries
        self.dataTypes = dataTypes
        self.contentTypes = contentTypes
        self.iterators = iterators
        self.engine = engine
        self.output = output
    }

    public func getScopes(
        for contentType: String
    ) -> [String: Scope] {
        if let scopes = scopes[contentType] {
            return scopes
        }
        return scopes["*"] ?? [:]
    }

    public func getScope(
        keyedBy key: String,
        for contentType: String
    ) -> Scope {
        let scopes = getScopes(for: contentType)
        // TODO: what should we return if there's no scope definition?
        return scopes[key] ?? .detail
    }
}
