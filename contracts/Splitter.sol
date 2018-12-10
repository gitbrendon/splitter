pragma solidity 0.5;

contract Owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
}

contract Splitter is Owned {
    address public alice;
    address payable public bob;
    address payable public carol;
    address private NULL_ADDRESS;

    event LogAliceAddressChanged(address indexed previousAlice, address newAlice);
    event LogBobAddressChanged(address indexed previousBob, address newBob);
    event LogCarolAddressChanged(address indexed previousCarol, address newCarol);
    event LogEtherSplit(uint amount);

    constructor() public payable {
        
    }

    function canChange(address toChange) private view returns (bool) {
        return (msg.sender == toChange) || (msg.sender == owner);
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
        require(bob != NULL_ADDRESS);
        require(carol != NULL_ADDRESS);
        require(msg.value > 0);
        require(address(this).balance >= msg.value);

        emit LogEtherSplit(msg.value);
        bob.transfer(msg.value / 2);
        carol.transfer(msg.value / 2);
    }
}
