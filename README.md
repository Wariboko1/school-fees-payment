# School Fees Payment Smart Contract

A Solidity smart contract built with Foundry that allows a school to manage and collect student fees on the Ethereum blockchain.

## What it does

- Admin registers students with their matric number, faculty, level and wallet address
- Admin sets fees per faculty and level
- Admin opens and closes the payment portal
- Students pay fees through the portal in ETH
- Late payments automatically include a penalty
- Admin can withdraw collected fees
- Admin can send payment reminders to unpaid students

## Contract Address (Sepolia Testnet)

`0xAb49704F5D014a97d20164EC12E62b7112780e1e`

## Built With

- Solidity ^0.8.22
- Foundry
- Forge Standard Library

## Getting Started

**Clone the repo**

```bash
git clone your_repo_url
cd your_project_folder
```

**Install Foundry**

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**Run tests**

```bash
forge test
```

**Check coverage**

```bash
forge coverage
```

**Deploy to Sepolia**

Create a `.env` file with:

SEPOLIA_RPC_URL=your_sepolia_rpc_url

PRIVATE_KEY=your_private_key

Then run:

```bash
source .env
forge script script/DeploySchoolFeesPayment.s.sol \
--rpc-url $SEPOLIA_RPC_URL \
--private-key $PRIVATE_KEY \
--broadcast
```

## Test Coverage

- 12 passing tests
- 90% line coverage
- 54% branch coverage

## License

MIT
