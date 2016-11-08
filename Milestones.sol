

contract Milestones {

    address public recipient;
    address public donor;
    address public arbitrator;

    enum MilestoneStatus { NotDone, Done_PendingApproval, Paid, Cancelled }

    struct Milestone {
        string description;
        string url;
        uint amount;
        uint minDoneDate;
        uint maxDoneDate;
        uint reviewTime;

        MilestoneStatus status;
        uint terminationTime
        uint paidTime;
    }

    Milestone[] public milestones;
    function getNumberMilestones() constant return (uint)


    function milestoneCompleted(uint _idMilestone) onlyRecipient;


    function collectMilestone(uint _idMilestone) onlyRecipient;


    function approveMilestone(uint _idMilestone) onlyDonor;

    function rejectMilestone(uint _idMilestone) onlyDonor;


    function forceApproveMileston(uint _idMilestone) onlyArbitrator;

    function cancelCampaign() onlyArbitrator;


// Changing Milestone

    function proposeMilestonAddition(
        string _description,
        string _url,
        uint _amount,
        uint _minDoneDate;
        uint _maxDoneDate;
        uint _reviewTime;
    ) onlyRecipient {}

    function cancelProposaMilestoneAddition(uint _idMilestone) onlyRecipient
    function approveMilestonAddition(uint _idMilestone) onlyDonor

    function proposeMilestonRemoval(uint _idMilestone) onlyRecipient
    function cancelMilestoneRemoval(uint _idMilestone) onlyRecipient
    function approveMilestonRemoval(uint _idMilestone) onlyDonor

// Change players

    function setCon



}
