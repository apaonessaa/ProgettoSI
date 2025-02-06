// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/*
*   Product & Device structures
*/
struct Product {
    uint pid;
    string name;
    string size;
    string color;
    string category;
    string fabric;
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
    bytes32 public constant PRODUCER = keccak256("PRODUCER_ROLE");

    constructor() Ownable(msg.sender) {
        // Assegnazione del ruolo di ADMIN al proprietario dello SC 
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        // Attivazione dello smart contract
        state=State.ACTIVE;
    }

    // Role
    function registerProducer(address account) external isActive onlyOwner {
        grantRole(PRODUCER, account);
    }

    // Active & Disactive
    //function active() public onlyOwner onlyState(State.INACTIVE) {
    //    state=State.ACTIVE;
    //} 

    modifier isActive() {
        require(state==State.ACTIVE, " It is required an active state to perform the action. ");
        _;
    }

    function inactivate() public onlyOwner isActive {
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
        onlyRole(PRODUCER)
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

    function registerProduct(uint pid, string memory name, string memory size, string memory color, string memory category, string memory fabric) external 
        isActive
        onlyRole(PRODUCER)
        notExistProduct(pid)
        returns(uint)
    {
        products.push(
            Product(pid,name,size,color,category,fabric)
        );
        pmap[pid]=products.length-1;
        return pid;
    }

    function getProduct(uint pid) public view 
        isActive
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

    // Combination: did => pid, pid => did
    mapping(uint => uint) private dcombine; 
    mapping(uint => uint) private pcombine; 

    function combine(uint pid, uint did) external 
        isActive
        onlyRole(PRODUCER)
        existDevice(did)
        existProduct(pid)
        returns(Device memory, Product memory) 
    {
        require(dcombine[did]==0, " The device is already combined. ");
        require(pcombine[pid]==0, " The product is already combined. ");
        dcombine[did]=pid;   
        pcombine[pid]=did;
        return (this.getDevice(did), this.getProduct(pid));
    }

    function getProductCombined(uint did) public view
        isActive
        existDevice(did)
        returns(uint) 
    {
        return dmap[did];
    }
        
    function getDeviceCombined(uint pid) public view
        isActive
        existProduct(pid)
        returns(uint) 
    {
        return pmap[pid];
    }
}