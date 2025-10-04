const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Vepulse", function () {
  let vepulse;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const Vepulse = await ethers.getContractFactory("Vepulse");
    vepulse = await Vepulse.deploy();
    await vepulse.waitForDeployment();
  });

  describe("Project Management", function () {
    it("Should create a project", async function () {
      const tx = await vepulse.createProject("Test Project", "A test project");
      await tx.wait();

      const project = await vepulse.getProject(1);
      expect(project.name).to.equal("Test Project");
      expect(project.description).to.equal("A test project");
      expect(project.creator).to.equal(owner.address);
      expect(project.active).to.equal(true);
    });

    it("Should update a project", async function () {
      await vepulse.createProject("Test Project", "A test project");
      await vepulse.updateProject(1, "Updated Project", "Updated description");

      const project = await vepulse.getProject(1);
      expect(project.name).to.equal("Updated Project");
      expect(project.description).to.equal("Updated description");
    });

    it("Should deactivate a project", async function () {
      await vepulse.createProject("Test Project", "A test project");
      await vepulse.deactivateProject(1);

      const project = await vepulse.getProject(1);
      expect(project.active).to.equal(false);
    });
  });

  describe("Poll Management", function () {
    it("Should create a standalone poll", async function () {
      const duration = 86400; // 1 day
      await vepulse.createPoll("Test Poll", "A test poll", duration, 0);

      const poll = await vepulse.getPollSurvey(1);
      expect(poll.title).to.equal("Test Poll");
      expect(poll.itemType).to.equal(0); // POLL
      expect(poll.projectId).to.equal(0);
    });

    it("Should create a poll within a project", async function () {
      await vepulse.createProject("Test Project", "A test project");
      const duration = 86400;
      await vepulse.createPoll("Project Poll", "A poll in a project", duration, 1);

      const poll = await vepulse.getPollSurvey(1);
      expect(poll.projectId).to.equal(1);

      const project = await vepulse.getProject(1);
      expect(project.pollIds.length).to.equal(1);
      expect(project.pollIds[0]).to.equal(1);
    });

    it("Should fund a poll", async function () {
      const duration = 86400;
      await vepulse.createPoll("Test Poll", "A test poll", duration, 0);

      const fundingAmount = ethers.parseEther("1.0");
      await vepulse.fundPollSurvey(1, { value: fundingAmount });

      const poll = await vepulse.getPollSurvey(1);
      expect(poll.fundingPool).to.equal(fundingAmount);
    });

    it("Should allow responding to a poll", async function () {
      const duration = 86400;
      await vepulse.createPoll("Test Poll", "A test poll", duration, 0);

      await vepulse.connect(addr1).submitResponse(1);

      const hasResponded = await vepulse.hasResponded(1, addr1.address);
      expect(hasResponded).to.equal(true);

      const poll = await vepulse.getPollSurvey(1);
      expect(poll.totalResponses).to.equal(1);
    });

    it("Should not allow duplicate responses", async function () {
      const duration = 86400;
      await vepulse.createPoll("Test Poll", "A test poll", duration, 0);

      await vepulse.connect(addr1).submitResponse(1);
      await expect(
        vepulse.connect(addr1).submitResponse(1)
      ).to.be.revertedWith("Already responded");
    });

    it("Should end a poll", async function () {
      const duration = 86400;
      await vepulse.createPoll("Test Poll", "A test poll", duration, 0);

      await vepulse.endPollSurvey(1);

      const poll = await vepulse.getPollSurvey(1);
      expect(poll.status).to.equal(1); // ENDED
    });

    it("Should allow claiming rewards after poll ends", async function () {
      const duration = 86400;
      await vepulse.createPoll("Test Poll", "A test poll", duration, 0);

      // Fund the poll
      const fundingAmount = ethers.parseEther("1.0");
      await vepulse.fundPollSurvey(1, { value: fundingAmount });

      // Submit responses
      await vepulse.connect(addr1).submitResponse(1);
      await vepulse.connect(addr2).submitResponse(1);

      // End the poll
      await vepulse.endPollSurvey(1);

      // Check potential reward
      const potentialReward = await vepulse.getPotentialReward(1);
      expect(potentialReward).to.equal(ethers.parseEther("0.5"));

      // Claim reward
      const balanceBefore = await ethers.provider.getBalance(addr1.address);
      const tx = await vepulse.connect(addr1).claimReward(1);
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * receipt.gasPrice;
      const balanceAfter = await ethers.provider.getBalance(addr1.address);

      expect(balanceAfter).to.be.closeTo(
        balanceBefore + ethers.parseEther("0.5") - gasUsed,
        ethers.parseEther("0.001") // Allow for small rounding errors
      );
    });
  });

  describe("Survey Management", function () {
    it("Should create a survey", async function () {
      const duration = 86400;
      await vepulse.createSurvey("Test Survey", "A test survey", duration, 0);

      const survey = await vepulse.getPollSurvey(1);
      expect(survey.title).to.equal("Test Survey");
      expect(survey.itemType).to.equal(1); // SURVEY
    });

    it("Should create a survey within a project", async function () {
      await vepulse.createProject("Test Project", "A test project");
      const duration = 86400;
      await vepulse.createSurvey("Project Survey", "A survey in a project", duration, 1);

      const survey = await vepulse.getPollSurvey(1);
      expect(survey.projectId).to.equal(1);

      const project = await vepulse.getProject(1);
      expect(project.surveyIds.length).to.equal(1);
      expect(project.surveyIds[0]).to.equal(1);
    });
  });
});
