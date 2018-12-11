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
}

contract Splitter is Owned {
    address public alice;
    address payable public bob;
    uint public bobBalance;
    address payable public carol;
    uint public carolBalance;

    event LogAliceAddressChanged(address indexed previousAlice, address newAlice);
    event LogBobAddressChanged(address indexed previousBob, address newBob);
    event LogCarolAddressChanged(address indexed previousCarol, address newCarol);
    event LogEtherSplit(address indexed payer, uint amount);
    event LogWithdrawal(address indexed payee, uint amount);

    constructor() public {

    }

    function canChange(address toChange) public view returns (bool) {
        return (msg.sender == toChange) || (msg.sender == super.getOwner());
    }

    function setAlice(address newAddress) public {
        require(canChange(alice));
        emit LogAliceAddressChanged(alice, newAddress);
        alice = newAddress;
    }

    function setBob(address payable newAddress) public {
        require(canChange(bob));
        emit LogBobAddressChanged(bob, newAddress);
        bob = newAddress;
    }

    function setCarol(address payable newAddress) public {
        require(canChange(carol));
        emit LogCarolAddressChanged(carol, newAddress);
        carol = newAddress;
    }

    function split() public payable {
        require(msg.sender == alice);
        require(msg.value > 0);

        emit LogEtherSplit(msg.sender, msg.value);
        uint splitAmount = msg.value >> 1; // divide by 2, bitwise

        bobBalance += splitAmount;
        assert(bobBalance >= splitAmount);

        carolBalance += (splitAmount + (msg.value & uint(1))); // give carol the extra wei if there is a remainder
        assert(carolBalance >= splitAmount);
    }

    function withdraw() external {
        uint amount;

        if (msg.sender == bob) {
            amount = bobBalance;
            bobBalance = 0;
        } else if (msg.sender == carol) {
            amount = carolBalance;
            carolBalance = 0;
        } else if (msg.sender == super.getOwner()) {
            // owner will withdraw all remaining contract funds
            amount = address(this).balance;
            bobBalance = 0;
            carolBalance = 0;
        } else revert();

        emit LogWithdrawal(msg.sender, amount);
        msg.sender.transfer(amount);
    }
}
