
pragma solidity ^0.8.2;


contract BridgeTypes {

    enum Types  {DEPOSIT, WITHDRAW}

    struct BridgeStorage {
        address user;
        uint256 amount;
        Types action;
    }

}