//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2025. 01. 31..
//

import Foundation

extension SiteBundle {

    public func run(query: Query) -> [Content] {
        let bundle = contentBundles.first {
            query.contentType == $0.definition.type
        }
        guard let bundle else {
            print("ERROR: no such content type")
            return []
        }
        return filter(contents: bundle.contents, using: query)
    }

    private func filter(
        contents: [Content],
        using query: Query
    ) -> [Content] {
        var filteredPageBundles = contents.filter { element in
            evaluate(condition: query.filter, with: element.properties)
        }

        for order in query.orderBy.reversed() {
            filteredPageBundles.sort { a, b in
                guard
                    let valueA = a.properties[order.key],
                    let valueB = b.properties[order.key]
                else { return false }
                return order.direction == .asc
                    ? (valueA < valueB) : (valueA > valueB)
            }
        }

        if let offset = query.offset {
            filteredPageBundles = Array(filteredPageBundles.dropFirst(offset))
        }

        if let limit = query.limit {
            filteredPageBundles = Array(filteredPageBundles.prefix(limit))
        }

        return filteredPageBundles
    }

    private func evaluate(
        condition: Condition?,
        with props: [String: PropertyValue]
    ) -> Bool {
        guard let condition else {
            return true
        }
        switch condition {
        case .field(let key, let `operator`, let value):
            guard let fieldValue = props[key] else { return false }
            guard let typedValue = PropertyValue(value) else { return false }
            return evaluateField(
                fieldValue: fieldValue,
                operator: `operator`,
                value: typedValue
            )

        case .and(let conditions):
            return conditions.allSatisfy {
                evaluate(condition: $0, with: props)
            }

        case .or(let conditions):
            return conditions.contains { evaluate(condition: $0, with: props) }
        }
    }

    private func evaluateField(
        fieldValue: PropertyValue,
        operator: Operator,
        value: PropertyValue
    ) -> Bool {
        switch `operator` {
        case .equals:
            return fieldValue == value
        case .notEquals:
            return fieldValue != value
        case .lessThan:
            return fieldValue < value
        case .greaterThan:
            return fieldValue > value
        case .lessThanOrEquals:
            return fieldValue <= value
        case .greaterThanOrEquals:
            return fieldValue >= value
        case .like:
            guard case let .string(fieldString) = fieldValue else {
                return false
            }
            guard case let .string(valueString) = value else { return false }
            return fieldString.contains(valueString)
        case .caseInsensitiveLike:
            guard case let .string(fieldString) = fieldValue else {
                return false
            }
            guard case let .string(valueString) = value else { return false }
            return fieldString.lowercased().contains(valueString.lowercased())
        // FIXME: double check if in & contains are ok like this or not...
        case .in:
            guard case let .array(valueArray) = value else { return false }
            return valueArray.contains(fieldValue)
        case .contains:
            guard case let .array(fieldArray) = fieldValue else { return false }
            return fieldArray.contains(fieldValue)
        }
    }

}
