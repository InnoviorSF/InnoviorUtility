/* eslint-disable no-alert */
import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import { CloseActionScreenEvent } from 'lightning/actions';
import sendEmailController from "@salesforce/apex/CM_CustomSendEmailController.sendEmailController";
import fetchEmailTemplate from "@salesforce/apex/CM_CustomSendEmailController.fetchEmailTemplate";
import fetchEmailBody from "@salesforce/apex/CM_CustomSendEmailController.fetchEmailBody";
import getFromEmailAddress from "@salesforce/apex/CM_CustomSendEmailController.getFromEmailAddress";
import getContactEmails from "@salesforce/apex/CM_CustomSendEmailController.getContactEmails";
import getDefaultFromEmailAddress from "@salesforce/apex/CM_CustomSendEmailController.getDefaultFromEmailAddress";
import getAllRelatedFiles from "@salesforce/apex/CM_CustomSendEmailController.getAllRelatedFiles";
import findObjectNameFromRecordIdPrefix from "@salesforce/apex/CM_CustomSendEmailController.findObjectNameFromRecordIdPrefix";

export default class CM_SendEmailContainer extends NavigationMixin(LightningElement) {
    @track toAddress = [];
    @track ccAddress = [];
    @track bccAddress = [];
    fileIDs = [];
    contactDataMap = new Map();
    relatedFilesDataMap = new Map();
    subject = "";
    @track body = "";
    @track plainTextBody = "";
    fromAddress = "";
    fromAddressId = "";
    @track fromAddressses = [];
    noEmailError = false;
    invalidEmails = false;
    @track isLoaded = false;
    templateOptions = [];

    @track defaultFromAddress = [];

    showBCC = false;
    showCC = false;

    @track toContactSelectModal = false;
    @track ccContactSelectModal = false;
    @track bccContactSelectModal = false;
    @track uploadedFileList = []
        
    _recordId;
    _objectType;

    @api set recordId(value) {
        this._recordId = value;
        this.isLoaded = true;
        findObjectNameFromRecordIdPrefix({recordIdOrPrefix: this._recordId})
        .then(response => {
            if(response) {
                console.log('@@ objectType: ' + JSON.stringify(response));
                this._objectType = response;
            }
            getContactEmails({idMainRecord : this._recordId, objectType : this._objectType})
            .then(response => {
                if (response) {
                    console.log('@@ data: '+JSON.stringify(response));
                    let temp = [];
                    for (let key in response) {
                        temp.push({ key: key, value: response[key] });
                    }
        
                    this.contactDataMap = temp;
                    console.log('@@ this.contactDataMap: '+JSON.stringify(this.contactDataMap));
                }
                this.isLoaded = false;
            }).catch((error)=>{
                this.isLoaded = false
                console.log('ID = ' + this._recordId + '\nError getContactEmails: ',JSON.stringify(error));
            })
               
    
            getFromEmailAddress({recordId : this._recordId, objectType : this._objectType})
            .then(response => {
                if(response) {
                    console.log('@@getFromEmailAddress: ' + JSON.stringify(response));
                    var fromAddressses = JSON.parse(JSON.stringify(response));
                    fromAddressses.forEach(address => {
                        var display = address.DisplayName + ': ' + address.Address;
                        console.log('@display: ' + display);
                        this.fromAddressses.push({ key: display, value: address.Address, id: address.Id});
                    });
                }

                getDefaultFromEmailAddress({recordId : this._recordId, objectType : this._objectType})
                .then(response => {
                    if(response) {
                        console.log('@@getDefaultFromEmailAddress: ' + JSON.stringify(response));
                        var display = response.DisplayName + ': ' + response.Address;
                        this.defaultFromAddress.push({ key: display, value: response.Address, id: response.Id});
                        console.log('@@defaultFromAddress.key: ' + this.defaultFromAddress[0].key);
                        console.log('@@defaultFromAddress.value: ' + this.defaultFromAddress[0].value);
                        this.fromAddressses = this.fromAddressses.filter(item => item.key !== this.defaultFromAddress[0].key);
                        this.fromAddress = this.defaultFromAddress[0].value;
                        this.fromAddressId = this.defaultFromAddress[0].id;
                    }
                }).catch((error) => {
                    console.log('ID = ' + this._recordId + '\nError getDefaultFromEmailAddress: ', JSON.stringify(error));
                })

            }).catch((error) => {
                console.log('ID = ' + this._recordId + '\nError getFromEmailAddress: ', JSON.stringify(error));
            } )
    
           

            fetchEmailTemplate()
            .then(result => {
                console.log('@@TemplateOptions: ' + JSON.stringify(result));
                this.templateOptions = result;
            })
            .catch((errors) => {
                let error = ((JSON.stringify(errors.body)).split("message\":\""));
                error = error[error.length - 1].split("\"")[0];
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to load email templates. Error: ' + error,
                        variant: 'error'
                    })
                    );
            });

