// NFTDisplay.jsx - Display Chapter 5 NFTs on your website
import { useEffect, useState } from 'react'
import * as fcl from '@onflow/fcl'

const GET_CHAPTER5_NFTS = `
import SemesterZero from 0xce9dd43888d99574
import MetadataViews from 0x1d7e57aa55817448

access(all) fun main(account: Address): [{String: AnyStruct}] {
    let collection = getAccount(account)
        .capabilities.borrow<&SemesterZero.Chapter5Collection>(
            SemesterZero.Chapter5CollectionPublicPath
        )
    
    if collection == nil {
        return []
    }
    
    let nftIDs = collection!.getIDs()
    let result: [{String: AnyStruct}] = []
    
    for id in nftIDs {
        let nft = collection!.borrowChapter5NFT(id: id)!
        let display = nft.resolveView(Type<MetadataViews.Display>())! 
            as! MetadataViews.Display
        
        result.append({
            "id": nft.id,
            "name": display.name,
            "description": display.description,
            "image": display.thumbnail.uri(),
            "serialNumber": nft.serialNumber,
            "achievement": nft.achievementType,
            "revealed": nft.metadata["revealed"] ?? "false"
        })
    }
    
    return result
}
`

export function Chapter5NFTDisplay({ userAddress }) {
  const [nfts, setNfts] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchNFTs() {
      if (!userAddress) return
      
      try {
        const result = await fcl.query({
          cadence: GET_CHAPTER5_NFTS,
          args: (arg, t) => [arg(userAddress, t.Address)]
        })
        setNfts(result)
      } catch (error) {
        console.error('Error fetching NFTs:', error)
      } finally {
        setLoading(false)
      }
    }
    
    fetchNFTs()
  }, [userAddress])

  if (loading) return <div>Loading your Chapter 5 NFTs...</div>
  if (nfts.length === 0) return <div>No Chapter 5 NFTs found</div>

  return (
    <div className="nft-grid">
      <h2>Flunks: Semester Zero Collection</h2>
      {nfts.map((nft) => (
        <div key={nft.id} className="nft-card">
          <img src={nft.image} alt={nft.name} />
          <h3>{nft.name}</h3>
          <p>{nft.description}</p>
          <p>Serial #{nft.serialNumber}</p>
          <p>Achievement: {nft.achievement}</p>
          {nft.revealed === "false" && (
            <span className="unrevealed-badge">🔒 Unrevealed</span>
          )}
        </div>
      ))}
    </div>
  )
}
