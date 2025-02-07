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
    string prodType;
    string fabric;
}

struct Device {
    uint did;
    address pubkey;
    uint timestamp;
}

enum State { INACTIVE, ACTIVE }

/*
*   Access Control Policy 
*/

// TODO commenti

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract AProgettoSI is Ownable, AccessControl {
    // State
    State private state = State.INACTIVE;
    // Roles
    bytes32 internal constant PRODUCER = keccak256("PRODUCER_ROLE");

    constructor() Ownable(msg.sender) {
        // Assegnazione del ruolo di ADMIN al proprietario dello SC 
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        // Attivazione dello smart contract
        active();
    }

    //Events
    event ContractState(string indexed state, uint timestamp);
    event ProducerRegistered(address indexed account, uint timestamp);
    event ProducerRevoked(address indexed account, uint timestamp);

    // Active & Disactive

    modifier isActive() {
        require(state==State.ACTIVE, " It is required an active state to perform the action. ");
        _;
    }

    modifier isInactive() {
        require(state==State.INACTIVE, " It is required an inactive state to perform the action. ");
        _;
    }

    function active() public isInactive onlyOwner {
        state=State.ACTIVE;
        emit ContractState("ACTIVE",block.timestamp);
    } 

    function inactivate() public isActive onlyOwner {
        state=State.INACTIVE;
        emit ContractState("INACTIVE",block.timestamp);
    } 

    // Assign and Revoke Role
    function registerProducer(address account) external isActive {
        grantRole(PRODUCER, account);
        emit ProducerRegistered(account, block.timestamp);
    }

    function revokeProducer(address account) external isActive {
        revokeRole(PRODUCER, account);
        emit ProducerRevoked(account, block.timestamp);
    }
}

/*
*   Business Logic
*/

contract ProgettoSI is AProgettoSI() {

    mapping(uint => uint) private dmap; // did => index>0
    Device[] private devices;           // devices.length-1 elementi di tipo Device
    mapping(uint => uint) private pmap; // pid => index>0
    Product[] private products;         // devices.length-1 elementi di tipo Product

    // Events
    event DeviceRegistered(uint indexed did, address dpk, uint timestamp);
    event ProductRegistered(uint indexed pid, string name, string size, string color, string prodType, string fabric, uint timestamp);
    event Linked(uint indexed did, uint indexed pid, uint timestamp);
    //event Unliked(uint indexed did, uint indexed pid, uint timestamp)

    constructor() {
        // Inizializzazione delle strutture devices e products tali per cui si ha che
        // dmap[did] e pmap[pid] sono registrate se sono associati ad elementi degli array
        // con indice > 0.
        devices.push(Device(0,address(0x0),0));
        products.push(Product(0,"name","size","color","prodType","fabric"));
    }


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
        uint index=devices.length;
        devices.push(
            Device(did,dpk,block.timestamp)
        );
        dmap[did]=index;
        emit DeviceRegistered(did,dpk,block.timestamp);
        return did;
    }

    function getDevice(uint did) public view 
        isActive
        existDevice(did)
        returns(Device memory) 
    {
        return devices[ dmap[did] ];
    }

    function getAllDevices() public view
        isActive
        returns(Device[] memory)
    {
        return devices;
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

    function registerProduct(uint pid, string memory name, string memory size, string memory color, string memory prodType, string memory fabric) external 
        isActive
        onlyRole(PRODUCER)
        notExistProduct(pid)
        returns(uint)
    {
        uint index=products.length;
        products.push(
            Product(pid,name,size,color,prodType,fabric)
        );
        pmap[pid]=index;
        emit ProductRegistered(pid, name, size, color, prodType, fabric, block.timestamp);
        return pid;
    }

    function getProduct(uint pid) public view 
        isActive
        existProduct(pid)
        returns(Product memory) 
    {
        return products[ pmap[pid] ];
    }

    function getAllProducts() public view
        isActive
        returns(Product[] memory)
    {
        return products;
    }

    function getNumOfProduct() public view 
        isActive
        returns(uint) 
    {
        return products.length-1;
    }

    // Combinazioni: did => pid, pid => did[]
    mapping(uint => uint) private dlinks; 
    mapping(uint => uint[]) private plinks; 

    function link(uint pid, uint did) external 
        isActive
        onlyRole(PRODUCER)
        existDevice(did)
        existProduct(pid)
        returns(Device memory, Product memory) 
    {
        require(dlinks[did]==0, " The device is already linked to other device. ");
        for(uint i=0; i<plinks[pid].length; i++){
            require(plinks[pid][i]!=did, " The product is already linked with this device. ");
        }
        dlinks[did]=pid; 
        plinks[pid].push(did);
        emit Linked(did, pid, block.timestamp);
        return (this.getDevice(did), this.getProduct(pid));
    }

    function getProductLinkedTo(uint did) public view
        isActive
        existDevice(did)
        returns(uint) 
    {
        return dlinks[did];
    }
        
    function getDeviceLinkedTo(uint pid) public view
        isActive
        existProduct(pid)
        returns(uint[] memory) 
    {
        return plinks[pid];
    }
}