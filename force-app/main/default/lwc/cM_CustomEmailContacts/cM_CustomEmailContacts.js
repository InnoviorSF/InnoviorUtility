import { LightningElement, api, track } from "lwc";

export default class CM_CustomEmailContactsLWC extends LightningElement {

    contactDataMap = new Map();
    emails = [];
    @api open = false;
    @api 
    get addresses() {
        this.emails;
    }
    set addresses(value) {
        this.emails = JSON.parse(JSON.stringify(value));
    }
    @api  
    get contactmap() {
        return this.contactDataMap;
    }
    set contactmap(value) {
        this.contactDataMap = value;
    }
    @api type = "";


    @track columns = [
        { label: 'Contact Name', fieldName: 'strName' },
        { label: 'Contact Email', fieldName: 'strEmail'},
        { label: 'Contact Title', fieldName: 'strTitle'}
    ];

    contactsCloseHandler() {
        this.dispatchEvent(new CustomEvent('close', {detail: {address: this.addresses, type: this.type}}));
    }

    submitDetails() {
        console.log('Clicked on Submit Details.');
        
        let contactTables = this.template.querySelectorAll("lightning-datatable");
        console.log(contactTables);
        contactTables.forEach(table => {
            var selectedRecords =  table.getSelectedRows();
            
            if(selectedRecords.length > 0){
                console.log('selectedRecords are ', selectedRecords);
       
                selectedRecords.forEach(currentItem => {
                    this.emails.push(currentItem.strEmail);
                });

                console.log('@@Address set to:' + this.emails);
            }   
        });
        this.open = false;
        this.dispatchEvent(new CustomEvent('close', {detail: {address: this.emails, type: this.type}}));
    }

}