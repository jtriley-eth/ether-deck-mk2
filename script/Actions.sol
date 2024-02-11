// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { EtherDeckMk2 } from "../src/EtherDeckMk2.sol";

import { BribeMod } from "../src/mods/BribeMod.sol";
import { CreatorMod } from "../src/mods/CreatorMod.sol";
import { FlashMod } from "../src/mods/FlashMod.sol";
import { RevokeMod } from "../src/mods/RevokeMod.sol";
import { TransferMod } from "../src/mods/TransferMod.sol";
import { Mod4337 } from "../src/mods/Mod4337.sol";
import { StorageMod } from "../src/mods/StorageMod.sol";
import { TwoStepTransitionMod } from "../src/mods/TwoStepTransitionMod.sol";

function makeDeck() returns (EtherDeckMk2) {
    return new EtherDeckMk2();
}

function linkBribeMod(EtherDeckMk2 deck, address mod) {
    bytes4[] memory selectors = new bytes4[](3);
    selectors[0] = BribeMod.nonce.selector;
    selectors[1] = BribeMod.bribeBuilder.selector;
    selectors[2] = BribeMod.bribeCaller.selector;

    linkMod(deck, selectors, mod);
}

function linkCreatorMod(EtherDeckMk2 deck, address mod) {
    bytes4[] memory selectors = new bytes4[](3);
    selectors[0] = CreatorMod.create.selector;
    selectors[1] = CreatorMod.create2.selector;
    selectors[2] = CreatorMod.compute2.selector;

    linkMod(deck, selectors, mod);
}

// todo

function linkMod(EtherDeckMk2 deck, bytes4[] memory selectors, address mod) {
    address[] memory targets = new address[](selectors.length);
    for (uint256 i = 0; i < selectors.length; i++) {
        targets[i] = mod;
    }

    deck.setDispatchBatch(selectors, targets);
}
