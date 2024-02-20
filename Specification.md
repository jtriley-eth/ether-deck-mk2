## Ether Deck Mk2

## Abstract

The following is a specification for the Ether Deck Mk2 (deck). The deck is a
smart contract account that can run external calls and extend its functionality
with a mutable dispatcher.

## Motivation

Smart contract accounts for individuals are currently limited in selection and
bloated in implementation due to excessive modularity. The minimal functionality
of a smart contract account's core is the ability to make external calls and to
extend its functionality with delegate calls. A reasonable extension to this is
to batch both; allowing an externally owned account (EOA) to make multiple calls
in a single transaction.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 and RFC 8174.

### ABI Specification

The application binary interface used for the deck is Solidity's
[ABI Specification](https://docs.soliditylang.org/en/v0.8.24/abi-spec.html).

### Methods

#### `dispatch`

The `mod` address of a `selector` to `dispatch` if the `selector` does not match
one of the selectors on the core deck.

```yaml
- name: dispatch
  type: function
  stateMutability: view

  inputs:
    - name: selector
      type: bytes4

  outputs:
    - name: mod
      type: uint256
```

#### `runner`

The `runner` address that is authorized to take action on the deck.

The `runner` MAY delegate actions through `mod` addresses.

```yaml
- name: runner
  type: function
  stateMutability: view

  inputs: []

  outputs:
    - name: runner
      type: address
```

#### `run`

Runs a call to a `target` with a `payload` and a `callvalue`.

MAY forward entire `callvalue`.

MAY return `returndata` from `target`.

MUST revert if caller is not [`runner`](#runner).

```yaml
- name: run
  type: function
  stateMutability: payable

  inputs:
    - name: target
      type: address
    - name: payload
      type: bytes
```

#### `runBatch`

Runs an array of calls to `targets` with `payloads` and `values`.

MAY return `returndata` from each `target`.

MUST revert if caller is not [`runner`](#runner).

```yaml
- name: runBatch
  type: function
  stateMutability: payable

  inputs:
    - name: targets
      type: address[]
    - name: values
      type: uint256[]
    - name: payloads
      type: bytes[]

  outputs: []
```

#### `setDispatch`

Writes a `mod` to a given `selector` in [`dispatch`](#dispatch) to be dispatched
if an external call to the deck does not contain a matching selector on the core
deck.

```yaml
- name: setDispatch
  type: function
  stateMutability: nonpayable

  inputs:
    - name: selector
      type: bytes4
    - name: target
      type: address

  outputs: []
```

#### `setDispatchBatch`

Writes a `selectors` array a `targets` array.

```yaml
- name: setDispatchBatch
  type: function
  stateMutability: nonpayable

  inputs:
    - name: selectors
      type: bytes4[]
    - name: targets
      type: address[]

  outputs: []
```

#### `fallback`

The `fallback` loads the mod from the [`dispatch`](#dispatch) for the given
`selector` and delegatecalls to it.

MUST forward all calldata to the `mod`.

SHOULD return the `returndata` from the delegatecall.

MUST revert if the `dispatch` address for the `selector` is zero.

```yaml
- type: fallback
  stateMutability: payable

  inputs: []

  outputs: []
```

### Events

#### `DispatchSet`

Logged when [`setDispatch`](#setdispatch) sets a new address for the
[`dispatch`](#dispatch).

```yaml
- name: DispatchSet
  type: event

  inputs:
    - name: selector
      indexed: true
      type: bytes4
    - name: target
      indexed: true
      type: address
```

### Mods

Mods MUST use a custom, namespaced storage layout to avoid collisions with other
mods and the core deck. The following `slot_preimage` is the string to be hashed
then the hash digest is subtracted by one to make the slot value's preimage
unknown.

```ebnf
<slot_preimage> = "EtherDeckMk2", ".", <mod_name>, <variable_name>;

<mod_name> = <solc_ident>;
<variable_name> = <solc_ident>;
<solc_ident> = (* solidity identifier *);
```

Example:

```solidity
uint256 slot = uint256(keccak256("EtherDeckMk2.MyMod.myVariable")) - 1;
```

## Rationale

The rationale was to begin with minimal enshrined features and allow mods to be
the extend the functionality of the deck.

Minimal restrictions were placed on the `run` and `runBatch` functions, as these
could contain additional logic including payload decoding.

ERC-4337 is bad.

## Backwards Compatibility

No backward compatibility issues found.

## Reference Implementation

```solidity
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

contract EtherDeckMk2 {
    event DispatchSet(bytes4 indexed selector, address indexed target);

    mapping(bytes4 => address) public dispatch;
    address public runner;

    constructor(address firstRunner) payable {
        runner = firstRunner;
    }

    function run(address target, bytes calldata payload) external payable {
        require(runner == msg.sender);
        (bool success,) = target.call{ value: msg.value }(payload);
        require(success);
    }

    function runBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads
    ) external payable {
        require(runner == msg.sender);
        require(targets.length == values.length && targets.length == payloads.length);
        for (uint256 i; i < targets.length; i++) {
            (bool success,) = targets[i].call{ value: values[i] }(payloads[i]);
            require(success);
        }
    }

    function setDispatch(bytes4 selector, address target) external payable {
        require(runner == msg.sender);
        dispatch[selector] = target;
        emit DispatchSet(selector, target);
    }

    function setDispatchBatch(bytes4[] calldata selectors, address[] calldata targets) external payable {
        require(runner == msg.sender);
        require(selectors.length == targets.length);
        for (uint256 i; i < selectors.length; i++) {
            dispatch[selectors[i]] = targets[i];
            emit DispatchSet(selectors[i], targets[i]);
        }
    }

    fallback(bytes calldata) external payable returns (bytes memory) {
        address mod = dispatch[msg.sig];
        require(mod != address(0));
        (bool success, bytes memory returndata) = mod.delegatecall(msg.data);
        require(success);
        return returndata;
    }

    receive() external payable { }
}
```

## Security Considerations

Mods have complete write access to the deck, be aware of all storage
interactions.

Mods that selfdestruct may selfdestruct the deck if set to the dispatcher.
