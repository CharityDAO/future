pragma solidity ^0.4.0;

contract Multisig {


    //Position inside the owners array plus one.
    mapping(address => uint) ownerIdx;
    address[] public owners;
    uint required;

    struct Proposal {
        address owner;
        string description;
        address recipient;
        uint value;
        bytes data;

        uint expirationDate;
        mapping (address => bool) accepted;
        bool approved;
        bool terminated;
    }

    Proposal[] proposals;

    modifier onlyOwners { if ( ownerIdx[msg.sender] == 0) throw; _; }
    modifier onlySelf { if ( msg.sender != address(this)) throw; _; }

    function Multisig(address[] _owners, uint _required) {
        owners.length = _owners.length;
        uint i;
        for (i=0; i< _owners.length; i++) {
            owners[i] = _owners[i];
            ownerIdx[ _owners[i] ] = i +1;
        }
        required = _required;
    }

    function newProposal(string _description, address _recipient, uint _value, bytes _data, uint _timeout) onlyOwners returns (uint) {

        uint idProposal = proposals.length ++;
        Proposal proposal = proposals[ idProposal ];
        proposal.description = _description;
        proposal.recipient = _recipient;
        proposal.value = _value;
        proposal.data = _data;
        proposal.expirationDate = now + _timeout;
        proposal.owner = msg.sender;

        ProposalCreated(idProposal);

        confirm(idProposal);

        return (idProposal);
    }

    function confirm(uint _idProposal) onlyOwners {
        Proposal proposal = proposals[ _idProposal ];
        if (proposal.owner == 0) throw;

        if (! proposal.accepted[msg.sender]) {
            proposal.accepted[msg.sender] = true;

            ProposalConfirmed(_idProposal, msg.sender);
        }

        checkProposal(_idProposal);
    }

    function unconfirm(uint _idProposal) onlyOwners {
        Proposal proposal = proposals[ _idProposal ];
        if (proposal.terminated) return;
        if (proposal.expirationDate< now) {
            proposal.terminated = true;
            return;
        }
        proposal.accepted[msg.sender] = false;

        checkProposal(_idProposal);
    }


    function checkProposal(uint _idProposal) internal {
        Proposal proposal = proposals[ _idProposal ];
        if (proposal.terminated) return;
        if (proposal.expirationDate< now) {
            proposal.terminated = true;
            return;
        }
        if (confirmations(_idProposal) >= required) {
            proposal.approved = true;
            proposal.terminated = true;
            if (!proposal.recipient.call.value(proposal.value)(proposal.data)) throw;
            ProposalExecuted(_idProposal);
        }
    }

    function confirmations(uint _idProposal) constant returns (uint) {
        Proposal proposal = proposals[ _idProposal ];
        uint res =0;
        uint i;
        for (i=0; i<owners.length; i++) {
            if (proposal.accepted[ owners[i] ]) res ++;
        }
        return res;
    }

    function numberOfProposals() constant returns (uint) {
        return proposals.length;
    }

    function hasConfirmed(uint _idProposal, address _owner) constant returns (bool) {
        Proposal proposal = proposals[ _idProposal ];
        return proposal.accepted[_owner];
    }

    function addOwner(address _newOwner) onlySelf {
        if (ownerIdx[_newOwner] > 0 ) throw;
        uint idx = owners.length++;
        ownerIdx[_newOwner] = idx +1;
        owners[idx] = _newOwner;
    }

    function removeOwner(address _oldOwner) onlySelf {
        uint idx = ownerIdx[_oldOwner];
        if (idx == 0 ) throw;
        idx --;
        owners[idx] = owners[owners.length -1];
        ownerIdx[ owners[idx]] = idx +1;
        owners[owners.length -1] = 0;
        ownerIdx[ _oldOwner] = 0;
        owners.length --;
    }

    function setRequired(uint newRequired) onlySelf {
        required = newRequired;
    }

    function () payable { }

    event ProposalCreated(uint indexed idProposal);
    event ProposalConfirmed(uint indexed idProposal, address indexed owner);
    event ProposalExecuted(uint indexed idProposal);
}
