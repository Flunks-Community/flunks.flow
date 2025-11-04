import React, { useState } from 'react';
import * as fcl from '@onflow/fcl';

interface GumDropClaimButtonProps {
  userAddress?: string;
  username?: string;
}

export default function GumDropClaimButton({ userAddress, username }: GumDropClaimButtonProps) {
  const [isClaiming, setIsClaiming] = useState(false);
  const [txStatus, setTxStatus] = useState('');

  const handleClaimGumDrop = async () => {
    if (!userAddress || !username) {
      alert('Please connect your wallet first!');
      return;
    }

    setIsClaiming(true);
    setTxStatus('Preparing transaction...');

    try {
      // Auto-detect timezone
      const timezoneOffset = new Date().getTimezoneOffset() / -60;

      setTxStatus('Waiting for wallet approval...');

      const txId = await fcl.mutate({
        cadence: `
          import SemesterZero from 0xce9dd43888d99574
          import NonFungibleToken from 0x1d7e57aa55817448

          /// Claim GumDrop + Setup Timezone + Chapter 5 Collection
          /// 💡 Complete Chapter 5 objectives for a special treat!
          transaction(username: String, timezoneOffset: Int) {
            
            prepare(signer: auth(Storage, Capabilities) &Account) {
              // Setup UserProfile (if first time)
              let profileExists = signer.storage.borrow<&SemesterZero.UserProfile>(
                from: SemesterZero.UserProfileStoragePath
              ) != nil
              
              if !profileExists {
                let profile <- SemesterZero.createUserProfile(
                  username: username,
                  timezone: timezoneOffset
                )
                signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
                
                let cap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
                  SemesterZero.UserProfileStoragePath
                )
                signer.capabilities.publish(cap, at: SemesterZero.UserProfilePublicPath)
              }
              
              // Setup Chapter 5 NFT Collection (if first time)
              let collectionExists = signer.storage.borrow<&SemesterZero.Chapter5Collection>(
                from: SemesterZero.Chapter5CollectionStoragePath
              ) != nil
              
              if !collectionExists {
                let collection <- SemesterZero.createEmptyChapter5Collection()
                signer.storage.save(<-collection, to: SemesterZero.Chapter5CollectionStoragePath)
                
                let nftCap = signer.capabilities.storage.issue<&{NonFungibleToken.Receiver}>(
                  SemesterZero.Chapter5CollectionStoragePath
                )
                signer.capabilities.publish(nftCap, at: SemesterZero.Chapter5CollectionPublicPath)
              }
              
              // Verify eligibility for GumDrop
              assert(
                SemesterZero.isEligibleForGumDrop(user: signer.address),
                message: "You are not eligible or have already claimed"
              )
            }
            
            execute {
              log("GumDrop claim initiated - Chapter 5 collection ready!")
            }
          }
        `,
        args: (arg, t) => [
          arg(username, t.String),
          arg(timezoneOffset, t.Int)
        ],
        limit: 9999
      });

      setTxStatus('Transaction submitted! Waiting for confirmation...');

      await fcl.tx(txId).onceSealed();

      setTxStatus('✅ Success! GumDrop claimed!');

      // TODO: Call backend API to mark as claimed and add GUM to Supabase
      // await fetch('/api/mark-gumdrop-claimed', {
      //   method: 'POST',
      //   body: JSON.stringify({ walletAddress: userAddress, txId })
      // });

    } catch (error: any) {
      console.error('GumDrop claim error:', error);
      setTxStatus(`❌ Error: ${error.message || 'Transaction failed'}`);
    } finally {
      setIsClaiming(false);
    }
  };

  return (
    <div className="gumdrop-claim-container">
      <button
        onClick={handleClaimGumDrop}
        disabled={isClaiming || !userAddress}
        className="gumdrop-claim-button"
      >
        {isClaiming ? '⏳ Claiming...' : '🎃 Claim GumDrop'}
      </button>

      {txStatus && (
        <div className="tx-status">
          {txStatus}
        </div>
      )}

      <div className="chapter5-hint">
        💡 <strong>Slackers & Overachievers:</strong> Complete Chapter 5 objectives for a special treat!
      </div>

      <style jsx>{`
        .gumdrop-claim-container {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 1rem;
          padding: 2rem;
        }

        .gumdrop-claim-button {
          background: linear-gradient(135deg, #ff6b35, #f7931e);
          color: white;
          border: none;
          padding: 1rem 2rem;
          font-size: 1.5rem;
          font-weight: bold;
          border-radius: 12px;
          cursor: pointer;
          transition: transform 0.2s, box-shadow 0.2s;
          box-shadow: 0 4px 15px rgba(255, 107, 53, 0.4);
        }

        .gumdrop-claim-button:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(255, 107, 53, 0.6);
        }

        .gumdrop-claim-button:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }

        .tx-status {
          padding: 0.75rem 1.5rem;
          background: rgba(0, 0, 0, 0.8);
          border-radius: 8px;
          color: #fff;
          font-size: 0.9rem;
        }

        .chapter5-hint {
          text-align: center;
          padding: 1rem 1.5rem;
          background: rgba(255, 215, 0, 0.1);
          border: 2px dashed rgba(255, 215, 0, 0.5);
          border-radius: 8px;
          color: #ffd700;
          font-size: 0.95rem;
          max-width: 500px;
          animation: pulse 3s ease-in-out infinite;
        }

        @keyframes pulse {
          0%, 100% {
            opacity: 1;
            transform: scale(1);
          }
          50% {
            opacity: 0.8;
            transform: scale(1.02);
          }
        }
      `}</style>
    </div>
  );
}
