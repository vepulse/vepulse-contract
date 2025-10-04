# Vepulse Smart Contracts

VeChain smart contracts for Vepulse - a decentralized platform for creating and managing polls, surveys, and projects with built-in funding and reward mechanisms.

## Features

- **Projects**: Create and manage projects that organize multiple polls and surveys
- **Polls & Surveys**: Create standalone or project-based polls and surveys with time limits
- **Funding**: Fund polls and surveys with VET tokens to incentivize participation
- **Rewards**: Responders can claim equal shares of the funding pool after completion
- **Access Control**: Project creators have full control over their projects and items

## Smart Contract Architecture

The `Vepulse.sol` contract provides:

### Project Management
- Create projects with name and description
- Update project information
- Deactivate projects
- Organize polls and surveys within projects

### Poll & Survey Management
- Create polls and surveys (standalone or within projects)
- Set duration for each poll/survey
- Automatic expiration based on end time
- Track responses and prevent duplicates

### Funding & Rewards
- Fund polls/surveys with VET tokens
- Equal reward distribution among all responders
- Secure claim mechanism with reentrancy protection
- Refund mechanism for cancelled items

## Installation

1. Clone the repository:
```bash
cd ../vepulse-contract
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file for production deployments:
```bash
cp .env.example .env
# Edit .env and add your mnemonic phrase
```

## Compilation

Compile the smart contracts:
```bash
npm run compile
```

## Testing

Run the test suite:
```bash
npm test
```

## Deployment

### Deploy to VeChain Testnet

```bash
npm run deploy:testnet
```

### Deploy to VeChain Mainnet

**Warning**: Ensure you have the correct mnemonic in your `.env` file before deploying to mainnet.

```bash
npm run deploy:mainnet
```

## Usage Examples

### Creating a Project

```javascript
const tx = await vepulse.createProject(
  "Community Feedback Q1 2024",
  "Quarterly community feedback initiative"
);
const receipt = await tx.wait();
const projectId = 1; // First project
```

### Creating a Poll

```javascript
// Standalone poll (projectId = 0)
const duration = 7 * 24 * 60 * 60; // 7 days in seconds
await vepulse.createPoll(
  "What feature should we build next?",
  "Vote for the next major feature",
  duration,
  0 // projectId (0 for standalone)
);

// Poll within a project
await vepulse.createPoll(
  "Rate our service",
  "How satisfied are you with our service?",
  duration,
  projectId
);
```

### Creating a Survey

```javascript
const duration = 14 * 24 * 60 * 60; // 14 days
await vepulse.createSurvey(
  "User Experience Survey",
  "Help us improve your experience",
  duration,
  projectId
);
```

### Funding a Poll/Survey

```javascript
const fundingAmount = ethers.parseEther("100"); // 100 VET
await vepulse.fundPollSurvey(pollId, { value: fundingAmount });
```

### Submitting a Response

```javascript
await vepulse.submitResponse(pollId);
```

### Ending a Poll/Survey

```javascript
// Creator can end anytime
await vepulse.endPollSurvey(pollId);

// Anyone can end after endTime has passed
// (automatic expiration)
```

### Claiming Rewards

```javascript
// After poll/survey has ended
await vepulse.claimReward(pollId);
```

### Querying Data

```javascript
// Get project details
const project = await vepulse.getProject(projectId);

// Get poll/survey details
const poll = await vepulse.getPollSurvey(pollId);

// Check if user has responded
const responded = await vepulse.hasResponded(pollId, userAddress);

// Get all responders
const responders = await vepulse.getResponders(pollId);

// Get potential reward amount
const reward = await vepulse.getPotentialReward(pollId);

// Get user's projects
const userProjects = await vepulse.getUserProjects(userAddress);

// Get user's polls/surveys
const userItems = await vepulse.getUserPollsSurveys(userAddress);
```

## Contract Structure

### Enums
- `ItemType`: POLL, SURVEY
- `ItemStatus`: ACTIVE, ENDED, CANCELLED

### Structs
- `Project`: Project metadata and references to polls/surveys
- `PollSurvey`: Poll or survey data including funding and responses

### Key Functions

#### Project Management
- `createProject(name, description)`: Create a new project
- `updateProject(projectId, name, description)`: Update project details
- `deactivateProject(projectId)`: Deactivate a project

#### Poll/Survey Management
- `createPoll(title, description, duration, projectId)`: Create a poll
- `createSurvey(title, description, duration, projectId)`: Create a survey
- `submitResponse(itemId)`: Submit a response
- `endPollSurvey(itemId)`: End a poll/survey
- `cancelPollSurvey(itemId)`: Cancel and refund

#### Funding & Rewards
- `fundPollSurvey(itemId)`: Add funds to reward pool
- `claimReward(itemId)`: Claim reward as a responder

## Security Features

- **ReentrancyGuard**: Protection against reentrancy attacks
- **Ownable**: Owner access control for administrative functions
- **Input Validation**: Comprehensive checks on all inputs
- **Duplicate Prevention**: Users cannot respond multiple times
- **Secure Transfers**: Safe ETH transfers with failure handling

## Development

### Project Structure
```
vepulse-contract/
├── contracts/
│   └── Vepulse.sol          # Main contract
├── scripts/
│   └── deploy.js            # Deployment script
├── test/
│   └── Vepulse.test.js      # Test suite
├── hardhat.config.js        # Hardhat configuration
├── package.json             # Dependencies
└── README.md               # This file
```

### Network Configuration

The project is configured for VeChain networks:
- **Testnet**: https://testnet.vechain.org
- **Mainnet**: https://mainnet.vechain.org

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
