# Halloween Airdrop + Supabase Integration Guide 🎃

**Date**: October 20, 2025  
**Status**: Clear explanation of how systems interact

---

## 🤔 Your Questions Answered

### Q1: "Will the GUM drop directly populate on the website just like clicking 'Claim 15 GUM'?"

**Answer**: **NO** — It works differently, and **that's good** because it **won't break** your current system!

Here's how each system works:

---

## 📊 Two GUM Systems (They Don't Conflict!)

### **System 1: Daily GUM (Current System - Unchanged)**
**Location**: Supabase database only  
**Used for**: Daily clicking, challenges, social engagement  
**Display**: Shows in website UI immediately  
**No blockchain involved**

```
User clicks "Claim 15 GUM"
    ↓
Supabase: user_gum_balances.total_gum += 15
    ↓
Website shows updated balance INSTANTLY
    ↓
END (blockchain never touched)
```

**This continues to work exactly as it does today!**

---

### **System 2: Halloween Airdrop (New - October 31, 2025)**
**Location**: Blockchain FIRST, then optionally reflected in Supabase  
**Used for**: Special events, permanent rewards, collectible moments  
**Display**: Shows in "My Locker" → "Special Drops" section (new area)  
**Blockchain involved**: Yes, permanent record

```
Vercel Cron triggers at midnight
    ↓
API fetches users from Supabase (who earned 50+ GUM)
    ↓
Blockchain transaction: SemesterZero.GumAccount.deposit(100.0)
    ↓
Blockchain balance updated (permanent)
    ↓
Website polls blockchain, sees new balance
    ↓
Shows notification: "🎃 Halloween Drop Received!"
    ↓
OPTIONAL: Sync back to Supabase for display
```

---

## 🔄 How They Interact (No Conflicts!)

### Current Flow (Daily GUM - Unchanged):
```
┌─────────────┐
│   Website   │ User clicks "Claim 15 GUM"
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Supabase   │ total_gum += 15 (INSTANT)
└─────────────┘
       │
       ↓
Website shows: "500 GUM" → "515 GUM" (immediate)
```

**No blockchain involved. Fast. Free. Exactly like today.**

---

### Halloween Flow (Special Event - New):
```
┌─────────────┐
│ Vercel Cron │ Midnight Oct 31, 2025
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Supabase DB │ Query: "SELECT users WHERE total_gum >= 50"
└──────┬──────┘
       │
       ↓
┌─────────────┐
│  Blockchain │ SemesterZero.GumAccount.deposit(100.0)
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Website   │ Shows: "🎃 Halloween Drop: +100 GUM!"
└──────┬──────┘
       │
       ↓ (OPTIONAL)
┌─────────────┐
│  Supabase   │ event_gum += 100 (separate column!)
└─────────────┘
```

**Blockchain used for permanence. Separate from daily GUM.**

---

## 🎯 Where Does It Display?

### Option A: Separate "Special Drops" Section (Recommended)

**In "My Locker" page:**

```
┌────────────────────────────────────────┐
│           My Locker                    │
├────────────────────────────────────────┤
│                                        │
│  Daily GUM Balance: 515 🍬            │
│  (from Supabase, fast, always visible)│
│                                        │
├────────────────────────────────────────┤
│  🎃 Special Event Drops                │
├────────────────────────────────────────┤
│  ✨ Halloween 2025                     │
│     Received: Oct 31, 2025            │
│     Amount: +100 GUM                  │
│     Status: Claimed ✅                 │
│                                        │
│  [View on Blockchain] →                │
└────────────────────────────────────────┘
```

**Two separate displays:**
1. **Daily GUM** (Supabase) — Fast, free, immediate
2. **Event GUM** (Blockchain) — Permanent, collectible, special

---

### Option B: Combined Display (Shows Both)

