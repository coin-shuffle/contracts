// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IUTXO.sol";

/**
 *  @notice A library for managing an UTXO set
 */
library UTXOArray {
    struct Array {
        IUTXO.UTXO[] _values;
    }

    function addOutputs(Array storage array, address token_, IUTXO.Output[] memory outputs_) internal {
        uint256 id_ = array._values.length;

        for (uint256 i = 0; i < outputs_.length; i++) {
            array._values.push(IUTXO.UTXO(id_++, token_, outputs_[i].amount, outputs_[i].owner, false));
        }
    }

    function remove(Array storage array, uint256 id_) internal {
        array._values[id_].isSpent = true;
    }

    function getUTXOByIds(Array storage array, uint256[] memory ids_)
        internal
        view
        returns (IUTXO.UTXO[] memory utxos)
    {
        utxos = new IUTXO.UTXO[](ids_.length);

        uint256 length_ = array._values.length;
        for (uint256 i = 0; i < ids_.length; i++) {
            if (ids_[i] >= length_) {
                revert IUTXO.UTXONotFound();
            }

            utxos[i] = array._values[ids_[i]];
        }
    }

    function length(Array storage array) internal view returns (uint256) {
        return array._values.length;
    }

    function at(Array storage array, uint256 index_) internal view returns (IUTXO.UTXO memory) {
        return array._values[index_];
    }
}
