pragma solidity ^0.8.2;

abstract contract BridgeTypes {

    enum Type {ERC20, LP}

    //Lock storage record
    struct  LockStorageRecord {
        Type ltype;
        address token;
        uint256 amount;
        uint unlockFrom;
        address to;
    }
}
