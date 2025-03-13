//
//  File.swift
//
//
//  Created by Tibor Bodecs on 03/05/2024.
//

import Foundation
import FileManagerKit
import Logging
import ToucanFileSystem
import ToucanTesting
import ToucanSource

public struct Toucan {

    let inputUrl: URL
    let outputUrl: URL
    let baseUrl: String?
    let logger: Logger

    let fileManager: FileManagerKit
    let fs: ToucanFileSystem
    let frontMatterParser: FrontMatterParser
    let encoder: ToucanEncoder
    let decoder: ToucanDecoder

    /// Initialize a new instance.
    /// - Parameters:
    ///   - input: The input url as a path string.
    ///   - output: The output url as a path string.
    ///   - baseUrl: An optional baseUrl to override the config value.
    public init(
        input: String,
        output: String,
        baseUrl: String?,
        logger: Logger = .init(label: "toucan")
    ) {
        self.fileManager = FileManager.default
        self.fs = ToucanFileSystem(fileManager: fileManager)
        self.encoder = ToucanYAMLEncoder()
        self.decoder = ToucanYAMLDecoder()
        self.frontMatterParser = FrontMatterParser(decoder: decoder)

        let home = fileManager.homeDirectoryForCurrentUser.path

        func getSafeUrl(_ path: String, home: String) -> URL {
            .init(
                fileURLWithPath: path.replacingOccurrences(["~": home])
            )
            .standardized
        }

        self.inputUrl = getSafeUrl(input, home: home)
        self.outputUrl = getSafeUrl(output, home: home)
        self.baseUrl = baseUrl
        self.logger = logger
    }

    // MARK: - directory management

    func resetDirectory(at url: URL) throws {
        if fileManager.exists(at: url) {
            try fileManager.delete(at: url)
        }
        try fileManager.createDirectory(at: url)
    }

    /// generates the static site
    public func generate() throws {
        let processId = UUID()
        let workDirUrl = fileManager
            .temporaryDirectory
            .appendingPathComponent("toucan")
            .appendingPathComponent(processId.uuidString)

        try resetDirectory(at: workDirUrl)

        logger.debug("Working at: `\(workDirUrl.absoluteString)`.")

        do {
            let sourceLoader = SourceLoader(
                sourceUrl: inputUrl,
                baseUrl: baseUrl,
                fileManager: fileManager,
                fs: fs,
                frontMatterParser: frontMatterParser,
                encoder: encoder,
                decoder: decoder,
                logger: logger
            )
            let sourceBundle = try sourceLoader.load()

            // TODO: - do we need this?
            // source.validate(dateFormatter: DateFormatters.baseFormatter)

            let results = try sourceBundle.generatePipelineResults()

            // MARK: - Preparing work dir

            try resetDirectory(at: workDirUrl)

            // MARK: - Copy default assets

            let assetsWriter = AssetsWriter(
                fileManager: fileManager,
                sourceConfig: sourceBundle.sourceConfig,
                workDirUrl: workDirUrl
            )
            try assetsWriter.copyDefaultAssets()

            // MARK: - Copy content assets
            
            let assetsPath = sourceBundle.config.contents.assets.path
            let assetsFolder = workDirUrl.appending(path: assetsPath)
            try fileManager.createDirectory(at: assetsFolder)
            
            let scrDirectory = sourceBundle.sourceConfig.contentsUrl
            
            for content in sourceBundle.contents {
                if !content.rawValue.assets.isEmpty {
                    let contentFolder = assetsFolder.appending(path: content.slug)
                    try fileManager.createDirectory(at: contentFolder)
                    
                    let originContentDir = URL(string: content.rawValue.origin.path)?.deletingLastPathComponent().path
                    let originFullPath = scrDirectory.appending(path: originContentDir ?? "").appending(path: assetsPath)
                    
                    for asset in content.rawValue.assets {
                        let fromFile = originFullPath.appending(path: asset)
                        let toFile = contentFolder.appending(path: asset)
                        
                        try fileManager.createDirectory(at: toFile.deletingLastPathComponent())
                        try fileManager.copy(from: fromFile, to: toFile)
                    }
                }
            }
            
            // MARK: - Writing results
            
            for result in results {
                let destinationFolder = workDirUrl.appending(path: result.destination.path)
                try fileManager.createDirectory(at: destinationFolder)

                let outputUrl =
                    destinationFolder
                    .appending(path: result.destination.file)
                    .appendingPathExtension(result.destination.ext)

                try result.contents.write(
                    to: outputUrl,
                    atomically: true,
                    encoding: .utf8
                )
            }

            // MARK: - Finalize and cleanup

            try resetDirectory(at: outputUrl)
            try fileManager.copyRecursively(from: workDirUrl, to: outputUrl)
            try? fileManager.delete(at: workDirUrl)
        }
        catch {
            try? fileManager.delete(at: workDirUrl)
            throw error
        }
    }
}
