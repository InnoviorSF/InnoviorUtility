import { LightningElement, track, api } from "lwc";
//import search from "@salesforce/apex/CM_CustomSendEmailController.search";

export default class CM_CustomSendEmailInput extends LightningElement {
    @track items = [];

    @track showInput = false;
    @track newEmail;
    //searchTerm = "";
    //blurTimeout;
    //boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";

    _selectedValues = [];
    selectedValuesMap = new Map();

    @api
    get selectedValues() {
        return this._selectedValues;
    }
    set selectedValues(value) {
        this._selectedValues = value;

        const selectedValuesEvent = new CustomEvent("selection", { detail: { selectedValues: this._selectedValues} });
        this.dispatchEvent(selectedValuesEvent);
    }

    @api updateValues(values) {
        values.forEach(value => {
            if (value !== undefined && value != null && value !== "") {
                this.selectedValuesMap.set(value, value);
                this.selectedValues = [...this.selectedValuesMap.keys()];
            }
        });
    }

    handleKeyPress(event) {
        if (event.keyCode === 13 && this.allValid) {     // enter key function
            this.addNewEmailToList(event);
        }
    }

    handleRemove(event) {
        const item = event.target.label;
        this.selectedValuesMap.delete(item);
        this.selectedValues = [...this.selectedValuesMap.keys()];
    }

    @api reset() {
        this.selectedValuesMap = new Map();
        this.selectedValues = [];
    }

    @api validate() {
        this.template.querySelector('input').reportValidity();
        const isValid = this.template.querySelector('input').checkValidity();
        return isValid;
    }

    showInputBox(event) {
        this.showInput = true;
        setTimeout(() => {
            if(this.template.querySelector('lightning-input')) {
                this.template.querySelector('lightning-input').focus();
            }
        }, 5);
    }

    updateNewEmail(event) {
        if (this.allValid()) {
            this.newEmail = event.target.value;
            console.log(this,this.newEmail);
        }
    }

    addNewEmailToList(event) {
        if(this.newEmail) {
            this.selectedValuesMap.set(this.newEmail, this.newEmail);
            this.selectedValues = [...this.selectedValuesMap.keys()];

            this.newEmail = '';
        }

        this.showInput = false;
    }

    allValid() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allValid;
    }
}