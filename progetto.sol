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

enum State {
    INACTIVE, 
    ACTIVE
}

/*
*   Access Control Policy 
*/

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract AProgettoSI is Ownable, AccessControl {
    // State
    State state = State.INACTIVE;

    // Roles
    bytes32 public constant PRODUCTOR_ADMIN = keccak256("PRODUCTOR_ADMIN_ROLE");
    bytes32 public constant PRODUCTOR = keccak256("PRODUCTOR_ROLE");

    constructor() Ownable(msg.sender) {
        // Assegnazione del ruolo di ADMIN al proprietario dello SC 
        _setRoleAdmin(PRODUCTOR, PRODUCTOR_ADMIN);
        _grantRole(PRODUCTOR_ADMIN,msg.sender);

        // Attivazione dello smart contract
        state=State.ACTIVE;
    }

    modifier isActive() {
        require(state==State.ACTIVE, " It is required an active state to perform the action. ");
        _;
    }

    // Active & Disactive
    //function active() public onlyOwner onlyState(State.INACTIVE) {
    //    state=State.ACTIVE;
    //} 

    function inactive() public onlyOwner isActive {
        state=State.INACTIVE;
    } 
}

/*
*   Business Logic
*/

contract ProgettoSI is AProgettoSI() {

    // Data Structure
    mapping(uint => uint) private dmap; // did>0
    Device[] private devices;
    mapping(uint => uint) private pmap; // pid>0
    Product[] private products;

    // Device Utility

    function _existDevice(uint did) private view returns(bool) {
        return dmap[did]>0;
    }

    modifier existDevice(uint did) {
        require(
            _existDevice(did), 
            " The device is not registered. ");
        _;
    }

    modifier notExistDevice(uint did) {
        require(
            !_existDevice(did), 
            " The device is already registered. ");
        _;
    }

    function registerDevice(uint did, address dpk) external 
        isActive
        onlyRole(PRODUCTOR)
        notExistDevice(did)
        returns(uint) 
    {
        devices.push(
            Device(did,dpk,block.timestamp)
        );
        dmap[did]=devices.length-1;
        return did;
    }

    function getDevice(uint did) public view 
        isActive
        onlyRole(PRODUCTOR)
        existDevice(did)
        returns(Device memory) 
    {
        return devices[ dmap[did] ];
    }

    function getNumOfDevices() public view 
        isActive
        returns(uint) 
    {
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
        isActive
        onlyRole(PRODUCTOR)
        notExistProduct(pid)
        returns(uint)
    {
        products.push(
            Product(pid,name)
        );
        pmap[pid]=products.length-1;
        return pid;
    }

    function getProduct(uint pid) public view 
        isActive
        onlyRole(PRODUCTOR)
        existProduct(pid)
        returns(Product memory) 
    {
        return products[ pmap[pid] ];
    }

    function getNumOfProduct() public view 
        isActive
        returns(uint) 
    {
        return products.length;
    }

    // Combination did => pid
    mapping(uint => uint) private combination; 

    function _existCombination(uint pid, uint did) private view
        existDevice(did)
        existProduct(pid)
        returns(bool) 
    {
        return combination[did]>0;
    }

    modifier notExistCombination(uint pid, uint did) {
        require(!_existCombination(pid,did), " The combination already exists. ");
        _;
    }

    function combine(uint pid, uint did) external 
        isActive
        onlyRole(PRODUCTOR)
        notExistCombination(did,pid)
        returns(Device memory, Product memory) 
    {
        combination[did]=pid;   
        return (this.getDevice(did), this.getProduct(pid));
    }

    //TODO get combination
}