<div align="center">
  <h1>♟ StarkChess – Your Move is Your Transaction</h1>
  <p><strong>The Immutable Game of Chess on Starknet</strong></p>
  <p>Turning chess into a fully on-chain prediction and staking arena</p>
</div>

---

## 💡 Problem

- **Centralized and opaque** online games erode trust
- **No guaranteed payouts** or verifiable outcomes
- **Spectators are passive** with no stake or upside
- **Financial transparency is missing** from gameplay and rewards

## ✅ Solution: StarkChess

**A trustless, on-chain chess protocol** where your move is your transaction and your audience can profit from your win.

- 100% on-chain gameplay using Cairo + Dojo Engine
- Smart contracts handle moves, payouts, and predictions
- Spectators can stake on who they think will win
- All actions final and verifiable on Starknet
- **Cartridge integration** for walletless onboarding and account abstraction

## 🎮 Game Modes

- **Player vs Player (PvP)**
  - Players stake $STRK or custom ERC-20s
  - Winner takes the pot via trustless payout

- **Player vs AI (PvE)**
  - On-chain AI powered by Cairo
  - Transparent, verifiable decision logic

- **Spectator Prediction Staking**
  - Users stake on match outcomes
  - Correct predictors share rewards
  - Winner earns a cut of prediction stakes

## 🔑 Key Features

- **Fully On-Chain Chess Logic** (Cairo + Dojo)
- **Stake-Based PvP Matches** with escrow and settlement
- **On-Chain AI Opponent** for solo play
- **Prediction & Reward Pools** for spectators
- **Trustless Payouts** for players and predictors
- **On-Chain Match History & Leaderboards**
- **Cartridge Integration** for seamless onboarding
- **100% Starknet-Native** — no servers, no middlemen

## 🧱 Architecture Overview

- **Match Contract**: Enforces turns, rules, and victory conditions
- **Stake Pool Contract**: Escrows stakes and handles settlement
- **Prediction Module**: Tracks predictions and rewards winners
- **Treasury**: Collects protocol fees (2–5%)
- **Cartridge SDK**: AA, session keys, walletless sign-in
- **Indexer (Torii/Subgraph)**: Indexes games, players, predictions

Project layout (selected):

```
client/                 # React, Vite, TypeScript, Tailwind, Zustand
  src/dojo/             # Dojo bindings, config, provider, hooks
  src/chess/            # Chess UI, logic, components, assets
contract/               # Cairo contracts (Dojo)
  src/systems/          # actions.cairo, move_validation.cairo
```

## 💸 Revenue Model

| Source | Description |
|---|---|
| Match Fees | 2–5% per match |
| Prediction Pool Fees | 3% of total pool |
| AI Challenges | Entry fees |
| Sponsorships | DAO or brand tournaments |

## 🎯 Target Audience

| Segment | Description | Motivation |
|---|---|---|
| Blockchain Gamers | Web3-native competitors | Earn by playing |
| Chess Enthusiasts | Traditional fans | Transparent play |
| DeFi Users | Predictive investors | Stake and profit |
| Developers | Cairo & Dojo builders | Contribute logic |
| Streamers | Chess influencers | Engage audience |

## 🧭 Why It Matters

- **Transparency**: Every move and payout verified on-chain
- **Fairness**: No central servers or hidden algorithms
- **Engagement**: Players and spectators both earn
- **Innovation**: First fusion of chess, DeFi, and on-chain gaming

---

## 🛠️ Tech Stack

```
Smart Contracts: Cairo + Dojo Engine
Frontend: React + Vite + TypeScript + TailwindCSS + Zustand
Wallet & Onboarding: Cartridge (account abstraction, session keys)
Network: Starknet (Local / Sepolia / Mainnet)
Indexing: Torii / Subgraph
```

## 🚀 Quick Start

Prereqs: Node 18+, pnpm/npm, Rust toolchain, Cairo/Dojo toolchain.

1) Install dependencies

```bash
cd client && pnpm install
```

2) Run the frontend

```bash
pnpm dev
```

3) Contracts (optional, local dev)

```bash
cd ../contract
# Start local Katana, build and deploy with Sozo as per contract/README.md
```

## 📂 Notable Paths

- `client/src/components/pages/ChessScreen.tsx` – main chess screen
- `client/src/chess/components/Board/Board.jsx` – board rendering
- `client/src/dojo/hooks/` – blockchain interaction hooks
- `contract/src/systems/actions.cairo` – on-chain actions
- `contract/src/systems/move_validation.cairo` – chess rules

## 🔐 Onboarding & Cartridge

StarkChess integrates Cartridge to enable frictionless onboarding:

- Walletless sign-in, session keys, account abstraction
- Safe, policy-based gameplay without constant signing
- Works across local, Sepolia, and mainnet networks

See: `client/src/config/cartridgeConnector.tsx` and `client/src/dojo/starknet-provider.tsx`.

## 🧪 Development Notes

- Uses Zustand for deterministic UI state and optimistic UX
- Hooks abstract all blockchain flows (`useSpawnPlayer`, `useChessMove`, etc.)
- Assets and chess UI live under `client/src/chess/`

## 🗺️ Roadmap (preview)

- Tournaments, seasons, DAOs for governance
- Advanced AI levels and training datasets
- NFT cosmetics and match collectibles
- Anti-abuse mechanisms and slashing for griefing

## 📜 License

MIT — see `LICENSE`.

## 🙌 Acknowledgments

- Built with Dojo Engine and Cartridge on Starknet
- Inspired by the potential of fully on-chain autonomous worlds

---

Made with ♟️ on Starknet
