

contract Milestones {
    modifier onlyRecipient { if (msg.sender !=  recipient) throw; _; }
    modifier onlyDonor { if (msg.sender != donor) throw; _; }
    modifier onlyArbitrator { if (msg.sender != arbitrator) throw; _; }
    modifier onlyAnyPlayer {
        if ((msg.sender != recipient) &&
            (msg.sender != donor) &&
            (msg.sender != arbitrator))
            throw;
        _;
    }
    modifier campaigNotCancelled {
        if (campaigCancelled) throw;
        _;
    }

    address public recipient;
    address public donor;
    address public arbitrator;

    Vault public vault;

    enum MilestoneStatus { PendingApproval, NotDone, Done, Approved, Paid, Cancelled }

    struct Milestone {
        string description;
        string url;
        uint amount;
        uint minDoneDate;
        uint maxDoneDate;
        uint reviewTime;
        address payDestination;
        bytes payData;

        MilestoneStatus status;
        uint doneTime;
        uint approveTime;
    }

    Milestone[] public milestones;
    function getNumberMilestones() constant return (uint) {
        return milestones.length;
    }

    bool campaigCancelled;


////////////
// Creation and modification of Milestones
////////////


    function proposeMilestonAddition(
        string _description,
        string _url,
        uint _amount,
        address _payDestination,
        bytes _payData,
        uint _minDoneDate;
        uint _maxDoneDate;
        uint _approveTime;
    ) onlyRecipient {
        Milestone milestone = milestones[milestones.length ++];
        milestone.description = _description;
        milestone.url = _url;
        milestone.amount = _amount;
        milestone.minDoneDate = _minDoneDate;
        milestone.maxDoneDate = _maxDoneDate;
        milestone.reviewTime = _reviewTime;
        mailstone.payDestination = _payDestination;
        mailstone.payData = _payData;

        milestone.status = PendingApproval;
    }

    function cancelProposaMilestoneAddition(uint _idMilestone) onlyRecipient campaigNotCancelled {
        milestone.status = Cancelled;
    }

    function approveMilestoneAddition(uint _idMilestone) onlyDonor campaigNotCancelled {
        milestone.status = NotDone;
    }

    function cancelMilestone(uint _idMilestone) onlyAnyPlayer campaigNotCancelled {
        if  ((milestone.status != PendingApproval) &&
             (milestone.status != NotDone) &&
             (milestone.status != Done))
            throw;

        milestone.status = Cancelled;
    }

    function milestoneCompleted(uint _idMilestone) onlyRecipient campaigNotCancelled {

    }


    function collectMilestone(uint _idMilestone) onlyRecipient campaigNotCancelled {
        if  ((milestone.status == Done) &&
             (milestone.doneTime + mailstone.reviewTime < now))
        {
            milestone.status == Approved;
            milestone.approveTime = now;
        }

        if (milestone.status != Approved) throw;

        milestone.status = Paid;
        vault.preparePayment(milestone.payDestination, mailstone.value, mailstone.payData, 0);
    }


    function approveMilestone(uint _idMilestone) onlyDonor campaigNotCancelled {
        if (milestone.status != Done) throw;

//        milestone.status == Approved;
        milestone.approveTime = now;

        milestone.status = Paid;
        vault.preparePayment(milestone.payDestination, mailstone.value, mailstone.payData, 0);
    }

    function rejectMilestone(uint _idMilestone) onlyDonor campaigNotCancelled {
        if (milestone.status != Done) throw;

        mailstone.status = NotDone;
    }


    function forceApproveMileston(uint _idMilestone) onlyArbitrator campaigNotCancelled {
        mailstone.status = Paid;
        vault.preparePayment(milestone.payDestination, mailstone.value, mailstone.payData, 0);
    }

    function cancelCampaign() onlyArbitrator campaigNotCancelled {
        campaigCancelled = true;
    }
}