```
┌────────────────────────────────────────┐
│  Total GUM Balance: 615 🍬             │
│                                        │
│  Daily Earned:     515 GUM (Supabase) │
│  Event Bonuses:    100 GUM (Blockchain)│
│                                        │
│  Last Event: 🎃 Halloween 2025         │
│  Received: Oct 31, 2025                │
└────────────────────────────────────────┘
```

---

## 🔧 Technical Implementation

### Supabase Schema (Add These Columns):

```sql
-- OPTION 1: Add to existing user_gum_balances table
ALTER TABLE user_gum_balances 
ADD COLUMN daily_gum NUMERIC DEFAULT 0,      -- Current clicking system
ADD COLUMN event_gum NUMERIC DEFAULT 0,       -- Blockchain airdrops
ADD COLUMN total_gum NUMERIC GENERATED ALWAYS AS (daily_gum + event_gum) STORED;

-- OPTION 2: Create separate event_airdrops table (cleaner)
CREATE TABLE event_airdrops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_address TEXT NOT NULL,
    event_name TEXT NOT NULL,              -- "halloween_2025"
    amount NUMERIC NOT NULL,                -- 100.0
    blockchain_tx_id TEXT,                  -- Flow transaction ID
    claimed_at TIMESTAMP DEFAULT NOW(),
    synced_from_blockchain BOOLEAN DEFAULT TRUE
);
```

---

## 🚀 Website API Integration

### 1. **Daily GUM (Current System - No Changes)**

```typescript
// app/api/gum/claim-daily/route.ts
export async function POST(req: Request) {
  const { walletAddress } = await req.json();
  
  // ✅ This continues to work exactly as today
  const { data } = await supabase
    .from('user_gum_balances')
    .update({ daily_gum: supabase.raw('daily_gum + 15') })
    .eq('wallet_address', walletAddress)
    .select()
    .single();
  
  return Response.json({ 
    success: true, 
    newBalance: data.daily_gum,
    message: "Claimed 15 GUM!" 
  });
}
```

**No blockchain. Instant. Free. Unchanged.**

---

### 2. **Halloween Airdrop (New System - October 31 only)**

```typescript
// app/api/halloween/autopush/route.ts
export async function POST(req: Request) {
  // Triggered by Vercel Cron at midnight Oct 31
  
  // Step 1: Query Supabase for eligible users
  const { data: users } = await supabase
    .from('user_gum_balances')
    .select('wallet_address, daily_gum')
    .gte('daily_gum', 50); // Must have 50+ from clicking
  
  // Step 2: Send to blockchain (Flow Actions)
  for (const user of users) {
    const txId = await fcl.mutate({
      cadence: AUTOPUSH_TRANSACTION,
      args: (arg, t) => [
        arg(user.wallet_address, t.Address),
        arg("100.0", t.UFix64),  // Halloween bonus
        arg("halloween_2025", t.String)
      ]
    });
    
    // Step 3: Log to Supabase (optional)
    await supabase.from('event_airdrops').insert({
      wallet_address: user.wallet_address,
      event_name: 'halloween_2025',
      amount: 100.0,
      blockchain_tx_id: txId
    });
  }
  
  return Response.json({ success: true });
}
```

---

### 3. **Display on Website**

```typescript
// app/my-locker/page.tsx
export default function MyLocker() {
  const [dailyGum, setDailyGum] = useState(0);
  const [eventDrops, setEventDrops] = useState([]);
  
  useEffect(() => {
    // Fetch daily GUM (Supabase - fast)
    fetchDailyGum();
    
    // Fetch event drops (blockchain - slower but permanent)
    fetchEventDrops();
  }, []);
  
  async function fetchDailyGum() {
    const { data } = await supabase
      .from('user_gum_balances')
      .select('daily_gum')
      .eq('wallet_address', user.addr)
      .single();
    
    setDailyGum(data.daily_gum); // Shows immediately
  }
  
  async function fetchEventDrops() {
    // Option A: Query Supabase (faster)
    const { data } = await supabase
      .from('event_airdrops')
      .select('*')
      .eq('wallet_address', user.addr);
    
    setEventDrops(data);
    
    // Option B: Query blockchain (source of truth)
    // const balance = await fcl.query({
    //   cadence: GET_GUM_BALANCE_SCRIPT,
    //   args: (arg, t) => [arg(user.addr, t.Address)]
    // });
  }
  
  return (
    <div>
      <h2>Daily GUM Balance: {dailyGum} 🍬</h2>
      <p>Keep clicking to earn more!</p>
      
      {eventDrops.length > 0 && (
        <div>
          <h3>🎃 Special Event Drops</h3>
          {eventDrops.map(drop => (
            <div key={drop.id}>
              <p>✨ {drop.event_name}</p>
              <p>Amount: +{drop.amount} GUM</p>
              <p>Received: {drop.claimed_at}</p>
              <a href={`https://flowscan.org/tx/${drop.blockchain_tx_id}`}>
                View on Blockchain →
              </a>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

