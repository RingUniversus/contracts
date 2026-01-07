# Ring Universus

**Ring Universus** is an infinite on-chain universe of concentric Rings.

In this boundless expanse, the universe is structured into infinite concentric **Rings**, each possessing unique attributes, biomes, and rules. Commanders act as explorers, traversing the infinite void to claim **Stations**, discover powerful **Artifacts**, and restore order by neutralizing **Entropy Points**.

---

## 🌌 Lore & Concepts

The universe is a battleground between **Flux** (Flow) and **Entropy** (Stasis).

- **The Rings**: Experience an infinite procedural universe where each layer (Ring) offers distinct challenges and resources.
- **Exploration**: Venture outward or inward through the Rings to uncover the hidden secrets of the cosmos.

### Core Assets & Terminology

### 1. Flux (ERC20) - *The Energy*
**Flux** is the fundamental unit of energy in the universe. It represents "flow" and dynamic potential.
- **Usage**: Exploration consumes Flux. It is the fuel that powers your journey through the Rings.

### 2. Station (ERC721) - *The Land*
**Stations** (formerly Nodes) are the foothold of a Commander in the void.
- **Function**: These are claimable/tradeable land plots found within the Rings. A Station serves as a base for operations and resource generation.

### 3. Artifact (ERC721) - *The Equipment*
**Artifacts** (formerly Modules) are remnants of ancient technology or natural wonders found during exploration.
- **Function**: Equip Artifacts to enhance your exploration capabilities or combat strength.

### 4. Crystal (ERC721) - *The Essence*
**Crystals** are rare enhancements formed from condensed Flux or compressed Entropy.
- **Function**: Crystals can be **socketed** into **Stations** or **Artifacts** to unlock special abilities or boost stats.

### 5. Entropy Point - *The Anomaly*
**Entropy Points** (formerly Singularities) are manifestations of static chaos—the absolute opposite of Flux.
- **Mechanic**: Where Flux is moving energy, Entropy is dead silence. Players can discover these anomalies and repair them.
- **Reward**: Fixing an Entropy Point restores flow to the region and yields valuable rewards.

---

## 🛠 Technical Architecture

This project is built as a modular and upgradeable system using the **Diamond Standard (EIP-2535)**.

### Features

- **Modular Architecture**: Fully compliant with EIP-2535, allowing endless expansion of game logic without hitting contract size limits.
- **Optimized for Evolution**: Game mechanics (Facets) can be added, updated, or replaced transparently.
- **Viem & Hardhat**: Built for speed and developer experience.

## 🏁 Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) (v18+)
- [pnpm](https://pnpm.io/) (recommended)

### Installation

```bash
pnpm install
```

### Configuration

Create a `.env` file in the root directory and add your private key and provider URLs:

```env
PRIVATE_KEY=your_private_key
RPC_URL=your_rpc_url
```

## 📖 Usage

### Compilation

```bash
npx hardhat compile
```

### Generate Selectors

Before deploying or upgrading, run the selectors task to update the function map:

```bash
npx hardhat selectors
```

### Initial Deployment

Deploys the Diamond contract along with the standard facets and core game facets.

```bash
npx hardhat run scripts/deploy.ts --network <your-network>
```

### Upgrading the Game

The upgrade script automatically detects changes in your facets (e.g., new game mechanics) and prepares a `diamondCut` transaction.

```bash
npx hardhat run scripts/upgrade.ts --network <your-network>
```

## 💎 The Diamond Standard

**Ring Universus** utilizes EIP-2535 to ensure the game can evolve forever.
- **Facets**: Independent contracts that implement specific game logic (e.g., `ExplorationFacet`, `StationFacet`).
- **Diamond**: The central game contract.
