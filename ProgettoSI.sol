// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AbstractProgettoSI is Ownable, AccessControl {
    enum State { INACTIVE, ACTIVE }

    State private state = State.INACTIVE;
    bytes32 internal constant PRODUCER = keccak256("PRODUCER_ROLE");

    //Events
    event ContractState(string indexed state, uint timestamp);
    event ProducerRegistered(address indexed account, uint timestamp);
    event ProducerRevoked(address indexed account, uint timestamp);

    // Modifiers
    modifier isActive() {
        require(state==State.ACTIVE, "It is required an active state to perform the action.");
        _;
    }

    // Metodi per l'attivazione e disattivazione dello smart contract
    function activate() public onlyOwner {
        require(state==State.INACTIVE, "It is required an inactive state to perform the action.");
        state=State.ACTIVE;
        emit ContractState("ACTIVE",block.timestamp);
    }

    function deactivate() public isActive onlyOwner {
        state=State.INACTIVE;
        emit ContractState("INACTIVE",block.timestamp);
    }

    // Metodi per l'assegnamento e revoca del ruolo di Producer
    function registerProducer(address account) external isActive {
        grantRole(PRODUCER, account);
        emit ProducerRegistered(account,block.timestamp);
    }

    function revokeProducer(address account) external isActive {
        revokeRole(PRODUCER, account);
        emit ProducerRevoked(account,block.timestamp);
    }

    // Metodo per l'assegnazione di un nuovo admin per la gestione dei ruoli
    function transferAdmin(address account) external isActive {
        grantRole(DEFAULT_ADMIN_ROLE,account);
        _revokeRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }
}

contract ProgettoSI is AbstractProgettoSI {

    struct Device {
        uint did;
        address pubkey;
        uint timestamp;
    }

    struct Product {
        uint pid;
        string name;
        string size;
        string color;
        string prodType;
        string fabric;
    }

    mapping(uint => uint) private dmap; // did => index>0,      dmap[did]=index => devices[index]=Device(did)
    Device[] private devices;           // devices.length-1
    mapping(uint => uint) private pmap; // pid>0 => index>0,    pmap[pip]=index => products[index]=Product(pid)
    Product[] private products;         // devices.length-1

    // Events
    event DeviceRegistered(uint indexed did, address dpk, uint timestamp, address producer);
    event ProductRegistered(uint indexed pid, string name, string size, string color, string prodType, string fabric, uint timestamp, address producer);

    constructor() Ownable(msg.sender) {
        // Con il deployment dello smart contract, il deployer diventa sia proprietario dello stesso che admin per la gestione 
        // del ruolo di Producer. Lo smart contract viene attivato.
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        activate();
        
        // Inizializzazione delle strutture devices e products.
        // L'idea e' quella di avere nelle mappe pmap e dmap le associazioni tra device identifier (did) e product identifier (pid)
        // con i corrispettivi oggetti Device e Product che sono contenuti in devices e products.
        //
        //      dmap[did] = index per cui devices[index] = Device(did)
        //
        // Per evitare le ambiguità con l'indice 0, si e' pensato di inizializzare le due strutture con un elemento "dummy".
        // 
        // Tutte le registrazioni associeranno a dmap[did] e pmap[pid] un index>0.
        //
        // Se dmap[did]=0 significa che non e' stato registrato alcun device con l'identificativo did, altrimenti dmap[did]=index
        // corrisponde al Device gia' registrato e contenuto in devices[index].
        //
        // Stesso discorso per pmap e products.
        devices.push(Device(0,address(0x0),0));
        products.push(Product(0,"","","","",""));
    }

    // Funzionalita' per la gestione dei Devices
    function _existDevice(uint did) private view returns(bool) {
        return dmap[did]>0;
    }

    modifier existDevice(uint did) {
        require(_existDevice(did),"The device is not registered.");
        _;
    }

    modifier notExistDevice(uint did) {
        require(!_existDevice(did),"The device is already registered.");
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
            Device(did, dpk, block.timestamp)
        );
        dmap[did]=index;
        emit DeviceRegistered(did, dpk, block.timestamp, msg.sender);
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
        return devices.length-1; // non considera l'elemento dummy
    }

    // Funzionalita' per la gestione dei Products
    function _existProduct(uint pid) private view returns(bool) {
        return pmap[pid]>0;
    }

    modifier existProduct(uint pid) {
        require(_existProduct(pid),"The product is not registered.");
        _;
    }

    // Per evitare ambiguita' con il collegamento di un device ad un prodotto (si guardi la parte di codice
    // per la gestione dei links) si e' deciso di definire un vincolo sul valore che lo identifica.
    // Per cui si ha che pid != 0.
    modifier notExistProduct(uint pid) {
        require(pid!=0, "The product identifier is not valid.");
        require(!_existProduct(pid), "The product is already registered.");
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
            Product(pid, name, size, color, prodType, fabric)
        );
        pmap[pid]=index;
        emit ProductRegistered(pid, name, size, color, prodType, fabric, block.timestamp, msg.sender);
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
        return products.length-1; // non considera l'elemento dummy
    }

    // Gestione dei collegamenti tra Device e Product
    // Si e' considerato il contesto in cui un Device e' collegato ad esclusivamente un Product, mentre un Product
    // puo' essere collegato ad uno o piu' Device.
    mapping(uint => uint) private dlinks;       // dlinks[did]=pid
    mapping(uint => uint[]) private plinks;     // plinks[pid]=[did,...]

    event Linked(uint indexed did, uint indexed pid, uint timestamp, address producer);

    // Per il vincolo imposto durante la registrazione di un prodotto (pid>0) se dlinks[did]=0 significa che
    // il Device con identificativo did non e' associato a nessun product!
    function link(uint pid, uint did) external 
        isActive
        onlyRole(PRODUCER)
        existDevice(did)
        existProduct(pid)
        returns(Device memory, Product memory) 
    {
        require(dlinks[did]==0, "The device is already linked to other product.");
        dlinks[did]=pid; 
        plinks[pid].push(did);
        emit Linked(did, pid, block.timestamp, msg.sender);
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