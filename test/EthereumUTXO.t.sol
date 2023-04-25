// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "forge-std/Test.sol";

import "src/core/EthereumUTXO.sol";
import "src/mock/tokens/ERC20Mock.sol";

import "../src/interfaces/IUTXO.sol";

contract TestEthereumUTXO is Test {
    using ECDSA for bytes32;

    EthereumUTXO utxo;
    ERC20Mock token;
    ERC20Mock token2;

    uint256 constant acc1PK = 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e;
    uint256 constant acc2PK = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    address immutable acc1;
    address immutable acc2;

    constructor() {
        acc1 = vm.addr(acc1PK);
        acc2 = vm.addr(acc2PK);
    }

    function setUp() public {
        utxo = new EthereumUTXO();
        token = new ERC20Mock("TestToken", "TT", 18);
        token2 = new ERC20Mock("TestToken2", "TT2", 18);

        token.mint(acc1, 100 ether);
        token.mint(acc2, 100 ether);
        token2.mint(acc1, 100 ether);

        vm.prank(acc1);
        token.approve(address(utxo), 10 ether);

        vm.prank(acc2);
        token.approve(address(utxo), 10 ether);

        vm.prank(acc1);
        token2.approve(address(utxo), 10 ether);

        IUTXO.Output[] memory array1 = new IUTXO.Output[](3);
        array1[0] = IUTXO.Output({owner: acc1, amount: 1 ether});
        array1[1] = IUTXO.Output({owner: acc1, amount: 1.2 ether});
        array1[2] = IUTXO.Output({owner: acc1, amount: 1.5 ether});

        vm.prank(acc1);
        utxo.deposit(address(token), array1);

        array1[0] = IUTXO.Output({owner: acc2, amount: 2 ether});
        array1[1] = IUTXO.Output({owner: acc2, amount: 2.33 ether});
        array1[2] = IUTXO.Output({owner: acc2, amount: 2.52 ether});

        vm.prank(acc2);
        utxo.deposit(address(token), array1);

        vm.prank(acc1);
        array1[0] = IUTXO.Output({owner: acc1, amount: 2 ether});
        array1[1] = IUTXO.Output({owner: acc1, amount: 2.33 ether});
        array1[2] = IUTXO.Output({owner: acc1, amount: 2.52 ether});

        utxo.deposit(address(token2), array1);
    }

    function testGlobals() public {
        vm.assume(utxo.getUTXOsLength() == 9);

        vm.assume(utxo.getUTXOById(0).owner == acc1);

        vm.expectRevert(IUTXO.UTXONotFound.selector);
        utxo.getUTXOById(22);

        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        IUTXO.UTXO[] memory utxos = utxo.getUTXOByIds(ids);
        console.log(utxos[0].owner);
        vm.assume(utxos[0].owner == acc1);
        vm.assume(utxos[0].amount == 1 ether);
        vm.assume(utxos[1].owner == acc1);
        vm.assume(utxos[1].amount == 1.2 ether);
    }

    function testDeposit(address erc20Token) public {
        vm.expectRevert("EthereumUTXO: empty outputs");
        IUTXO.Output[] memory array = new IUTXO.Output[](0);
        utxo.deposit(erc20Token, array);

        IUTXO.Output[] memory array3 = new IUTXO.Output[](1);
        array3[0] = IUTXO.Output({owner: acc1, amount: 1 ether});

        vm.prank(acc1);
        utxo.deposit(address(token), array3);
    }

    function testTransfer() public {
        vm.expectRevert("EthereumUTXO: outputs can not be empty");
        utxo.transfer(new IUTXO.Input[](0), new IUTXO.Output[](0));

        vm.expectRevert("EthereumUTXO: inputs can not be empty");
        utxo.transfer(new IUTXO.Input[](0), new IUTXO.Output[](1));

        IUTXO.Input[] memory inputs = new IUTXO.Input[](2);
        inputs[0] = IUTXO.Input({id: 1, signature: new bytes(0)});
        inputs[1] = IUTXO.Input({id: 3, signature: new bytes(0)});

        IUTXO.Output[] memory newOutputs = new IUTXO.Output[](2);
        newOutputs[0] = IUTXO.Output({owner: acc1, amount: 2 ether});
        newOutputs[1] = IUTXO.Output({owner: acc2, amount: 1.3 ether});

        bytes memory data_;
        for (uint256 i = 0; i < newOutputs.length; i++) {
            data_ = abi.encodePacked(data_, newOutputs[i].amount, newOutputs[i].owner);
        }

        inputs[0].signature = _getSignature(acc1PK, 1, data_);
        inputs[1].signature = _getSignature(acc2PK, 3, data_);

        vm.expectRevert("EthereumUTXO: input and output amount mismatch");
        utxo.transfer(inputs, newOutputs);

        vm.expectRevert(IUTXO.UTXONotFound.selector);
        inputs[0] = IUTXO.Input({id: 1, signature: _getSignature(acc1PK, 1, data_)});
        inputs[1] = IUTXO.Input({id: 16, signature: new bytes(0)});

        utxo.transfer(inputs, newOutputs);

        newOutputs[1] = IUTXO.Output({owner: acc2, amount: 1.2 ether});
        data_ = new bytes(0);
        for (uint256 i = 0; i < newOutputs.length; i++) {
            data_ = abi.encodePacked(data_, newOutputs[i].amount, newOutputs[i].owner);
        }
        inputs[0] = IUTXO.Input({id: 1, signature: _getSignature(acc1PK, 1, data_)});
        inputs[1] = IUTXO.Input({id: 3, signature: _getSignature(acc2PK, 3, data_)});

        utxo.transfer(inputs, newOutputs);

        vm.expectRevert("EthereumUTXO: UTXO has been spent");
        utxo.transfer(inputs, newOutputs);

        vm.expectRevert("EthereumUTXO: UTXO token mismatch");
        inputs[0] = IUTXO.Input({id: 6, signature: _getSignature(acc1PK, 6, data_)});

        utxo.transfer(inputs, newOutputs);

        vm.expectRevert(IUTXO.UTXONotFound.selector);
        inputs[0] = IUTXO.Input({id: 16, signature: new bytes(0)});
        utxo.transfer(inputs, newOutputs);

        vm.expectRevert(abi.encodePacked(IUTXO.InvalidSignature.selector, abi.encode(acc1, 6)));
        inputs[0] = IUTXO.Input({id: 6, signature: _getSignature(acc1PK, 7, data_)});

        utxo.transfer(inputs, newOutputs);
    }

    function testWithdraw() public {
        vm.expectRevert(IUTXO.UTXONotFound.selector);
        utxo.withdraw(IUTXO.Input({id: 10, signature: _getSignature(acc1PK, 10, abi.encodePacked(acc1))}), acc1);

        vm.expectRevert(abi.encodePacked(IUTXO.InvalidSignature.selector, abi.encode(acc1, 1)));
        utxo.withdraw(IUTXO.Input({id: 1, signature: _getSignature(acc1PK, 2, abi.encodePacked(acc1))}), acc1);

        utxo.withdraw(IUTXO.Input({id: 1, signature: _getSignature(acc1PK, 1, abi.encodePacked(acc1))}), acc1);

        vm.expectRevert("EthereumUTXO: UTXO has been spent");
        utxo.withdraw(IUTXO.Input({id: 1, signature: _getSignature(acc1PK, 1, abi.encodePacked(acc1))}), acc1);
    }

    function testListUTXOs() public {
        IUTXO.UTXO[] memory utxos = utxo.listUTXOs(2, 2);
        vm.assume(utxos.length == 2);
        vm.assume(utxos[0].id == 2);
        vm.assume(utxos[0].owner == acc1);
        vm.assume(utxos[0].amount == 1.5 ether);
        vm.assume(utxos[0].token == address(token));

        vm.assume(utxos[1].id == 3);
        vm.assume(utxos[1].owner == acc2);
        vm.assume(utxos[1].amount == 2 ether);
        vm.assume(utxos[1].token == address(token));
    }

    function testListUTXOsAddress() public {
        IUTXO.UTXO[] memory utxos = utxo.listUTXOsByAddress(acc1, 1, 5);
        vm.assume(utxos.length == 2);
        vm.assume(utxos[0].id == 1);
        vm.assume(utxos[0].owner == acc1);
        vm.assume(utxos[0].amount == 1.2 ether);
        vm.assume(utxos[0].token == address(token));

        vm.assume(utxos[1].id == 2);
        vm.assume(utxos[1].owner == acc1);
        vm.assume(utxos[1].amount == 1.5 ether);
        vm.assume(utxos[1].token == address(token));
    }

    function _getSignature(uint256 pk_, uint256 id_, bytes memory data_) private returns (bytes memory signature) {
        bytes32 toSign_ = keccak256(abi.encodePacked(id_, data_)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk_, toSign_);
        signature = bytes.concat(r, s, bytes1(v));
    }
}
