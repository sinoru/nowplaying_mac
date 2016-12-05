import PackageDescription

let package = Package(
    name: "NowPlaying-PM",
    dependencies: [
        .Package(url: "https://github.com/sinoru/STwitter-Swift.git", "2.0.0-develop.20161205132659")
        ],
    exclude: ["NowPlaying"]
)
