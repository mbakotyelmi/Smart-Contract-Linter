# 🔍 Smart Contract Linter

🎯 **Automated code quality assurance for Clarity smart contracts**

A comprehensive linting platform that analyzes Clarity smart contracts for code quality, security issues, and best practices. Perfect for developers learning smart contract development and teams maintaining high code standards.

## ✨ Features

🔬 **Automated Code Analysis**
- Quality scoring based on best practices
- Issue detection and categorization
- Severity classification (High/Medium/Low)

📊 **Quality Metrics**
- Real-time quality scoring (0-100)
- Quality levels: Excellent, Good, Fair, Poor
- Historical trend tracking

👤 **User Analytics**
- Personal linting history
- Performance improvement tracking
- Best score achievements
- Quality level rankings

🔄 **Batch Processing**
- Submit multiple contracts simultaneously
- Bulk quality assessments
- Efficiency for large codebases

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks blockchain testnet access

### Installation

```bash
git clone <your-repo>
cd smart-contract-linter
clarinet integrate
```

### Basic Usage

#### 1. 📤 Submit Contract for Linting

```clarity
(contract-call? .smart-contract-linter submit-contract-for-linting 
    "(define-public (hello-world) (ok \"Hello, World!\"))")
```

#### 2. 📋 Check Lint Results

```clarity
(contract-call? .smart-contract-linter get-lint-result u1)
```

#### 3. 👤 View User History

```clarity
(contract-call? .smart-contract-linter get-user-history 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### 4. 🏆 Check User Ranking

```clarity
(contract-call? .smart-contract-linter get-user-ranking 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 📝 Core Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `submit-contract-for-linting` | 📤 Submit contract code for analysis | `contract-code: string-ascii` |
| `batch-lint-contracts` | 🔄 Lint multiple contracts at once | `contracts: list` |
| `add-lint-issue` | ⚠️ Add specific issues (admin only) | `lint-id, issue-index, type, severity, line, description` |
| `update-lint-status` | 🔄 Update linting status (admin only) | `lint-id, new-status` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-lint-result` | 📋 Retrieve linting results | Complete lint analysis |
| `get-user-history` | 📊 Get user's linting history | User statistics |
| `get-user-ranking` | 🏆 Get user's quality ranking | Ranking details |
| `estimate-quality-score` | 🔍 Preview quality score | Estimated score |
| `get-platform-stats` | 📈 Platform-wide statistics | Total lints, current metrics |

## 🎯 Quality Scoring System

### Score Ranges
- 🏅 **90-100**: Excellent (Production-ready)
- ✅ **70-89**: Good (Minor improvements needed)
- ⚠️ **50-69**: Fair (Significant improvements required)
- ❌ **0-49**: Poor (Major refactoring needed)

### Scoring Factors
- ✅ Error handling implementation (+20 points)
- 🔒 Assertion usage (+15 points)
- 📋 Constants definition (+10 points)
- 🗃️ Data structures usage (+10 points)
- 🔐 Private functions (+10 points)
- 🌐 Public functions (+15 points)
- 📖 Code readability (+10 points)
- ⚡ Complexity penalty (-10 points for large contracts)

## 🔧 Development

### Testing

```bash
clarinet test
```

### Deployment

```bash
clarinet deploy --testnet
```

### Contract Integration

```clarity
;; Example integration
(use-trait linter-trait .smart-contract-linter)

(define-public (lint-my-contract (code (string-ascii 2048)))
    (contract-call? .smart-contract-linter submit-contract-for-linting code)
)
```

## 📊 Platform Statistics

Monitor platform usage and performance:
- Total contracts linted
- Average quality scores
- Most common issues
- User engagement metrics

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Links

- [Clarity Documentation](https://docs.stacks.co/clarity/)
- [Clarinet Guide](https://github.com/hirosystems/clarinet)
- [Stacks Blockchain](https://www.stacks.co/)

---

> 🚀 **Ready to improve your smart contract quality?** Start linting today!
