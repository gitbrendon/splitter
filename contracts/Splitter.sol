pragma solidity 0.5;

contract Owned {
    address private owner;

    event LogOwnerChanged(address indexed previousOwner, address newOwner);

    constructor() public {
        owner = msg.sender;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        emit LogOwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Pausable is Owned {
    bool private isRunning;

    event LogContractPaused(address sender);
    event LogContractResumed(address sender);

    constructor() public {
        isRunning = true;
    }

    modifier onlyIfRunning() {
        require(isRunning);
        _;
    }

    function pauseContract() public onlyOwner {
        isRunning = false;
        emit LogContractPaused(msg.sender);
    }

    function resumeContract() public onlyOwner {
        isRunning = true;
        emit LogContractResumed(msg.sender);
    }
}

contract Splitter is Pausable {
    struct Recipient {
        uint balance;
        uint index;
    }
    address[] private recipientList;
    mapping(address => Recipient) recipientStructs;

    event LogEtherSplit(address indexed payer, uint amount, address recipientA, address recipientB);
    event LogRemainderReturned(address indexed payer);
    event LogWithdrawal(address indexed recipient, uint amount);
    event LogNewRecipient(address indexed recipient, uint balance, uint index);
    event LogUpdatedRecipient(address indexed recipient, uint balance, uint index);

    function isRecipient(address a) public view returns (bool isIndeed) {
        if (recipientList.length == 0) return false;

        return (recipientList[recipientStructs[a].index] == a);
    }

    function insertRecipient(address a, uint _balance) private returns (uint index) {
        require(!isRecipient(a));
        recipientStructs[a].balance = _balance;
        recipientStructs[a].index = recipientList.push(a) - 1;
        emit LogNewRecipient(a, _balance, recipientStructs[a].index);
        return recipientList.length - 1;
    }

    function updateRecipientBalance(address a, uint newBalance) private returns (bool success) {
        require(isRecipient(a));
        recipientStructs[a].balance = newBalance;
        emit LogUpdatedRecipient(a, newBalance, recipientStructs[a].index);
        return true;
    }

    function getRecipient(address a) public view returns (uint balance, uint index) {
        require(isRecipient(a));
        return (recipientStructs[a].balance, recipientStructs[a].index);
    }

    function getRecipientCount() public view returns (uint count) {
        return recipientList.length;
    }

    function getRecipientAtIndex(uint index) public view returns (address a) {
        return recipientList[index];
    }

    function deposit(address a, uint amount) private returns (bool success) {
        if (!isRecipient(a)) {
            // create new account if doesn't exist
            insertRecipient(a, amount);
        } else {
            updateRecipientBalance(a, recipientStructs[a].balance + amount);
            assert(recipientStructs[a].balance >= amount); // check for overflow
        }
        return true;
    }

    function split(address a, address b) public onlyIfRunning payable {
        require(msg.value > 0);

        emit LogEtherSplit(msg.sender, msg.value, a, b);
        uint splitAmount = msg.value >> 1; // divide by 2, bitwise
        if (msg.value % 2 == 1) {
            msg.sender.transfer(1); // return extra wei if tx value was odd
            emit LogRemainderReturned(msg.sender);
        }

        deposit(a, splitAmount);
        deposit(b, splitAmount);
    }

    function withdraw() public onlyIfRunning {
        require(isRecipient(msg.sender));
        uint amount = recipientStructs[msg.sender].balance;
        updateRecipientBalance(msg.sender, 0);
        msg.sender.transfer(amount);
        emit LogWithdrawal(msg.sender, amount);
    }
}
