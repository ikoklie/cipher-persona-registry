# Cipher Persona Registry

**A decentralized identity protocol built in Clarity.**

Cipher Persona Registry empowers virtual communities with secure identity creation, profile management, and visibility governance on the Stacks blockchain.

---

## 📘 Features

- **Create and update identities**: Register members with bios, aliases, and labels.
- **Activity metrics**: Track visits and actions for community analytics.
- **Visibility control**: Manage access permissions to profile data.
- **Security-focused**: Enforced ownership checks for all mutations.
- **Optimized utilities**: Rapid update paths and efficient data validation.
- **Composable functions**: Extensible and modular profile operations.

---

## 📜 Contract Functions

| Function                         | Description                                              |
|----------------------------------|----------------------------------------------------------|
| `create-virtual-identity`        | Registers a new profile with alias, bio, and categories |
| `record-member-visit`           | Logs a visit and updates visit metrics                  |
| `revise-category-labels`        | Updates category labels with ownership validation       |
| `onboard-community-member`      | Full profile setup alternative                          |
| `modify-member-alias`           | Changes a member alias securely                         |
| `quick-label-update`            | Optimized category label updater                        |
| `enforce-profile-privacy`       | Validates wallet against profile for visibility control |
| `execute-full-profile-update`   | Atomic update for alias, bio, and categories            |
| `authenticate-identity-claim`   | Confirms if an address owns a profile                   |

---

## ⚙️ Deployment

Make sure you have Clarity CLI installed and deploy the contract on the Stacks testnet or mainnet:

```bash
clarity-cli launch