            getAllRelatedFiles({caseId : this._recordId, objectType : this._objectType})
            .then(response => {
                if(response) {
                    console.log('@@getAllRelatedFiles: ' + JSON.stringify(response));
                    let temp = [];
                    for (let key in response) {
                        temp.push({ key: key, value: response[key] });
                    }
        
                    this.relatedFilesDataMap = temp;
                    console.log('@@ this.relatedFilesDataMap: '+JSON.stringify(this.relatedFilesDataMap));
                }
            }).catch((error) => {
                console.log('ID = ' + this._recordId + '\nError getAllRelatedFiles: ',JSON.stringify(error));
            })

        }).catch((error)=>{
            console.log('ID = ' + this.recordId + '\nError findObjectNameFromRecordIdPrefix: ',JSON.stringify(error));
        })
    }
    
    get recordId() {
        return this._recordId;
    }

    @track files = [];

    get hasDefaultFromAddress() {
        if (this.defaultFromAddress.length > 0) {
            return this.defaultFromAddress[0];
        }        
    }


    navigateToFile(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
          type: "standard__namedPage",
          attributes: {
            pageName: "filePreview"
          },
          state: {
            recordIds: event.target.value,
            selectedRecordId: event.target.value
          }
        });
      }

    handleFromEmailChange(event) {
        this.fromAddress = event.target.value;
        this.fromAddressses.forEach(address => {
            console.log('@@addressvalue : ' + address.value);
            console.log('@@fromaddress : ' + this.fromAddress);
            if(address.value == this.fromAddress) {
                this.fromAddressId = address.id;
                console.log('@@fromAddressId set to: ' + this.fromAddressId);
            }
        })
    
        console.log('@@fromAddress set to: ' + this.fromAddress);

    }

    openToContactModal(){
        this.toContactSelectModal = true;
    }

    openCcContactModal(){
        this.ccContactSelectModal = true;
    }

    openBccContactModal(){
        this.bccContactSelectModal = true;
    }

    handleShowCc() {
        this.showCC = !this.showCC;
    }

    handleShowBcc() {
        this.showBCC = !this.showBCC;
    }
    
    contactsCloseHandler(event) {
        let address = event.detail.address;
        var input;
        if(address){
            if (event.detail.type == "to") {
                
                    this.toAddress = address;
                input = this.template.querySelector(".to-input");
                
            } else if(event.detail.type == "cc" ) {
                    this.ccAddress = address;
                input = this.template.querySelector(".cc-input");

            } else if(event.detail.type == "bcc") {
                    this.bccAddress = address;
                input = this.template.querySelector(".bcc-input");
            }
            console.log(input);
            input.updateValues(address);
        }

        this.toContactSelectModal = false;

        this.ccContactSelectModal = false;

        this.bccContactSelectModal = false;
    }
    handleToAddressChange(event) {
        console.log(event.detail.selectedValues);
        this.toAddress = event.detail.selectedValues;
    }

    handleCcAddressChange(event) {
        this.ccAddress = event.detail.selectedValues;
    }

    handleBccAddressChange(event) {
        this.bccAddress = event.detail.selectedValues;
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }

    validateEmails(emailAddressList) {
        let areEmailsValid;
        if(emailAddressList.length > 1) {
            areEmailsValid = emailAddressList.reduce((accumulator, next) => {
                const isValid = this.validateEmail(next);
                return accumulator && isValid;
            });
        }
        else if(emailAddressList.length > 0) {
            areEmailsValid = this.validateEmail(emailAddressList[0]);
        }
        return areEmailsValid;
    }

    validateEmail(email) {
        const res = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        console.log("res", res);
        return res.test(String(email).toLowerCase());
    }

    handleSendEmail() {
        
        this.noEmailError = false;
        this.invalidEmails = false;
        this.isLoaded = true;
        if (![...this.toAddress, ...this.ccAddress, ...this.bccAddress].length > 0) {
            this.noEmailError = true;
            return;
        }
        
        if (!this.validateEmails([...this.toAddress, ...this.ccAddress, ...this.bccAddress])) {
            this.invalidEmails = true;
            return;
        }
        console.log(this.body);
        const regex = /<p>(.*?)\<\/p>/g;

        // this.body = this.body.replaceAll('<p>','');
        this.body = this.body.replaceAll('<br>','');
        // this.body = this.body.replaceAll('</p>','<br/>');
        // this.body = this.body.replaceAll('<p>(.*?)\<\/p></p>','<br/>');
        this.body = this.body.replaceAll(regex, "$1<br>");
        
        // this.body = this.body.replaceAll('<p><br></p>','');
        
        console.log(this.body);
        let emailDetails = {
            orgId: this.fromAddressId,
            toAddress: this.toAddress,
            ccAddress: this.ccAddress,
            bccAddress: this.bccAddress,
            subject: this.subject,
            body: this.body,
        };
        console.log("@@fileIDs "+ JSON.stringify(this.fileIDs));
        sendEmailController({ emailDetailStr: JSON.stringify(emailDetails) , lstFileIDs : this.fileIDs , idMainRecord : this.recordId})
        .then(() => {
            this.isLoaded = false;
            console.log('email sent success' + JSON.stringify(emailDetails));
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Email Sent!',
                    message: 'Email has been successfully sent.',
                    variant: 'success'
                })
                );
        })
        .catch((error) => {
            this.isLoaded = false;
            console.error("Error in CM_CustomSendEmailController:", error);
        });
        

    }
    handleSelectAttachment(){
        this.template.querySelector("c-c-m-_-email-attachment-component").openFileUpload();
    }
    handleAttachment(event){
        this.uploadedFileList = event.detail;
        console.log('@@Files Recieved: ' + JSON.stringify(event.detail));
        let tempIds = [];
        event.detail.forEach(file => {
            tempIds.push(file.id);
        })
        this.fileIDs = tempIds;
    }

    /**
     * @description Method to show modal for Email template selection
     */
    handleInsertEmailTemplate(){
        this.template.querySelector("c-c-m-_-email-template-select-component").openEmailTemplateSelector();
    }

    /**
     * @description method to set selected Template and update the Email Body accordingly
     * @param event - to track the details of event triggered from child component "emailTemplateSelectComponent"
     */
    setEmailTemplate(event) {
        this.body = '';
        this.subject = '';

        if(event.detail !== '') {
            this.isLoaded = true;
            this.selectedEmailTemplate = event.detail;
            this.createEmailBody(event.detail);
        }
    }

    /**
     * @description method to render Email Subject and Email body based on the selected Outer and Inner email templates for the selected Contacts / Accounts
     */
     createEmailBody(selectedEmailTemplate) {

        fetchEmailBody({
            recordId: this.recordId,
            emailTemplateId: selectedEmailTemplate,
            objectType: this._objectType
        })
        .then(result => {
            this.isLoaded = false;
            this.subject = result.etSubject;
            this.body = result.etBody;
            console.log(this.body);
            this.template.querySelector('lightning-input-rich-text').focus();
            // const editor = this.template.querySelector('lightning-input-rich-text');
            // const textToInsert = result.etBody;
            // editor.setRangeText(textToInsert, undefined, undefined, 'select');
        })
        .catch((errors) => {
            this.isLoaded = false;
            let error = ((JSON.stringify(errors.body)).split("message\":\""));
            error = error[error.length - 1].split("\"")[0];
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Please try again',
                    message: 'Email templates are still loading. Please try again!',
                    variant: 'warning'
                })
                );
        });
        
    }   

    /**
     * @description method to preview email screen
     */
    handleEmailPreview(){
        this.template.querySelector("c-c-m-_-email-preview-component").previewEmail(this.fromAddress, this.uploadedFileList);
    }

        /**
     * @description getter() to disable "Send" button if either toAddresses list is blank or email subject is blank or email body is blank
     */
        get handleWhenNoToEmailAdded() {
        if(this.toAddress.length && this.subject && this.body) {
            return false;
        }
        else {
            return true;
        }
    }

}