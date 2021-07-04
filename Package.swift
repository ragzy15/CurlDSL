// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CurlDSL",
    platforms: [
		.macOS(.v10_15),
            .iOS(.v13),
            .tvOS(.v13),
            .watchOS(.v6)
    ],
	products: [
        .library(
            name: "CurlDSL",
            targets: ["CurlDSL"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ragzy15/NetworkKit", .branch("networker"))
    ],
    targets: [
        .target(
            name: "CurlDSL",
            dependencies: ["NetworkKit"]),
        .testTarget(
            name: "CurlDSLTests",
            dependencies: ["CurlDSL"]),
    ]
)
