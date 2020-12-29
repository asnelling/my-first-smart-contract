import {expect, use} from 'chai';
import {Contract} from 'ethers';
import {deployContract, MockProvider, solidity} from 'ethereum-waffle';
import Ballot from '../build/Ballot.json';

use(solidity);

describe('Ballot', () => {
    const [wallet, voter1, voter2] = new MockProvider().getWallets();
    let contract: Contract;

    beforeEach(async () => {
        const proposalNames = 
        contract = await deployContract(wallet, Ballot, [[
            // prop1
            "0x70726f7031000000000000000000000000000000000000000000000000000000",

            // prop2
            "0x70726f7032000000000000000000000000000000000000000000000000000000"
        ]]);
    });

    it('Assigns initial proposal vote counts and names', async () => {
        expect((await contract.proposals(0)).name).to.equal("0x70726f7031000000000000000000000000000000000000000000000000000000");
        expect((await contract.proposals(0)).voteCount).to.equal(0);
        expect((await contract.proposals(1)).name).to.equal("0x70726f7032000000000000000000000000000000000000000000000000000000");
        expect((await contract.proposals(1)).voteCount).to.equal(0);
    });

    it('giveRightToVote sets weight', async () => {
        await contract.giveRightToVote([voter1.address]);
        expect((await contract.voters(voter1.address)).weight).to.equal(1);
    });

    it('delegate sets weight', async () => {
        await contract.giveRightToVote([voter1.address, voter2.address]);
        const voter1contract = contract.connect(voter1);
        await voter1contract.delegate(voter2.address);
        expect((await contract.voters(voter2.address)).weight).to.equal(2);
    });

    it('vote increases vote count', async () => {
        await contract.giveRightToVote([voter1.address]);
        const voter1contract = contract.connect(voter1);
        await voter1contract.vote(0);
        expect((await contract.proposals(0)).voteCount).to.equal(1);
    });

    it('computes winning proposal with highest vote count', async () => {
        await contract.giveRightToVote([voter1.address]);
        const voter1contract = contract.connect(voter1);
        await voter1contract.vote(1);
        expect(await contract.winningProposal()).to.equal(1);
    });

    it('computes winning proposal name with highest vote count', async () => {
        await contract.giveRightToVote([voter1.address]);
        const voter1contract = contract.connect(voter1);
        await voter1contract.vote(1);
        expect(await contract.winnerName()).to.equal("0x70726f7032000000000000000000000000000000000000000000000000000000");
    });
});
