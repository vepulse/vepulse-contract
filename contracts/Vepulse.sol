// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Vepulse
 * @dev Smart contract for creating and managing polls, surveys, and projects on VeChain
 */
contract Vepulse is Ownable, ReentrancyGuard {

    enum ItemType { POLL, SURVEY }
    enum ItemStatus { ACTIVE, ENDED, CANCELLED }

    struct Project {
        uint256 id;
        string name;
        string description;
        address creator;
        uint256 createdAt;
        bool active;
        uint256[] pollIds;
        uint256[] surveyIds;
    }

    struct PollSurvey {
        uint256 id;
        ItemType itemType;
        string title;
        string description;
        address creator;
        uint256 projectId; // 0 if not part of a project
        uint256 createdAt;
        uint256 endTime;
        ItemStatus status;
        uint256 fundingPool;
        uint256 totalResponses;
        mapping(address => bool) hasResponded;
        address[] responders;
    }

    // State variables
    uint256 private nextProjectId = 1;
    uint256 private nextPollSurveyId = 1;

    mapping(uint256 => Project) public projects;
    mapping(uint256 => PollSurvey) private pollsSurveys;
    mapping(address => uint256[]) private userProjects;
    mapping(address => uint256[]) private userPollsSurveys;

    // Events
    event ProjectCreated(uint256 indexed projectId, string name, address indexed creator);
    event ProjectUpdated(uint256 indexed projectId, string name);
    event ProjectDeactivated(uint256 indexed projectId);

    event PollCreated(uint256 indexed pollId, string title, address indexed creator, uint256 indexed projectId);
    event SurveyCreated(uint256 indexed surveyId, string title, address indexed creator, uint256 indexed projectId);
    event PollSurveyFunded(uint256 indexed itemId, uint256 amount, address indexed funder);
    event ResponseSubmitted(uint256 indexed itemId, address indexed responder);
    event PollSurveyEnded(uint256 indexed itemId);
    event PollSurveyCancelled(uint256 indexed itemId);
    event RewardClaimed(uint256 indexed itemId, address indexed responder, uint256 amount);

    constructor() Ownable(msg.sender) {}

    // Project Management Functions

    /**
     * @dev Create a new project
     * @param name Name of the project
     * @param description Description of the project
     */
    function createProject(string memory name, string memory description) external returns (uint256) {
        uint256 projectId = nextProjectId++;

        Project storage project = projects[projectId];
        project.id = projectId;
        project.name = name;
        project.description = description;
        project.creator = msg.sender;
        project.createdAt = block.timestamp;
        project.active = true;

        userProjects[msg.sender].push(projectId);

        emit ProjectCreated(projectId, name, msg.sender);
        return projectId;
    }

    /**
     * @dev Update project information
     * @param projectId ID of the project to update
     * @param name New name
     * @param description New description
     */
    function updateProject(uint256 projectId, string memory name, string memory description) external {
        Project storage project = projects[projectId];
        require(project.id != 0, "Project does not exist");
        require(project.creator == msg.sender, "Only creator can update project");
        require(project.active, "Project is not active");

        project.name = name;
        project.description = description;

        emit ProjectUpdated(projectId, name);
    }

    /**
     * @dev Deactivate a project
     * @param projectId ID of the project to deactivate
     */
    function deactivateProject(uint256 projectId) external {
        Project storage project = projects[projectId];
        require(project.id != 0, "Project does not exist");
        require(project.creator == msg.sender, "Only creator can deactivate project");

        project.active = false;

        emit ProjectDeactivated(projectId);
    }

    // Poll and Survey Management Functions

    /**
     * @dev Create a new poll
     * @param title Title of the poll
     * @param description Description of the poll
     * @param duration Duration in seconds
     * @param projectId Optional project ID (0 for standalone)
     */
    function createPoll(
        string memory title,
        string memory description,
        uint256 duration,
        uint256 projectId
    ) external returns (uint256) {
        return _createPollSurvey(ItemType.POLL, title, description, duration, projectId);
    }

    /**
     * @dev Create a new survey
     * @param title Title of the survey
     * @param description Description of the survey
     * @param duration Duration in seconds
     * @param projectId Optional project ID (0 for standalone)
     */
    function createSurvey(
        string memory title,
        string memory description,
        uint256 duration,
        uint256 projectId
    ) external returns (uint256) {
        return _createPollSurvey(ItemType.SURVEY, title, description, duration, projectId);
    }

    /**
     * @dev Internal function to create poll or survey
     */
    function _createPollSurvey(
        ItemType itemType,
        string memory title,
        string memory description,
        uint256 duration,
        uint256 projectId
    ) private returns (uint256) {
        require(duration > 0, "Duration must be greater than 0");

        if (projectId != 0) {
            Project storage project = projects[projectId];
            require(project.id != 0, "Project does not exist");
            require(project.active, "Project is not active");
        }

        uint256 itemId = nextPollSurveyId++;

        PollSurvey storage item = pollsSurveys[itemId];
        item.id = itemId;
        item.itemType = itemType;
        item.title = title;
        item.description = description;
        item.creator = msg.sender;
        item.projectId = projectId;
        item.createdAt = block.timestamp;
        item.endTime = block.timestamp + duration;
        item.status = ItemStatus.ACTIVE;

        userPollsSurveys[msg.sender].push(itemId);

        if (projectId != 0) {
            if (itemType == ItemType.POLL) {
                projects[projectId].pollIds.push(itemId);
                emit PollCreated(itemId, title, msg.sender, projectId);
            } else {
                projects[projectId].surveyIds.push(itemId);
                emit SurveyCreated(itemId, title, msg.sender, projectId);
            }
        } else {
            if (itemType == ItemType.POLL) {
                emit PollCreated(itemId, title, msg.sender, 0);
            } else {
                emit SurveyCreated(itemId, title, msg.sender, 0);
            }
        }

        return itemId;
    }

    /**
     * @dev Fund a poll or survey
     * @param itemId ID of the poll or survey to fund
     */
    function fundPollSurvey(uint256 itemId) external payable nonReentrant {
        PollSurvey storage item = pollsSurveys[itemId];
        require(item.id != 0, "Poll/Survey does not exist");
        require(msg.value > 0, "Funding amount must be greater than 0");

        item.fundingPool += msg.value;

        emit PollSurveyFunded(itemId, msg.value, msg.sender);
    }

    /**
     * @dev Submit a response to a poll or survey
     * @param itemId ID of the poll or survey
     */
    function submitResponse(uint256 itemId) external {
        PollSurvey storage item = pollsSurveys[itemId];
        require(item.id != 0, "Poll/Survey does not exist");
        require(item.status == ItemStatus.ACTIVE, "Poll/Survey is not active");
        require(block.timestamp < item.endTime, "Poll/Survey has ended");
        require(!item.hasResponded[msg.sender], "Already responded");

        item.hasResponded[msg.sender] = true;
        item.responders.push(msg.sender);
        item.totalResponses++;

        emit ResponseSubmitted(itemId, msg.sender);
    }

    /**
     * @dev End a poll or survey (can be called by creator or automatically after end time)
     * @param itemId ID of the poll or survey
     */
    function endPollSurvey(uint256 itemId) external {
        PollSurvey storage item = pollsSurveys[itemId];
        require(item.id != 0, "Poll/Survey does not exist");
        require(item.status == ItemStatus.ACTIVE, "Poll/Survey is not active");
        require(
            msg.sender == item.creator || block.timestamp >= item.endTime,
            "Only creator can end before end time"
        );

        item.status = ItemStatus.ENDED;

        emit PollSurveyEnded(itemId);
    }

    /**
     * @dev Cancel a poll or survey (only creator, refunds funding)
     * @param itemId ID of the poll or survey
     */
    function cancelPollSurvey(uint256 itemId) external nonReentrant {
        PollSurvey storage item = pollsSurveys[itemId];
        require(item.id != 0, "Poll/Survey does not exist");
        require(item.creator == msg.sender, "Only creator can cancel");
        require(item.status == ItemStatus.ACTIVE, "Poll/Survey is not active");

        item.status = ItemStatus.CANCELLED;

        // Refund funding pool to creator
        if (item.fundingPool > 0) {
            uint256 refundAmount = item.fundingPool;
            item.fundingPool = 0;
            (bool success, ) = payable(item.creator).call{value: refundAmount}("");
            require(success, "Refund failed");
        }

        emit PollSurveyCancelled(itemId);
    }

    /**
     * @dev Claim reward for responding to a poll or survey
     * @param itemId ID of the poll or survey
     */
    function claimReward(uint256 itemId) external nonReentrant {
        PollSurvey storage item = pollsSurveys[itemId];
        require(item.id != 0, "Poll/Survey does not exist");
        require(item.status == ItemStatus.ENDED, "Poll/Survey has not ended");
        require(item.hasResponded[msg.sender], "Did not respond to this poll/survey");
        require(item.fundingPool > 0, "No funds available");
        require(item.totalResponses > 0, "No responses");

        // Calculate equal share for each responder
        uint256 rewardAmount = item.fundingPool / item.totalResponses;
        require(rewardAmount > 0, "Reward amount too small");

        // Mark as claimed by reducing funding pool
        item.fundingPool -= rewardAmount;

        // Transfer reward
        (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
        require(success, "Reward transfer failed");

        emit RewardClaimed(itemId, msg.sender, rewardAmount);
    }

    // View Functions

    /**
     * @dev Get project details
     */
    function getProject(uint256 projectId) external view returns (
        uint256 id,
        string memory name,
        string memory description,
        address creator,
        uint256 createdAt,
        bool active,
        uint256[] memory pollIds,
        uint256[] memory surveyIds
    ) {
        Project storage project = projects[projectId];
        require(project.id != 0, "Project does not exist");

        return (
            project.id,
            project.name,
            project.description,
            project.creator,
            project.createdAt,
            project.active,
            project.pollIds,
            project.surveyIds
        );
    }

    /**
     * @dev Get poll or survey details
     */
    function getPollSurvey(uint256 itemId) external view returns (
        uint256 id,
        ItemType itemType,
        string memory title,
        string memory description,
        address creator,
        uint256 projectId,
        uint256 createdAt,
        uint256 endTime,
        ItemStatus status,
        uint256 fundingPool,
        uint256 totalResponses
    ) {
        PollSurvey storage item = pollsSurveys[itemId];
        require(item.id != 0, "Poll/Survey does not exist");

        return (
            item.id,
            item.itemType,
            item.title,
            item.description,
            item.creator,
            item.projectId,
            item.createdAt,
            item.endTime,
            item.status,
            item.fundingPool,
            item.totalResponses
        );
    }

    /**
     * @dev Check if an address has responded to a poll/survey
     */
    function hasResponded(uint256 itemId, address responder) external view returns (bool) {
        return pollsSurveys[itemId].hasResponded[responder];
    }

    /**
     * @dev Get all responders for a poll/survey
     */
    function getResponders(uint256 itemId) external view returns (address[] memory) {
        PollSurvey storage item = pollsSurveys[itemId];
        require(item.id != 0, "Poll/Survey does not exist");
        return item.responders;
    }

    /**
     * @dev Get projects created by a user
     */
    function getUserProjects(address user) external view returns (uint256[] memory) {
        return userProjects[user];
    }

    /**
     * @dev Get polls/surveys created by a user
     */
    function getUserPollsSurveys(address user) external view returns (uint256[] memory) {
        return userPollsSurveys[user];
    }

    /**
     * @dev Get potential reward for a responder
     */
    function getPotentialReward(uint256 itemId) external view returns (uint256) {
        PollSurvey storage item = pollsSurveys[itemId];
        require(item.id != 0, "Poll/Survey does not exist");

        if (item.totalResponses == 0 || item.fundingPool == 0) {
            return 0;
        }

        return item.fundingPool / item.totalResponses;
    }
}
