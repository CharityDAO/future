pragma solidity ^0.4.4;

contract Owned {
    /// Allows only the owner to call a function
    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    address public owner;

    function Owned() { owner = msg.sender;}



    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


// Rename the token. Possible names
// FlakyToken
// HierachableToken
// ClonableToken
// ForkToken
// MagikToken
// SplitableToken
// MutableToken

contract SSToken is Owned {

    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = 'H0.1';       //human 0.1 standard. Just an arbitrary versioning scheme.

    struct  Checkpoint {
        // snapshot when starts to take effect this assignation
        uint fromBlock;
        // balance assigned to token holder from this snapshot
        uint value;
    }

    SSToken parentToken;
    uint parentSnapShotBlock;
    mapping (address => Checkpoint[]) balances;
    mapping (address => mapping (address => uint256)) allowed;
    Checkpoint[] totalSupplyHistory;
    bool public isConstant;

    SSTokenFactory tokenFactory;

////////////////
// Constructor
////////////////

    function SSToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _isConstant
        ) {
        tokenFactory = SSTokenFactory(_tokenFactory);
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                              // Set the symbol for display purposes
        parentToken = SSToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        isConstant = _isConstant;
    }


////////////////
// ERC20 Interface
////////////////

    function transfer(address _to, uint256 _value) returns (bool success) {

        return doTransfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

        if (isConstant) throw;
        if ((msg.sender != owner) && (allowed[_from][msg.sender] < _value)) return false;
        doTransfer(_from, _to, _value);
    }

    function doTransfer(address _from, address _to, uint _value) internal returns(bool) {

           if (_value == 0) {
               return true;
           }

           // Do not allow transfer to this
           if ((_to == 0) || (_to == address(this))) throw;

           // Remove _from votes
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _value) {
               return false;
           }

           updateValueAtNow(balances[_from], previousBalanceFrom - _value);

           var previousBalanceTo = balanceOfAt(_to, block.number);
           updateValueAtNow(balances[_to], previousBalanceTo + _value);

           Transfer(_from, _to, _value);

           return true;
    }


    function balanceOf(address _owner) constant returns (uint256 balance) {
        return getValueAt(balances[_owner], block.number);
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if (isConstant) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        if (isConstant) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    function totalSupply() returns (uint) {
        return getValueAt(totalSupplyHistory,block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    function balanceOfAt(address _holder, uint _blockNumber) constant returns (uint) {
        return getValueAt( balances[_holder], _blockNumber);
    }

    function totalSupplyAt(uint _blockNumber) constant returns(uint) {
        return getValueAt( totalSupplyHistory, _blockNumber);
    }

////////////////
// Create a child token from an snapshot of this token at a given block
////////////////

    function createChildToken(string _childTokenName, uint8 _childDecimalUnits, string _childTokenSymbol, bool _isConstant, uint _snapshotBlock) {
        if (_snapshotBlock > block.number) _snapshotBlock = block.number;
        SSToken childToken = tokenFactory.createChildToken(this, _snapshotBlock, _childTokenName, _childDecimalUnits, _childTokenSymbol, _isConstant);
        NewChildToken(_snapshotBlock, childToken);
    }


////////////////
// Generate and destroy tokens
////////////////

    function generateTokens(address _dest, uint _value) onlyOwner {
        if (isConstant) throw;
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _value);
        var previousBalanceTo = balanceOf(_dest);
        updateValueAtNow(balances[_dest], previousBalanceTo + _value);
        Transfer(0, _dest, _value);
    }

    function destroyTokens(address _from, uint _value) onlyOwner {
        if (isConstant) throw;
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
        if (curTotalSupply < _value) throw;
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _value);
        var previousBalanceFrom = balanceOf(_from);
        if (previousBalanceFrom < _value) throw;
        updateValueAtNow(balances[_from], previousBalanceFrom + _value);
        Transfer(_from, 0, _value);
    }


////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;
        if (_block < checkpoints[0].fromBlock) return 0;
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal  {
           if ((checkpoints.length == 0) || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  block.number;
               newCheckPoint.value = _value;
           } else {
               Checkpoint oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = _value;
           }
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NewChildToken(uint _snapshotBlock, address _childToken);

}

contract SSTokenFactory {
    function createChildToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _isConstant
    ) returns (SSToken) {
        SSToken newToken = new SSToken(this, _parentToken, _snapshotBlock, _tokenName, _decimalUnits, _tokenSymbol, _isConstant);
        return newToken;
    }
}
