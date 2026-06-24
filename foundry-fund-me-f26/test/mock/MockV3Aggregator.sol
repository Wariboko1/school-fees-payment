// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MockV3Aggregator is AggregatorV3Interface {
    uint8 public decimals;
    uint256 public version;
    uint256 public constant override version = 4; // sometimes needed

    int256 private s_answer;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        s_answer = _initialAnswer;
    }

    function updateAnswer(int256 _answer) public {
        s_answer = _answer;
    }

    function latestRoundData()
        public
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, s_answer, 0, 0, 0);
    }

    // Stub other functions
    function getRoundData(
        uint80
    )
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return latestRoundData();
    }

    function description() external pure override returns (string memory) {
        return "v0.8/tests/MockV3Aggregator.sol";
    }
}
