pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint TICKET_PRICE = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public eventId;
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event{
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping(address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isOwner(){
        require(msg.sender == owner, "You are not the owner of the contract");
        _;
    }

    constructor() public {
        owner = msg.sender;
        eventId = 0;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _url, uint _numOfTickets)
        public
        isOwner()
        returns (uint)
        {
        events[eventId] = Event({description:_description, website:_url, totalTickets: _numOfTickets, sales: 0, isOpen: true});
        eventId += 1;
        emit LogEventAdded(_description, _url, _numOfTickets, eventId);
        return eventId;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */
        function readEvent(uint _eventId)
            public view
            returns(string memory description, string memory URL, uint totalTickets, uint sales, bool isOpen)
            {
            Event storage myEvent = events[_eventId];
            description = myEvent.description;
            URL = myEvent.website;
            totalTickets = myEvent.totalTickets;
            sales = myEvent.sales;
            isOpen = myEvent.isOpen;
            }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
        function buyTickets(uint _eventId, uint numOfTickets)
            public
            payable
            {
            Event storage myEvent = events[_eventId];
            require(myEvent.isOpen, "Event is closed.");
            require(myEvent.totalTickets >= numOfTickets, "Ticket amount exceeds the stock available.");
            uint totalPrice = numOfTickets * TICKET_PRICE;
            require(msg.value >= totalPrice, "Not enough ETH.");
            myEvent.buyers[msg.sender] += numOfTickets;
            myEvent.totalTickets -= numOfTickets;

            myEvent.sales += numOfTickets;

            uint refundAmount = msg.value - totalPrice;
            if(refundAmount > 0){
                msg.sender.transfer(refundAmount);
            }
            emit LogBuyTickets(msg.sender, _eventId, numOfTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventId)
        public
        {
        Event storage myEvent = events[_eventId];
        uint totalTickets = myEvent.buyers[msg.sender];
        require (totalTickets > 0,"No tickets purchased.");
        myEvent.buyers[msg.sender] -= totalTickets;
        myEvent.totalTickets += totalTickets;
        uint refundAmount = totalTickets * TICKET_PRICE;
        msg.sender.transfer(refundAmount);
        emit LogGetRefund(msg.sender,_eventId, totalTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventId)
        public
        view
        returns(uint){
        Event storage myEvent = events[_eventId];
        return myEvent.buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventId) public isOwner() {
        Event storage myEvent = events[_eventId];
        myEvent.isOpen = false;
        uint totalBalance = myEvent.sales * TICKET_PRICE;
        owner.transfer(totalBalance);
        emit LogEndSale(owner, totalBalance, _eventId);
    }
}
