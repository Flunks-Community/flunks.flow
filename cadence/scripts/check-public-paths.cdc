access(all) fun main(address: Address): [String] {
    let account = getAccount(address)
    let paths: [String] = []
    
    // Check some common collection paths
    let commonPaths = [
        "/public/SimpleFlunksCollection",
        "/public/SimpleFlunksWithTraitsCollection", 
        "/public/SimpleFlunksV2Collection"
    ]
    
    for path in commonPaths {
        let publicPath = PublicPath(identifier: path.slice(from: 8, upTo: path.length))!
        if account.capabilities.get<&AnyResource>(publicPath) != nil {
            paths.append(path)
        }
    }
    
    return paths
}
