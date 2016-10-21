
import "SafeBox.sol";
import "SSToken.sol";

contract ProposalSelector {

    function ProposalSelector() {

    }

    struct Proposal {
        uint creationDate;
        address owner;
        string title;
        bytes32 swarmHash;
        address recipient;
        uint amount;
        bytes data;
        uint closingTime;
        SSToken proposalToken;
        uint deposit;
        uint totalYes;
        uint totalNo;
        bool terminated;
        bool preAccepted;
        bool accepted;
        mapping (address => uint) yesVotes;
        mapping (address => uint) noVotes;
    }

    uint public timeForSupporting = 14 days;
    uint public deposit = 2 ether;
    uint public percentageToAccept = 1000;   // 12.13% -> 1213
    SSToken public token;
    SafeBox public safeBox;


    Proposal[] allProposals;

    function newPreproposal(string _title, bytes32 _swarmHash, address _recipient, uint _amount, bytes _data) payable returns (uint) {
        if (msg.value != deposit) throw;
        uint idProposal = allProposals.length ++;
        Proposal proposal = allProposals[idProposal];

        string proposalName = concat(token.name(), "_", int2str(idProposal));
        string proposalSymbol = concat(token.symbol(), "_", int2str(idProposal));

        proposal.creationDate = now;
        proposal.owner = msg.sender;
        proposal.title = _title;
        proposal.swarmHash = _swarmHash;
        proposal.recipient = _recipient;
        proposal.amount = _amount;
        proposal.data = _data;
        proposal.closingTime = now + timeForSupporting;
        proposal.proposalToken = token.createChildToken(token.nProposals(), childTokenName, token.decimalUnits, childTokenSymbol, false);
        proposal.totalYes = 0;
        proposal.totalNo = 0;
        proposal.terminated = false;
        proposal.preAccepted = false;
        proposal.accepted = false;
        proposal.deposit = deposit;

        return idProposal;
    }


    function vote(uint _idProposal, bool _support) {
        Proposal proposal = allProposals[_idProposal];
        voteAmount(_idProposal, _support, proposal.proposalToken.balanceOf(msg.sender));
    }

    function voteAmount(uint _idProposal, bool _support, uint _amount) {
        if (_amount == 0) return;
        Proposal proposal = allProposals[_idProposal];
        if ( (proposal.creationDate == 0) ||
             (proposal.terminated) ||
             (now > proposal.closingTime) ||
             (token.balanceOf(msg.sender) < _amount))
            throw;

        if (_support) {
            proposal.totalYes += _amount;
            proposal.yesVotes[msg.sender] += _amount;
        } else {
            proposal.totalNo += _amount;
            proposal.noVotes[msg.sender] += _amount;
        }

        if (!proposal.proposalToken.transferFrom(msg.sender, this, _amount)) throw;

        uint p = (proposal.totalYes - proposal.totalNo)*100 / proposal.proposalToken.totalSupply();

        if ((!proposal.preAccepted) && ( p > percentageToAccept )) {
            proposal.preAccepted = true;
            proposal.closingTime = now + timeForSupporting;
        }

    }

    function unvote(uint _idProposal) {
        Proposal proposal = allProposals[_idProposal];

        unvoteAmount(_idProposal, true, proposal.yesVotes[msg.sender]);
        unvoteAmount(_idProposal, false, proposal.noVotes[msg.sender]);
    }

    function unvoteAmount(uint _idProposal, bool _support, uint _amount) {
        if (_amount == 0) return;
        Proposal proposal = allProposals[_idProposal];
        if ( (proposal.creationDate == 0) ||
             (proposal.terminated) ||
             (now > proposal.closingTime))
            throw;


        if (_support) {
            if (proposal.yesVotes[msg.sender] < _amount) throw;
            proposal.totalYes -= _amount;
            proposal.yesVotes[msg.sender] -= _amount;
        } else {
            if (proposal.noVotes[msg.sender] < _amount) throw;
            proposal.totalNo -= _amount;
            proposal.noVotes[msg.sender] -= _amount;
        }

        if (!proposal.proposalToken.transferFrom(this, msg.sender, _amount)) throw;

    }

    function executeProposal(uint _idProposal) {
        Proposal proposal = allProposals[_idPreproposal];
        if ( (proposal.creationDate == 0) ||
             (proposal.terminated) ||
             (now <= proposal.closingTime))
            throw;

        if (!proposal.preAccepted) {
            proposal.terminated = true;
            return;
        }

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.accepted = true;
            proposal.terminated = true;
            if (! safeBox.preparePayment(proposal.recipient, proposal.amount, proposal.data)) throw;
        } else {
            proposal.terminated = true;
        }
    }
}

