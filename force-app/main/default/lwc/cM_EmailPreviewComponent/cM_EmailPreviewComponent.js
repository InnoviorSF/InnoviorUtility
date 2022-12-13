import { LightningElement, api } from 'lwc';

export default class EmailPreviewComponent extends LightningElement {
    @api toAddresses;
    @api bccAddresses;
    @api ccAddresses;
    @api subject;
    @api body;
    uploadedFileList=[];
    fromAddress;
    showModal = false;

    @api previewEmail(fromAddress, uploadedFileList){
        this.fromAddress = fromAddress;
        this.uploadedFileList = uploadedFileList;
        this.showModal = true;
    }

    get toAddress(){
        let toEmailAddresses = [];

        this.toAddresses.forEach(function(obj) {
            toEmailAddresses.push(obj);
        });
        return toEmailAddresses.length > 0 ? toEmailAddresses.join('; ') : '';
    }

    get ccAddress(){
        let ccEmailAddresses = [];

        this.ccAddresses.forEach(function(obj) {
            ccEmailAddresses.push(obj);
        });

        return ccEmailAddresses.length > 0 ? ccEmailAddresses.join('; ') : '';
    }

    get bccAddress(){
        let bccEmailAddresses = [];

        this.bccAddresses.forEach(function(obj) {
            bccEmailAddresses.push(obj);
        });
        return bccEmailAddresses.length > 0 ? bccEmailAddresses.join('; ') : '';
    }

    closeModal(){
        this.showModal = false;
    }
}