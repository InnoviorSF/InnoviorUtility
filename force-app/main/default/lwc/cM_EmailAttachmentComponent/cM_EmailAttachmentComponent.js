/**
 *******************************************************************************
 * @description JS Controller for fileUploadLComponent LWC component
 * @author Sumit Agrawal, Bowen Li
 * @date 2022-10-10
 * @comment Bowen Li modified on 26/10/2022
 *******************************************************************************
 */
 import { LightningElement, api, track } from 'lwc';
 import {ShowToastEvent} from 'lightning/platformShowToastEvent';
 import deleteAttachmentFile from "@salesforce/apex/CM_CustomSendEmailController.deleteAttachmentFile";
 import { NavigationMixin } from "lightning/navigation";
 

 export default class CM_EmailAttachmentComponent extends NavigationMixin(LightningElement) {
   @track filesList = [];
   @track attachmentList = [];
   @track selectedRows = [];
   @track selectedRowsDisplay = [];
   @track selectedNumber = 0;
   @track totalNumber = 0;
   fileData = [];
   fileIds = [];
   showModal = false;
   relatedFilesDataMap = new Map();
   sortedBy = 'createdDate';
   sortedDirection = 'desc';
   @api recordId = '';
   @api openFileUpload() {
     this.showModal = true;
   }

   // accepted parameters
   get acceptedFormats() {
     return ".pdf, .png, .jpg, .jpeg, .doc, .docx";
   }

   @api
   get relatedFilesMap() {
     return this.relatedFilesDataMap;
   }
   set relatedFilesMap(value) {
     this.relatedFilesDataMap = value;
      value.forEach(item => {this.totalNumber += item.value.length});
   }


   @track columns = [
    {  fieldName: "label", wrapText: true, hideLabel: true},

    {   type: 'button-icon', 
        typeAttributes:
        {
            iconName: 'action:preview',
            class: 'slds-align_absolute-center',
            alternativeText: 'preview'
        }
    }
   ];

    handleUploadFinished(event) {
        let filesList = event.detail.files;
        console.log(JSON.stringify(filesList));
        for (let i = 0; i < filesList.length; i++) {
          this.filesList.push({
            index: this.filesList.length,
            file: filesList[i],
            filename: filesList[i].name,
            id: filesList[i].documentId,
          });
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
            recordIds: event.detail.row.id,
            selectedRecordId: event.detail.row.id
          }
        });
      }

    handleRemove(event) {
        let index = event.currentTarget.name;
        this.filesList.splice(index, 1);

        for (let i = 0; i < this.filesList.length; i++) {
            this.filesList[i].index = i;
        }
        if(event.currentTarget.fileid) {
            deleteAttachmentFile({idMainRecord : this.recordId, strFileRecord : event.currentTarget.fileid})
            .then(() => {
                console.log('Attachment has been deleted');
            })
            .catch((error) => {
                console.error("Error in CM_CustomSendEmailController:", error);
            });
        }   
    }

    handleSelectRows(event) {
        let currentRows = event.detail.selectedRows;
        console.log('@@current rows: ' + JSON.stringify(currentRows));
        this.selectedNumber = currentRows.length;
        if(currentRows.length>0){
        this.selectedRowsDisplay = currentRows.map(row => row.id);
        } else {
            this.selectedRowsDisplay = [];
        }
    }
   handleAttach() {

        let filesTables = this.template.querySelectorAll("lightning-datatable");
        this.attachmentList = [];
        this.selectedRows = [];
        filesTables.forEach(table => {
            var selectedRecords =  table.getSelectedRows();
            if(selectedRecords.length > 0){
                console.log('selectedRecords are ', selectedRecords);

                selectedRecords.forEach(currentItem => {
                    console.log('@@currentRecord: ' + JSON.stringify(currentItem));
                    let currentFileName = currentItem.label.split("\n")[0] + '.' + currentItem.label.split("|")[1];
                    this.attachmentList.push({
                        file: currentItem,
                        filename: currentFileName,
                        id: currentItem.id,
                    });

                    this.selectedRows.push(currentItem.id);

                });
                

            }   
        });

        console.log('@@File Sent: ' + JSON.stringify([...this.filesList, ...this.attachmentList]));
        const newEvent = new CustomEvent("attachfile", {
            detail: [...this.filesList, ...this.attachmentList],
        });

     
        this.dispatchEvent(newEvent);
        this.closeModal();
   }

   handleCancel() {
    this.selectedRowsDisplay = this.selectedRows;
    this.selectedNumber = this.selectedRows.length;
     this.closeModal();
   }
   /**
    * @description method to show- toast when server response is received or any event happens
    * @param type - type of message either "Success", or "Error" or "Warning" or "Info"
    * @param toastMessage - message to be shown on toast
    */
   showToastMessage(type, toastMessage) {
     const event = new ShowToastEvent({
       message: toastMessage,
       variant: type,
     });

     this.dispatchEvent(event);
   }

   closeModal() {
     this.showModal = false;
   }

   get attacheLabel() {
    let allList = [...this.filesList, ...this.selectedRowsDisplay];
    return allList.length > 0 ? "Attach " + "(" + allList.length + ")" : "Attach";
   }

   get cancelLabel() {
     return "Cancel";
   }
 }