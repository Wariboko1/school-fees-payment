// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MockV3Aggregator} from "./MockV3Aggregator.sol";

library PriceConverter {
    function getPrice(
        MockV3Aggregator priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer) * 1e10; // Convert to 18 decimals
    }

    function getConversionRate(
        uint256 ethAmount,
        MockV3Aggregator priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
