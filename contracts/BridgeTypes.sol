
pragma solidity ^0.8.2;


contract BridgeTypes {

    enum Type  {DEPOSIT, WITHDRAW}

    struct BridgeStorage {
        address user;
        uint256 amount;
        Type type;
    }

}