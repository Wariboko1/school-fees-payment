// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";
import {Faucet} from "../src/Faucet.sol";

contract DeployFaucet is Script {
    function run() external returns (MyToken, Faucet) {
        uint256 dripAmount = 100 * 10 ** 18;
        vm.startBroadcast();
        MyToken token = new MyToken();
        Faucet faucet = new Faucet(address(token), dripAmount);
        token.transfer(address(faucet), 10_000 * 10 ** 18);
        vm.stopBroadcast();
        return(token, faucet);
    }
}