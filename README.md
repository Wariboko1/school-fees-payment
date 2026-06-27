# Token Faucet

A smart contract that drips a fixed amount of ERC-20 tokens to any address once every 24 hours. Built with Solidity and Foundry.

---

## What It Does

- Anyone can claim a fixed amount of tokens once per 24 hours
- Owner can adjust the drip amount at any time
- Owner can withdraw remaining tokens from the faucet
- Built-in cooldown tracking per wallet address
- Fully tested with 11 passing tests and 100% function coverage

---

## Contracts

| Contract      | Description                                                 |
| ------------- | ----------------------------------------------------------- |
| `MyToken.sol` | A simple ERC-20 token used to fund and test the faucet      |
| `Faucet.sol`  | The faucet contract that drips tokens on a 24 hour cooldown |

---

## Project Structure

```
token-faucet/
├── src/
│   ├── Faucet.sol               # Main faucet contract
│   └── MyToken.sol              # ERC-20 token contract
├── script/
│   └── DeployFaucet.s.sol       # Deployment script
├── test/
│   └── Faucet.t.sol             # Full test suite
├── .env.example                 # Environment variable template
├── .gitignore                   # Protects secrets from being pushed
└── foundry.toml                 # Foundry configuration
```

---

## Requirements

- [Foundry](https://getfoundry.sh/) installed
- [Git](https://git-scm.com/) installed
- A wallet with Sepolia testnet ETH
- An [Alchemy](https://alchemy.com) or [Infura](https://infura.io) RPC URL
- An [Etherscan](https://etherscan.io) API key

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR-USERNAME/token-faucet.git
cd token-faucet
```

### 2. Install dependencies

```bash
forge install
```

### 3. Set up environment variables

```bash
cp .env.example .env
```

Open `.env` and fill in your real values:

```bash
SEPOLIA_RPC_URL=your_alchemy_url_here
PRIVATE_KEY=your_wallet_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

> ⚠️ Never commit your `.env` file. It is already protected by `.gitignore`.

### 4. Load environment variables

```bash
source .env
```

---

## Usage

### Build

```bash
forge build
```

### Run Tests

```bash
forge test
```

### Run Tests with Verbose Output

```bash
forge test -vv
```

### Check Coverage

```bash
forge coverage
```

### Deploy to Sepolia Testnet

```bash
forge script script/DeployFaucet.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv
```

---

## Test Coverage

```
src/Faucet.sol     100% Lines    100% Statements    100% Funcs
src/MyToken.sol    100% Lines    100% Statements    100% Funcs
```

### Tests Written

| Test                                          | What It Checks                                                 |
| --------------------------------------------- | -------------------------------------------------------------- |
| `test_FaucetIsFunded`                         | Faucet receives correct token balance on deployment            |
| `test_UserCanClaimToken`                      | User receives correct drip amount on first claim               |
| `test_UserCanNotClaimTwiceIn24Hours`          | Cooldown blocks a second claim within 24 hours                 |
| `test_UserCanClaimAgainAfter24Hours`          | User can claim again after cooldown expires                    |
| `test_OwnerCanWithdraw`                       | Owner successfully drains faucet back to their wallet          |
| `test_NonOwnerCanNotWithdraw`                 | Non-owner is blocked from calling withdraw                     |
| `test_OwnerCanSetDripAmount`                  | Owner can update the drip amount                               |
| `test_NonOwnerCanNotSetDripAmount`            | Non-owner is blocked from updating drip amount                 |
| `test_RevertWhenFaucetIsEmpty`                | requestToken reverts with correct message when faucet is empty |
| `test_TimeUntilNextClaim`                     | Returns remaining cooldown seconds after a claim               |
| `test_TimeUntilNextClaimReturnsZeroWhenReady` | Returns zero when cooldown has expired                         |

---

## How It Works

```
1. Deploy MyToken.sol        →  Mints 1,000,000 MTK to deployer
2. Deploy Faucet.sol         →  Pass in token address and drip amount
3. Fund the faucet           →  Transfer tokens into the faucet contract
4. User calls requestToken() →  Receives drip amount if cooldown has passed
5. Cooldown resets           →  User must wait 24 hours before next claim
```

### Cooldown Logic

```
User calls requestToken()
        │
        ▼
Has 24 hours passed since last claim?
        │
   NO ──┴──► Revert: "Come back in 24 hours"
        │
       YES
        ▼
Does faucet have enough tokens?
        │
   NO ──┴──► Revert: "Faucet is empty"
        │
       YES
        ▼
Update lastClaimTime → Transfer tokens → Emit event ✅
```

---

## Security

- Follows the **Checks-Effects-Interactions** pattern to prevent reentrancy
- Owner functions protected by OpenZeppelin's `Ownable`
- State is updated before token transfer in `requestToken()`
- No admin backdoors — owner can only adjust drip amount or withdraw tokens

---

## Dependencies

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) — ERC20, Ownable
- [Forge Std](https://github.com/foundry-rs/forge-std) — Foundry testing library

---

## License

MIT
