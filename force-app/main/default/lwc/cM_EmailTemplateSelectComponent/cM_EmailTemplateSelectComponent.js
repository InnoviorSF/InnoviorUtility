/**
 *******************************************************************************
 * @description JS Controller for emailTemplateSelectComponent LWC component
 * @author Sumit Agrawal
 * @date 2022-10-06
 * @comment Bowen Li modified on 26/10/2022
 *******************************************************************************
 */
import { LightningElement, api, track } from 'lwc';

export default class CM_EmailTemplateSelectComponent extends LightningElement {
    @api templateType = '';
    @api selectedTemplate;
    @api templateOptions;
    @api showModal = false;
    @track selectedEmailTemplate;
    
    @api openEmailTemplateSelector(){
        this.showModal = true;
    }

    /**
     * @description method to find out which Email Template has been selected from the given list of templates
     * @param event - to track the details of event triggered
     */
    handleTemplateSelect(event) {
        this.selectedEmailTemplate = event.target.value;

        const newEvent = new CustomEvent('selectedtemplate', {
            detail: this.selectedEmailTemplate
        });

        this.closeModal();
        this.dispatchEvent(newEvent);
    }

    closeModal(){
        this.showModal = false;
    }
}