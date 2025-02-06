// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract OProgettoSI is Ownable, AccessControl {
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

struct Product {
    string name;
    uint id;
    // others
}

struct Device {
    uint id;
    address pubkey;
    uint ts_registration;
}

contract ProgettoSI is OProgettoSI() {

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
            Product("-1",0)
        );
    }

    modifier checkExistDevice(address pubkey) {
        require(
            pubkey!=address(0x0) && dmap[pubkey]>0, 
            " The device is already registered. ");
        _;
    }

    modifier checkExistProduct(uint pid) {
        require(
            pmap[pid]>0, 
            " The product does not exists registered. ");
        _;
    }

    // Device Utility

    function registerDevice(address device_pubkey) external 
        onlyRole(PRODUCTOR)
        checkExistDevice(device_pubkey) 
        returns(uint) 
    {
        uint id=devices.length;
        devices.push(
            Device(id,device_pubkey,block.timestamp)
        );
        dmap[device_pubkey]=id;
        return id;
    }

    function getDevice(address device_pubkey) public view 
        onlyRole(PRODUCTOR)
        checkExistDevice(device_pubkey)
        returns(Device memory) 
    {
       uint id=dmap[device_pubkey];
        return devices[id];
    }

    function getNumOfDevices() public view returns(uint) {
        return devices.length-1;
    }

    // Product Utility

    //TODO

}