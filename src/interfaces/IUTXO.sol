// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title UTXO-ERC20 interface
 */
interface IUTXO {
    /**
     * @dev Structure that represents a UTXO in the contract state.
     *
     * Contains the following information:
     *  - `id`: unique identifier of the UTXO
     *  - `token`: address of the token stored in the UTXO
     *  - `amount`: amount of the token stored in the UTXO
     *  - `owner`: address of the owner of the UTXO
     *  - `isSpent`: flag indicating if the UTXO has been spent
     */
    struct UTXO {
        uint256 id;
        address token;
        uint256 amount;
        address owner;
        bool isSpent;
    }

    /**
     * @dev Structure that represents an Output for creating a UTXO.
     *
     * Contains the following information:
     *  - `amount`: amount of the token to be stored in the UTXO
     *  - `owner`: address of the owner of the UTXO
     */
    struct Output {
        uint256 amount;
        address owner;
    }

    /**
     * @dev Structure that represents an Input for spending a UTXO.
     *
     * Contains the following information:
     *  - `id`: unique identifier of the UTXO to be spent
     *  - `signature`: signature signed by the owner of the UTXO, proving ownership
     *
     * The signed data always contains the `id` of the UTXO to be spent.
     * If the operation is a transfer, the signed data also includes concatenated data from the Outputs.
     * If the operation is a withdraw, the signed data also includes the address of the receiver.
     */
    struct Input {
        uint256 id;
        bytes signature;
    }

    error UTXONotFound();
    error InvalidSignature(address owner, uint256 inputId);

    /**
     * @dev Deposits an ERC20 token to the contract by creating UTXOs.
     * Before depositing, ensure that the transfer is approved on the token contract.
     *
     * @param token_ Address of the ERC20 token to be deposited.
     * @param outputs_ Array of Output structs containing information about the UTXOs to be created.
     */
    function deposit(address token_, Output[] memory outputs_) external;

    /**
     * @dev Withdraws an ERC20 token from the contract by spending a UTXO.
     *
     * @param input_ Input struct containing information about the UTXO to be spent.
     * @param to_ Address to withdraw the tokens to.
     */
    function withdraw(Input memory input_, address to_) external;

    /**
     * @dev Transfers an ERC20 token from one UTXO to another
     * by spending the source UTXOs and creating the target UTXOs.
     *
     * @param inputs_ Array of Input structs containing information about the UTXOs to be spent.
     * @param outputs_ Array of Output structs containing information about the UTXOs to be created.
     */
    function transfer(Input[] memory inputs_, Output[] memory outputs_) external;

    /**
     * @dev Returns a list of UTXO objects in the storage, starting from the offset and up to the limit.
     * @param offset_ The position in UTXO array from which the list will start.
     * @param limit_ The maximum number of UTXOs in the list.
     * @return The list of UTXOs.
     */
    function listUTXOs(uint256 offset_, uint256 limit_) external view returns (UTXO[] memory);

    /**
     * @dev Returns a list of UTXO objects in the storage owned by the specified address,
     * starting from the offset and limited by the limit.
     * @param address_ The address of the UTXO owner.
     * @param offset_ The position in UTXO array from which the list will start.
     * @param limit_ The maximum number of UTXOs in the list.
     * @return The list of UTXOs owned by the specified address.
     */
    function listUTXOsByAddress(address address_, uint256 offset_, uint256 limit_)
        external
        view
        returns (UTXO[] memory);

    /**
     * @dev Returns the length of the UTXO array.
     * @return The length of the UTXO array.
     */
    function getUTXOsLength() external view returns (uint256);

    /**
     * @dev Returns the UTXO object with the specified ID from the UTXO array.
     * @param id_ The ID of the UTXO.
     * @return The UTXO object with the specified ID.
     */
    function getUTXOById(uint256 id_) external view returns (UTXO memory);

    /**
     * @dev Returns the list of UTXO objects with the specified IDs from the UTXO array.
     * @param ids_ The IDs of the UTXOs.
     * @return The list of UTXO objects with the specified IDs.
     */
    function getUTXOByIds(uint256[] memory ids_) external view returns (UTXO[] memory);
}
