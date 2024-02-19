// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

/// @title Ether Deck Mk2 Registry
/// @author jtriley.eth
/// @notice a reasonably optimized, invite only registry for Ether Deck Mk2
contract DeckRegistry {
    /// @notice logged on deck registration
    /// @param deployer the deployer
    /// @param deck the deck
    event Registered(address indexed deployer, address indexed deck);

    /// @notice mapping from deck to deployer
    mapping(address => address) public deployer;

    constructor(address deck) {
        assembly {
            mstore(0x00, deck)

            sstore(keccak256(0x00, 0x40), deck)

            log3(0x00, 0x00, 0x0a31ee9d46a828884b81003c8498156ea6aa15b9b54bdd0ef0b533d9eba57e55, deck, deck)
        }
    }

    /// @notice deploys and registers as deck
    /// @dev directives:
    ///      01. store caller in memory
    ///      02. load caller's deployer from storage, check if nonzero; cache as success
    ///      03. store initcode in memory (lines 38:73)
    ///      04. store runner in memory at the end of initcode, padded to 32 bytes
    ///      05. deploy deck with create2; cache as deck
    ///      06. check if deck is nonzero; compose success
    ///      07. store deck in memory
    ///      08. store caller at `deployer[deck]` in storage
    ///      09. log deck registration
    ///      10. if success, return deck
    ///      11. else, revert
    /// @dev only decks deployed by this factory may deploy and register other decks
    /// @param runner the new deck's runner
    /// @return deck the new deck
    function deploy(address runner) external returns (address) {
        assembly {
            mstore(0x00, caller())

            let success := iszero(iszero(sload(keccak256(0x00, 0x40))))

            mstore(0x0040, 0x60803461006157601f61046338819003918201601f1916830191600160016040)
            mstore(0x0060, 0x1b03831184841017610065578084926020946040528339810103126100615751)
            mstore(0x0080, 0x6001600160a01b0381168103610061576001556040516103e9908161007a8239)
            mstore(0x00a0, 0xf35b5f80fd5b634e487b7160e01b5f52604160045260245ffdfe608060405260)
            mstore(0x00c0, 0x04361015610015575b3661038657005b5f3560e01c80637a8ca6151461007457)
            mstore(0x00e0, 0x8063a3d6bde91461006f578063b0e45f281461006a578063c08eaf2814610065)
            mstore(0x0100, 0x578063d36322cd146100605763fba34ed10361000e57610346565b610284565b)
            mstore(0x0120, 0x61021f565b610158565b6100b4565b3461009a575f36600319011261009a5760)
            mstore(0x0140, 0x01546001600160a01b03166080908152602090f35b5f80fd5b60043590600160)
            mstore(0x0160, 0x0160a01b038216820361009a57565b604036600319011261009a576100c86100)
            mstore(0x0180, 0x9e565b6024359067ffffffffffffffff9081831161009a573660238401121561)
            mstore(0x01a0, 0x009a57826004013591821161009a57366024838501011161009a57815f809392)
            mstore(0x01c0, 0x8193602460015433149701833734905af1163d5f803e610123573d5ffd5b3d5f)
            mstore(0x01e0, 0xf35b9181601f8401121561009a5782359167ffffffffffffffff831161009a57)
            mstore(0x0200, 0x6020808501948460051b01011161009a57565b3461009a576040806003193601)
            mstore(0x0220, 0x1261009a5767ffffffffffffffff9060043582811161009a5761018c90369060)
            mstore(0x0240, 0x0401610127565b91909260243590811161009a576101a7903690600401610127)
            mstore(0x0260, 0x565b6001949194543314908414161561009a5760059290921b8201915b828103)
            mstore(0x0280, 0x6101cb57005b8035843590805f5281845f20557f2c0b629fc2b386c229783b88)
            mstore(0x02a0, 0xb245e8730c1397b78e4dd4a43cd7aafdf1b39f125f80a3602093840193016101)
            mstore(0x02c0, 0xc2565b600435906001600160e01b03198216820361009a57565b3461009a5760)
            mstore(0x02e0, 0x4036600319011261009a57610238610208565b602435906001600160a01b0382)
            mstore(0x0300, 0x16820361009a57600154330361009a57805f528160405f20557f2c0b629fc2b3)
            mstore(0x0320, 0x86c229783b88b245e8730c1397b78e4dd4a43cd7aafdf1b39f125f80a3005b60)
            mstore(0x0340, 0x6036600319011261009a5767ffffffffffffffff60043581811161009a576102)
            mstore(0x0360, 0xb1903690600401610127565b919060243582811161009a576102cb9036906004)
            mstore(0x0380, 0x01610127565b909260443590811161009a576102e89092919236906004016101)
            mstore(0x03a0, 0x27565b919094600154331482959487938360051b0194831492141616945b8285)
            mstore(0x03c0, 0x036103155785610313575f80fd5b005b9091929394823582019081359182915f)
            mstore(0x03e0, 0x806020958695869586018337818b358d355af116970195019392019061030356)
            mstore(0x0400, 0x5b3461009a57602036600319011261009a576001600160e01b03196103686102)
            mstore(0x0420, 0x08565b165f525f602052602060018060a01b0360405f205416604051908152f3)
            mstore(0x0440, 0x5b63ffffffff60e01b5f35165f5260405f2054365f80375f803681845af49015)
            mstore(0x0460, 0x15163d5f803e610123573d5ffdfea264697066735822122026c9b2fdbff4c30a)
            mstore(0x0480, 0x0aa01ed802be4954eb8fa1cd8297bae13a082ff9dc5b70b164736f6c63430008)
            mstore(0x04a0, 0x1800330000000000000000000000000000000000000000000000000000000000)

            mstore(0x04a3, runner)

            let deck := create2(0x00, 0x40, 0x0483, 0x00)

            success := and(success, iszero(iszero(deck)))

            mstore(0x00, deck)

            sstore(keccak256(0x00, 0x40), caller())

            log3(0x00, 0x00, 0x0a31ee9d46a828884b81003c8498156ea6aa15b9b54bdd0ef0b533d9eba57e55, caller(), deck)

            if success { return(0x00, 0x20) }

            revert(0x00, 0x00)
        }
    }
}
