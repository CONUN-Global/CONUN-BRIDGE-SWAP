// SPDX-License-Identifier: MIT


pragma solidity 0.8.2;


contract BridgeTypes {

    enum Types  {DEPOSIT, WITHDRAW}

    struct BridgeStorage {
        address user;       // user address
        uint256 amount;     // amount
        Types action;       // deposit/withdraw
    }

    struct UserInfo {
        uint256 rewardDebt;
        uint256 lastBlock;
    }

}