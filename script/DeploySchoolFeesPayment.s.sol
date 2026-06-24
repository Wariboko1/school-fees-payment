// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {SchoolFeesPayment} from "../src/SchoolFeesPayment.sol";

contract DeploySchoolFeesPayment is Script {
    function run() external {
        vm.startBroadcast();
        new SchoolFeesPayment();
        vm.stopBroadcast();
    }
}