---

## ⚡ Key Points: No Conflicts!

### ✅ **Daily GUM (Supabase Only)**
- User clicks → Supabase updates → Website shows immediately
- **No blockchain involved**
- Free, instant, unchanged from today
- Used for: Daily rewards, challenges, engagement

### ✅ **Halloween Airdrop (Blockchain + Supabase)**
- Cron runs → Blockchain transaction → Permanent record
- **Separate from daily clicking**
- Shows in special "Event Drops" section
- Used for: Special events, collectible moments

### ✅ **They Don't Interfere**
- Different data sources (Supabase vs blockchain)
- Different display sections (Daily vs Events)
- Different purposes (Engagement vs Collectibles)
- Can be combined in UI if desired

---

## 🎯 Recommended Approach

### **Split GUM into Two Types:**

1. **Daily GUM** (Supabase)
   - Fast, free, temporary
   - For clicking, challenges, social
   - Shows in main balance

2. **Event GUM** (Blockchain)
   - Permanent, collectible, special
   - For airdrops, achievements, milestones
   - Shows in "Special Drops" section

**Benefits:**
- ✅ Current system unchanged
- ✅ No performance impact
- ✅ Clear separation of concerns
- ✅ Blockchain used only for special moments
- ✅ Users get both instant feedback AND permanent records

---

## 🔄 Syncing Strategy

### **Option 1: One-Way Sync (Blockchain → Supabase)**
```
Blockchain (source of truth)
    ↓
Event listener detects deposit
    ↓
Webhook calls your API
    ↓
Supabase updated (for display)
```

**Pros**: Simple, no conflicts  
**Cons**: Requires webhook setup

---

### **Option 2: No Sync (Query Both)**
```
Website queries:
  1. Supabase for daily_gum (fast)
  2. Blockchain for event_gum (permanent)
  
Combines results in UI
```

**Pros**: No sync needed, always accurate  
**Cons**: Slightly slower (but cacheable)

---

### **Option 3: Manual Sync (On Demand)**
```
User clicks "Refresh Event Drops"
    ↓
Query blockchain for GumAccount.balance
    ↓
Update event_airdrops table
    ↓
Display updated
```

**Pros**: User controls when to check blockchain  
**Cons**: Not automatic

---

## 📋 Migration Checklist

- [ ] **Add columns to Supabase** (daily_gum, event_gum) OR create event_airdrops table
- [ ] **Update daily claim API** to use `daily_gum` column
- [ ] **Create Halloween autopush API** (Oct 31 only)
- [ ] **Add "Special Drops" section** to My Locker page
- [ ] **Test on testnet** with small group
- [ ] **Deploy before Oct 31, 2025**

---

## 🎃 Summary

**Your current daily GUM system will NOT break!**

- Daily clicking → Supabase only (unchanged)
- Halloween airdrop → Blockchain (new, separate)
- Two different displays on website
- No conflicts, no syncing issues
- Users get best of both worlds:
  - ✅ Instant daily rewards (Supabase)
  - ✅ Permanent event bonuses (Blockchain)

**The Halloween airdrop is a BONUS system, not a replacement!**
