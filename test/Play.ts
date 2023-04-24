import { ethers } from "hardhat";
import { expect } from "chai";

const prime = 17;
const fairnessFactor = 10;

describe("Play", function () {
    async function deployPlayFixtures() {
        const [owner, otherAccounts] = await ethers.getSigners();

        // deploy Random library
        const Random = await ethers.getContractFactory("Random");
        const random = await Random.deploy();

        const Play = await ethers.getContractFactory("Play", {
            libraries:{
                Random: random.address
            }
        });
        const play = await Play.deploy({value : ethers.utils.parseEther("0.1")});

        // get deployment used gas in wei
        const tx = await play.deployTransaction.wait();
        const gasUsed = tx.gasUsed;

        return { play, owner, otherAccounts, gasUsed };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { play, owner } = await deployPlayFixtures();
            expect(await play.owner()).to.equal(owner.address);
        });

        it("Should have balance of 0.1 ether]", async function () {
            const { play, gasUsed } = await deployPlayFixtures();
            const balance = await ethers.provider.getBalance(play.address);
            expect(balance).to.equal(ethers.utils.parseEther("0.1"));
        });
    });


    describe("Randomness", function () {
        it("Should return a random number", async function () {
            const { play } = await deployPlayFixtures();
            await play.getTestRandom({value : ethers.utils.parseEther("0.001")});
        
            // check the latest event
            const event = await play.queryFilter(play.filters["randomNumberLog(address,uint256)"]());
            const latestEvent = event[event.length - 1];
            

            expect(latestEvent.args[1]).to.be.greaterThan(-1);
            expect(latestEvent.args[1]).to.be.lessThan(prime);
        });
        it("Should 100 random numbers following the same pattern", async function () {
            const {play} = await deployPlayFixtures();
            const guesses = [];
            for (let i = 0; i < 100; i++) {
                await play.getTestRandom({value : ethers.utils.parseEther("0.001")});
                const event = await play.queryFilter(play.filters["randomNumberLog(address,uint256)"]());
                const latestEvent = event[event.length - 1];
                guesses.push(latestEvent.args[1]);
            }

            const counts: Map<number, number> = new Map();
            for (let i = 0; i < 100; i++) {
                const guess = Number(guesses[i]);
                if (counts.has(guess)) {
                    counts.set(guess, counts.get(guess)! + 1);
                } else {
                    counts.set(guess, 1);
                }
            }

            const max = Math.max(...counts.values());
            const min = Math.min(...counts.values());

            expect(max - min).to.be.lessThan(fairnessFactor);
        });     
    });
});