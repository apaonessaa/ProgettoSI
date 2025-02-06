// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/*
*   Product & Device structures
*/
struct Product {
    uint pid;
    string name;
    // others
}

struct Device {
    uint did;
    address pubkey;
    uint ts_registration;
}

/*
*   Access Control Policy 
*/

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ACProgettoSI is Ownable, AccessControl {
    // Roles
    bytes32 public constant PRODUCTOR_ADMIN = keccak256("PRODUCTOR_ADMIN_ROLE");
    bytes32 public constant PRODUCTOR = keccak256("PRODUCTOR_ROLE");

    constructor() Ownable(msg.sender) {
        // Assegnazione del ruolo di ADMIN al proprietario dello SC 
        _setRoleAdmin(PRODUCTOR, PRODUCTOR_ADMIN);
        _grantRole(PRODUCTOR_ADMIN,msg.sender);
    }

    // Activate & Disactivate 
}

/*
*   Business Logic
*/

contract ProgettoSI is ACProgettoSI() {

    // Data Structure
    mapping(address => uint) private dmap;
    Device[] private devices;
    mapping(uint => uint) private pmap;
    Product[] private products;

    constructor() {
        // Init devices
        devices.push(
            Device(0,address(0x0),block.timestamp)
        );
        // In questo modo, nella struttura dmap, affinche' 
        // un device sia stato registrato, deve avere un id>0.
        // Il numero di devices coincide con devices.length-1

        // Init products
        products.push(
            Product(0,"NO PRODUCT")
        );
    }

    // Device Utility

    function _existDevice(address pubkey) private view returns(bool) {
        return dmap[pubkey]>0;
    }

    function _isValidDevice(address pubkey) private pure returns(bool) {
        return pubkey!=address(0x0);
    }

    modifier existDevice(address pubkey) {
        require(
            _isValidDevice(pubkey) && _existDevice(pubkey), 
            " The device is not registered. ");
        _;
    }

    modifier notExistDevice(address pubkey) {
        require(
            _isValidDevice(pubkey) && !_existDevice(pubkey), 
            " The device is already registered. ");
        _;
    }

    function registerDevice(address device_pubkey) external 
        onlyRole(PRODUCTOR)
        notExistDevice(device_pubkey) 
        returns(uint) 
    {
        uint did=devices.length;
        devices.push(
            Device(did,device_pubkey,block.timestamp)
        );
        dmap[device_pubkey]=did;
        return did;
    }

    function getDevice(address device_pubkey) public view 
        onlyRole(PRODUCTOR)
        existDevice(device_pubkey)
        returns(Device memory) 
    {
       uint i=dmap[device_pubkey];
        return devices[i];
    }

    function getNumOfDevices() public view returns(uint) {
        return devices.length-1;
    }

    // Product Utility

    function _existProduct(uint pid) private view returns(bool) {
        return pmap[pid]>0;
    }

    modifier existProduct(uint pid) {
        require(
            _existProduct(pid), 
            " The product is not registered. ");
        _;
    }

    modifier notExistProduct(uint pid) {
        require(
            !_existProduct(pid), 
            " The product is already registered. ");
        _;
    }

    function registerProduct(uint pid, string memory name) external 
        onlyRole(PRODUCTOR)
        notExistProduct(pid)
    {
        products.push(
            Product(pid,name)
        );
        pmap[pid]=products.length-1;
    }

    function getProduct(uint pid) public view 
        onlyRole(PRODUCTOR)
        existProduct(pid)
        returns(Product memory) 
    {
        uint i=pmap[pid];
        return products[i];
    }

    function getNumOfProduct() public view returns(uint) {
        return products.length-1;
    }
}