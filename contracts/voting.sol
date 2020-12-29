// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegation.
contract Ballot {

    struct Voter {
        // accumulated by delegation
        uint weight;

        // if true, Voter already voted
        bool voted;

        // person delegated to
        address delegate;

        // index of the voted proposal
        uint vote;
    }

    struct Proposal {
        bytes32 name;
        uint voteCount;
    }

    address public chairperson;

    // state variable that stores a Voter struct for each possible address
    mapping(address => Voter) public voters;

    // dynamically-sized array
    Proposal[] public proposals;

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // create a new proposal for each name provided, adding to end of array
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Give `voter` the right to vote on this ballot
    // May only be called by `chairperson`
    function giveRightToVote(address[] calldata voters_) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );

        for (uint i = 0; i < voters_.length; i++) {
            require(
                !voters[voters_[i]].voted,
                "Voter already voted"
            );
            require(voters[voters_[i]].weight == 0);
            voters[voters_[i]].weight = 1;
        }
    }

    /// Delegate vote to voter `to`.
    function delegate(address to) public {
        // assign reference
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is not allowed");

        // If `to` is delegated, walk up the delegation tree to find a non-delegated voter.
        // These loops are dangerous; may get stuck completely.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // ensure no delegation loop exists
            require(to != msg.sender, "Delegation loop is not allowed");
        }

        // Modifies `voters[msg.sender]` since `sender` is a reference
        sender.voted = true;
        sender.delegate = to;
        
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // delegate already voted, add to number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // delegate did not vote yet, add to her weight
            delegate_.weight += sender.weight;
        }
    }

    /// Cast your vote (including delegated votes) to provided proposal
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote");
        require(!sender.voted, "You already voted.");

        sender.voted = true;
        sender.vote = proposal;

        // Automatically throws and reverts all changes if `proposal` is out of range
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev computes the winning proposal, accounting for all previous votes
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Returns the name of the winner using the index of the winner from winningProposal()
    function winnerName() public view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }

}
