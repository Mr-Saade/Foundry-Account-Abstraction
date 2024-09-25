> [!IMPORTANT]  
> This repository is for demonstration and educational purposes only.

# Account Abstraction with Foundry

<br/>

This repository contains two Account Abstraction projects built using Foundry:

- One compatible with Ethereum (Arbitrum as an example of EVM chains)
- One compatible with zkSync (Layer 2 solution)

## Table of Contents

- [Account Abstraction with Foundry](#account-abstraction-with-foundry)
  - [Table of Contents](#table-of-contents)
  - [What is Account Abstraction?](#what-is-account-abstraction)
  - [What does this project showcase?](#what-does-this-project-showcase)
  - [What does this project not cover?](#what-does-this-project-not-cover)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
- [Quickstart](#quickstart)
  - [Vanilla Foundry](#vanilla-foundry)
  - [zkSync Foundry](#zksync-foundry)
- [Disclaimer](#disclaimer)

## What is Account Abstraction?

Account Abstraction (AA) refers to allowing users to interact with blockchains using smart contracts as their account rather than traditional externally owned accounts (EOAs) that rely on private keys.

To put it simply, **Account Abstraction** turns EOAs into smart contracts with customizable logic for transaction validation and authorization.

> Account abstraction means that not only the execution of a transaction can involve complex computation logic, but also the authorization logic can be customized.
> – _Vitalik Buterin_

- [Vitalik's Thoughts on Account Abstraction](https://ethereum-magicians.org/t/implementing-account-abstraction-as-part-of-eth1-x/4020)
- [EntryPoint Contract v0.6 (Ethereum)](https://etherscan.io/address/0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789)
- [zkSync AA Transaction Flow](https://docs.zksync.io/build/developer-reference/account-abstraction.html#the-transaction-flow)

## What does this project showcase?

1. A minimal EVM-compatible "Smart Wallet" using alt-mempool-based Account Abstraction on Ethereum (Arbitrum in this case).
2. A minimal zkSync "Smart Wallet" using native Account Abstraction.
   - [zkSync AA is slightly different from ERC-4337](https://docs.zksync.io/build/developer-reference/account-abstraction.html#iaccount-interface).

## What does this project not cover?

1. Sending user operations to the alt-mempool.
   - You can refer to the [Alchemy documentation](https://alchemy.com/?a=673c802981) for more information.

---

# Getting Started

## Requirements

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - Confirm installation with `git --version`.
- [Foundry](https://getfoundry.sh/)
  - Confirm installation with `forge --version`.
- [Foundry-zkSync](https://github.com/matter-labs/foundry-zksync)
  - Confirm installation with `forge-zksync --help`.

## Installation

```bash
git clone https://github.com/Mr-Saade/Foundry-Account-Abstraction
cd Foundry-Account-Abstraction
make
```

# Quickstart

## Vanilla Foundry

```bash
foundryup
make test
```

## zkSync Foundry

```bash
foundryup-zksync
make zkbuild
make zktest
```

# Disclaimer

This codebase is for educational purposes only and has not undergone a security review. It is recommended not to use it with real funds unless it has been audited and security reviewed.
