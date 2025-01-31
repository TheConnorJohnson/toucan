//
//  PageBundleLocation.swift
//  toucan
//
//  Created by Tibor Bodecs on 2025. 01. 31..
//

public struct RawContentLocation {
    /// The original path of the page bundle directory, also serves as the page bundle identifier.
    let path: String
    /// The slug, derermined by the path and noindex files.
    let slug: String
}
