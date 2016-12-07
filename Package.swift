import PackageDescription

let package = Package(
    name: "NowPlaying-PM",
    dependencies: [
        .Package(url: "https://github.com/sinoru/STwitter.git", "2.0.0-develop.20161207034300")
        ],
    exclude: ["NowPlaying"]
)
