/*
 * @author : Innovior - Sid, Bowen
 * @description : Controller for Custom Email LWC
 *
*/

public class CM_CustomSendEmailController {

    // static final String INVOICE_OBJECT_NAME = 'CM_Invoice__c';
    static final String CASE_OBJECT_NAME = 'Case';
    /**
    * @description: delete attachement file from salesforce
    * @param idMainRecord - Id, Linked Entity Id - Case Id.
    * @param strFileRecord - String, File Id.
    * @return N/A
    */
    @AuraEnabled
    public static void deleteAttachmentFile(Id idMainRecord, String strFileRecord){
        /*
        try {
            List<ContentDocumentLink> lstContentDocuLink = [SELECT Id, ContentDocumentId
                                                            FROM ContentDocumentLink
                                                            WHERE LinkedEntityId =: idMainRecord
                                                            AND ContentDocumentId =: strFileRecord];
            system.debug('@@ lstContentDocuLink: '+lstContentDocuLink);

            if(!lstContentDocuLink.isEmpty()){
                delete lstContentDocuLink;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        */
    }

    /**
    * @description: fectch Lightning email templates for CareCo from salesforce
    * @return List of Lightning email templates wrap in OptionWrap.
    */
    @AuraEnabled(cacheable = true)
    public static List<OptionWrap> fetchEmailTemplate(){
        /*
        System.debug('@@ Controller');
        Final String strRemedyFolderName = 'CareCo Remedy Healthcare Email Templates';
        Final String strRamsayFolderName = 'CareCo Ramsay Connect Email Templates';
        List<OptionWrap> lstEmailTempOptions = new List<OptionWrap>();
        try {

            List<Folder> lstFolder = [SELECT Id,
                                             Name
                                      FROM Folder
                                      WHERE (Name = :strRemedyFolderName
                                      OR Name = :strRamsayFolderName)];
            System.debug('@@ lstFolder: '+lstFolder);
            for(EmailTemplate emailTemp: [SELECT Id,Name FROM EmailTemplate WHERE FolderId IN: lstFolder])
            {
                OptionWrap optWrap = new OptionWrap();
                optWrap.label = emailTemp.Name;
                optWrap.value = emailTemp.Id;
                lstEmailTempOptions.add(optWrap);
            }
            System.debug('@@ lstEmTplte: '+lstEmailTempOptions);

            return lstEmailTempOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        */
        return new List<OptionWrap>();
    }

    /**
    * @description: controller for sending email 
    * @param emailDetailStr - String, Contains email details - FROM, TO, CC, BCC, ATTACHMENT, SUBJECT, BODY
    * @param lstFileIDs - List<Id>, File Ids to be attached as attachments
    * @param idMainRecord - Id, Case Id
    * @return N/A
    */
    @AuraEnabled
    public static void sendEmailController(String emailDetailStr, list<id> lstFileIDs, Id idMainRecord) {
        EmailWrapper emailDetails = new EmailWrapper();
        try{
            emailDetails = (EmailWrapper) json.deserialize(emailDetailStr, EmailWrapper.class);
        } catch (exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        List<Messaging.EmailFileAttachment> emailFileAttList = getEmailAttachments(idMainRecord, lstFileIDs);

        try {
            messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
                mail.setToAddresses(emailDetails.toAddress);
                mail.setCcAddresses(emailDetails.ccAddress);
                mail.setBccAddresses(emailDetails.bccAddress);
                mail.setOrgWideEmailAddressId(emailDetails.OrgId);
                if(emailFileAttList.size() > 0) {
                    mail.setFileAttachments(emailFileAttList);   
                }
                mail.setSubject(emailDetails.subject);
                mail.setHtmlBody(emailDetails.body);
                mail.setWhatId(idMainRecord);               // to associate email to record
            Messaging.sendEmail(new List<messaging.SingleEmailMessage>{ mail });
        } catch (exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description: Get all files related to Case and related service requests
    *  This is an enhancement to include files generated from Gen Templates for Case and Service Request
    * @param caseId - Id, Case Id
    * @return Map<String, List<RelatedFilesWrap>> 
    *  Key: Case/Service Request
    *  Value: List of Files warpped in RelatedFiles Wrap
    */
    @AuraEnabled(cacheable = true)
    public static Map<String, List<RelatedFilesWrap>> getAllRelatedFiles(Id idMainRecord, String objectType){
        Map<String, List<RelatedFilesWrap>> allRelatedFilesMap = new Map<String, List<RelatedFilesWrap>>();

        // get case related files
        List<Id> recordIds = new List<Id>{idMainRecord};
        allRelatedFilesMap.put(objectType, getRelatedFiles(recordIds));

        /**
        *   Optional: turn on to get linked objects related files
        *
        // get service request related files
        List<CM_Service_Request__c> serviceRequestRecords = [SELECT Id 
                                                             FROM 	CM_Service_Request__c 
                                                             WHERE 	CM_Case__c = :caseId];
        List<Id> serviceRequestRecordId = new List<Id>();
        for(CM_Service_Request__c sr : serviceRequestRecords){
            serviceRequestRecordId.add(sr.Id);
        }
        List<RelatedFilesWrap> serviceRequestFiles = getRelatedFiles(serviceRequestRecordId);
        If(serviceRequestFiles.size() > 0){
            allRelatedFilesMap.put('Service Request', serviceRequestFiles);
        }
        */

        return allRelatedFilesMap;
    }

    /**
    * @description: Helper function of getAllRelatedFiles()
    *   get a list of related files given the list of linked record Ids
    * @param lstRecordId - List<Id>, Case Id or Service Request Ids
    * @return List<RelatedFilesWrap> List of Files warpped in RelatedFiles Wrap
    */
    private static List<RelatedFilesWrap> getRelatedFiles(List<Id> lstRecordId) {
        List<RelatedFilesWrap> lstRelatedFiles = new List<RelatedFilesWrap>();

        If(lstRecordId.size() > 0){
            // Get related file Titles and IDs        
            List<ContentDocumentLink> files = [SELECT 	ContentDocumentId 
                                               FROM 	ContentDocumentLink 
                                               WHERE 	LinkedEntityId IN :lstRecordId];
            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink docLink : files) {
                fileIDs.add(docLink.ContentDocumentId);
            }
    
            List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title, CreatedDate, ContentSize
                FROM ContentVersion WHERE ContentDocumentId IN : fileIDs AND isLatest = true ORDER BY CreatedDate DESC];

            for (ContentVersion docLink : docs) {
                RelatedFilesWrap file = new RelatedFilesWrap();
                String formattedCreatedDate = docLink.CreatedDate.format('dd-MM-yyyy HH:mm a');
                file.label = docLink.Title + '\n' + formattedCreatedDate + ' | ' + docLink.FileExtension + ' | ' + fileSizeToString(docLink.ContentSize);
                file.id = docLink.ContentDocumentId; 
                file.createdDate = docLink.CreatedDate;
                lstRelatedFiles.add(file);
            }
        }
         return lstRelatedFiles;
    }
    
    /**
    * @description: helper function to format file size
    * @param value - Long, File size in Byte
    * @return String, File size in text
    */
    private static String fileSizeToString(Long value) {
        /* string representation if a file's size, such as 2 KB, 4.1 MB, etc */
        /*
        if (value < 1024){
          return string.valueOf(value) + ' Bytes';
        }
        else
        if (value >= 1024 && value < (1024*1024))
        {
          //KB
          Decimal kb = Decimal.valueOf(value);
          kb = kb.divide(1024,2);
          return string.valueOf(kb) + ' KB';
        }
        else
        if (value >= (1024*1024) && value < (1024*1024*1024))
        {
          //MB
          Decimal mb = Decimal.valueOf(value);
          mb = mb.divide((1024*1024),2);
          return string.valueOf(mb) + ' MB';
        }
        else
        {
          //GB
          Decimal gb = Decimal.valueOf(value);
          gb = gb.divide((1024*1024*1024),2);
         
          return string.valueOf(gb) + ' GB';
        }    
        */
        return '10 MB';
    }

    /**
    * @description: get all files attached to this email
    * @param idMainRecord - Id, Case Id
    * @param lstFileIDs - List<Id>, List of file Ids
    * @return List<Messaging.EmailFileAttachment>, List of email attachments
    */
    public static List<Messaging.EmailFileAttachment> getEmailAttachments(Id idMainRecord, List<Id> lstFileIDs){
        List<Messaging.EmailFileAttachment> lstEmailFileAttachment = new List<Messaging.EmailFileAttachment>();
        List<ContentDocumentLink> lstContentDocuLink = [SELECT 	ContentDocumentId
                                                        FROM 	ContentDocumentLink
                                                        WHERE 	LinkedEntityId =: idMainRecord
                                                        	AND ContentDocumentId IN: lstFileIDs];
        System.debug('@@ lstContentDocuLink: '+lstContentDocuLink);

        List<Id> lstContentDocuId = new List <Id> ();
        
        for (ContentDocumentLink nextCDL : lstContentDocuLink) {
            lstContentDocuId.add(nextCDL.ContentDocumentId); 
        }
        System.debug('@@ lstContentDocuId: '+lstContentDocuId);

        if(lstContentDocuId.size() > 0) {
            List<ContentVersion> lstContentVersion = [SELECT Id,
                                                             title,
                                                             VersionData,
                                                             FileExtension,
                                                             ContentDocumentId 
                                                      FROM ContentVersion 
                                                      WHERE ContentDocumentId IN: lstContentDocuId 
                                                      AND isLatest = true];
            System.debug('@@ lstContentVersion: '+lstContentVersion);
            for(ContentVersion cvObj : lstContentVersion) {
                lstEmailFileAttachment.add(setEmailFileAtt(cvObj));       
            }
        }

        return lstEmailFileAttachment;
    }

    /**
    * @description: helper function of getEmailAttachments
    * @param cvObj - ContentVersion, File Object
    * @return Messaging.EmailFileAttachment, converted email attachments object for sending
    */
    private static Messaging.EmailFileAttachment setEmailFileAtt(ContentVersion cvObj) {
        Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
            Blob fileData = cvObj.VersionData;
            emlAtt.setFilename(cvObj.title+'.'+cvObj.FileExtension);
            emlAtt.setBody(fileData);
        return emlAtt;
    }

    /**
    * @description: Get From Email Address from OrgWideAddress and the OrgWideAddress metadata
        Create metadata CM_Org_Wide_Address__mdt to store a list of valid email address for filterring purpose
        In the example below, the valid email addresses depends on the Case.RecordType.Name
    * @param recordId - String, Case Id
    * @return List<OrgWideEmailAddress>, A list of valid from email addresses in Org Wide Email Address List as the sender email address
    */
    @AuraEnabled(cacheable = true)
    public static List<OrgWideEmailAddress> getFromEmailAddress(String recordId, String objectType){

        /*
        try {
            String caseId = recordId;
            
            List<Case> myCase = [SELECT  Id, 
                                     RecordType.Name, 
                                     CM_Program_Type__c 
                                 FROM    Case 
                                 WHERE Id = :caseId LIMIT 1];
            List<OrgWideEmailAddress> addresses = [SELECT  ID, 
                                                           Address, 
                                                           DisplayName 
                                                   FROM    OrgWideEmailAddress];
            List<CM_Org_Wide_Address__mdt> metaAddresses = [SELECT  Id, 
                                                                    CM_Case_Type__c, 
                                                                    CM_Email_Address__c 
            												FROM CM_Org_Wide_Address__mdt];
            Set<OrgWideEmailAddress> resultSet = new Set<OrgWideEmailAddress>();
            List<OrgWideEmailAddress> result = new List<OrgWideEmailAddress>();

            // filter for emails only in metadata 
            if(!myCase.isEmpty()){
                for(OrgWideEmailAddress address : addresses) {
                    for(CM_Org_Wide_Address__mdt metaAddress : metaAddresses ) {
                        if (address.Address == metaAddress.CM_Email_Address__c 
                            && metaAddress.CM_Case_Type__c == myCase[0].RecordType.Name) {
                                resultSet.add(address);
                            }
                    }
                }
            }
            
            if( resultSet != null) {
                result.addAll(resultSet);
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(recordId + e.getMessage() );
        }
        */
        return new List<OrgWideEmailAddress>();
    }

    /**
    * @description: Get Default From Email Address from OrgWideAddress and the OrgWideAddress metadata
        This email address will display as the first/default email address in the From: dropdown
    * @param recordId - String, Case Id
    * @return OrgWideEmailAddress, get the default from addresses to send the email
    */
    @AuraEnabled(cacheable = true)
    public static OrgWideEmailAddress getDefaultFromEmailAddress(String recordId, String objectType){
        /*
        try {
            String caseId = recordId;
            if(objectType == INVOICE_OBJECT_NAME){
                List<CM_Invoice__c> myInvoice = [SELECT  Id,
                                                CM_Case__c
                                            FROM CM_Invoice__c
                                            WHERE Id = :recordId LIMIT 1];
                if(!myInvoice.isEmpty()){
                    caseId = Id.valueOf(myInvoice[0].CM_Case__c);
                }
            }

            Case myCase = [SELECT  	Id, 
                                    RecordType.Name, 
                                    CM_Program_Type__c 
                           FROM 	Case 
                           WHERE Id = :caseId LIMIT 1];
            List<OrgWideEmailAddress> addresses = getFromEmailAddress(recordId, objectType);
            List<CM_Org_Wide_Address__mdt> metaAddresses = [SELECT Id, CM_Case_Type__c, 
                                                            		CM_Program_Type__c, CM_Email_Address__c 
            												FROM 	CM_Org_Wide_Address__mdt];
            
            // find the default email address
            if(!addresses.isEmpty() && !metaAddresses.isEmpty()){
                for(OrgWideEmailAddress address : addresses) {
                    for(CM_Org_Wide_Address__mdt metaAddress : metaAddresses ) {
                        if (address.Address == metaAddress.CM_Email_Address__c 
                            && metaAddress.CM_Case_Type__c == myCase.RecordType.Name
                            && metaAddress.CM_Program_Type__c == myCase.CM_Program_Type__c) {
                                return address;
                            }
                    }
                }   
            }

            return null;
        } catch (Exception e) {
            throw new AuraHandledException(recordId + e.getMessage());
        }
        */
        return null;
    }

    /**
    * @description: Limit Recipient Email Address only for related contacts from Case
    * @param idMainRecord - String, Case Id
    * @return Map<String, List<ContactInfoWrapper>>, A Map for a list of available contacts
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<ContactInfoWrapper>> getContactEmails(String idMainRecord, String objectType){
        Map<String, List<ContactInfoWrapper>> mapContactInfoByObject = new Map<String, List<ContactInfoWrapper>>();
        /*
        if(objectType == CASE_OBJECT_NAME){
            getCaseContactEmails(idMainRecord, mapContactInfoByObject);

            getServiceProviderContactEmails(idMainRecord, mapContactInfoByObject);

        } else if(objectType == INVOICE_OBJECT_NAME){
            getFunderContactEmails(idMainRecord, mapContactInfoByObject);
        }
        */
        return mapContactInfoByObject;
    }
    
    /**
    * @description: Limit To Email Address only for related contacts from Case
    * @param idMainRecord - String, Case Id
    * @param mapContactInfoByObject - List<ContactInfoWrapper>>, Contact map
    * @return N/A
    */
    private static void getCaseContactEmails(String idMainRecord , Map<String, List<ContactInfoWrapper>> mapContactInfoByObject) {
/*
        Final String strCaseObjectName = 'Case';

        List<Case> lstMainRecordCase = [SELECT Id, ContactId, CM_Referrer__c, CM_GP__c, CM_Specialist__c, CM_Funder__c,
                                               Contact.Name, Contact.Email,Contact.Title,
                                               CM_Referrer__r.Name, CM_Referrer__r.Email,CM_Referrer__r.Title,
                                               CM_GP__r.Name, CM_GP__r.Email,CM_GP__r.Title,
                                               CM_Specialist__r.Name, CM_Specialist__r.Email,CM_Specialist__r.Title,
                                               CM_Funder__r.CM_Account_Name__c, CM_Funder__r.CM_Accounts_Email_Address__c
                                        FROM Case
                                        WHERE Id =: idMainRecord];

        System.debug('@@ lstMainRecordCase: '+lstMainRecordCase);

        for(Case cse : lstMainRecordCase){

            if (!mapContactInfoByObject.containsKey(strCaseObjectName)) {
                mapContactInfoByObject.put(strCaseObjectName, new List<ContactInfoWrapper>());
            }

            if(cse.ContactId != null){
                

                ContactInfoWrapper contactWrapper = getContactInfo(cse.Contact.Email, cse.Contact.Name, cse.Contact.Title);

                mapContactInfoByObject.get(strCaseObjectName).add(contactWrapper);

            }
            if(cse.CM_Referrer__c != null){

                ContactInfoWrapper referrerWrapper = getContactInfo(cse.CM_Referrer__r.Email, cse.CM_Referrer__r.Name, cse.CM_Referrer__r.Title);

                mapContactInfoByObject.get(strCaseObjectName).add(referrerWrapper);

            }
            if(cse.CM_Specialist__c != null){

                ContactInfoWrapper specialistWrapper = getContactInfo(cse.CM_Specialist__r.Email, cse.CM_Specialist__r.Name, cse.CM_Specialist__r.Title);

                mapContactInfoByObject.get(strCaseObjectName).add(specialistWrapper);
      
            }
            if(cse.CM_GP__c != null){
    
                ContactInfoWrapper gpWrapper = getContactInfo(cse.CM_GP__r.Email, cse.CM_GP__r.Name, cse.CM_GP__r.Title);

                mapContactInfoByObject.get(strCaseObjectName).add(gpWrapper);
 
            }
            if(cse.CM_Funder__c != null){
    
                ContactInfoWrapper funderWrapper = getContactInfo(cse.CM_Funder__r.CM_Accounts_Email_Address__c, cse.CM_Funder__r.CM_Account_Name__c, 'Funder Accounts');

                mapContactInfoByObject.get(strCaseObjectName).add(funderWrapper);
 
            }
        }
        System.debug('@@ Case: mapContactInfoByObject: '+mapContactInfoByObject);
        */
    }

    /**
    * @description: Limit To Email Address only for related contacts from Case.Service Providers
    * @param idMainRecord - String, Case Id
    * @param mapContactInfoByObject - List<ContactInfoWrapper>>, Contact map
    * @return N/A
    */
    private static void getServiceProviderContactEmails(String idMainRecord, Map<String, List<ContactInfoWrapper>> mapContactInfoByObject) {
        /*
        //Final String strServiceProviderObjectName = 'CM_Care_Plan_Service__c';
        Final String strServiceProviderDisplayName = 'Care Plan Service Providers';
        List<Id> processedIds = new List<Id>();
        List<CM_Care_Plan_Service__c> lstCarePlanServices = [SELECT Id, 
                                                                    CM_Service_Provider_Contact__c, 
                                                                    CM_Service_Provider_Contact__r.Name,
                                                                    CM_Service_Provider_Contact__r.Email,
                                                                    CM_Service_Provider_Contact__r.Title
                                                            FROM CM_Care_Plan_Service__c
                                                            WHERE CM_Case__c =: idMainRecord];

        

        for(CM_Care_Plan_Service__c cps : lstCarePlanServices){
            if (!mapContactInfoByObject.containsKey(strServiceProviderDisplayName)) {
                mapContactInfoByObject.put(strServiceProviderDisplayName, new List<ContactInfoWrapper>());
            }
            if(cps.CM_Service_Provider_Contact__c != null) {
                if(!processedIds.contains(cps.CM_Service_Provider_Contact__c)){
                        ContactInfoWrapper serviceProviderWrapper = getContactInfo(cps.CM_Service_Provider_Contact__r.Email, cps.CM_Service_Provider_Contact__r.Name, 
                        cps.CM_Service_Provider_Contact__r.Title);
                    mapContactInfoByObject.get(strServiceProviderDisplayName).add(serviceProviderWrapper);
                    processedIds.add(cps.CM_Service_Provider_Contact__c);
                }
            }
        }
        System.debug('@@ Care Plan Service Providers: mapContactInfoByObject: '+mapContactInfoByObject);
        */
    }

    /**
    * @description: Limit To Email Address only for related contacts from Case.Service Providers
    * @param idMainRecord - String, Case Id
    * @param mapContactInfoByObject - List<ContactInfoWrapper>>, Contact map
    * @return N/A
    */
    private static void getFunderContactEmails(String idMainRecord, Map<String, List<ContactInfoWrapper>> mapContactInfoByObject) {
        /*
        Final String strFunderDisplayName = 'Funder';
        String caseId = '';
        List<CM_Invoice__c> myInvoice = [SELECT  Id,
                                                CM_Case__c
                                            FROM CM_Invoice__c
                                            WHERE Id = :idMainRecord LIMIT 1];
        if(!myInvoice.isEmpty()){
            caseId = Id.valueOf(myInvoice[0].CM_Case__c);
        }

        List<Case> lstMainRecordCase = [SELECT Id, CM_Funder__c,
        CM_Funder__r.CM_Account_Name__c, CM_Funder__r.CM_Accounts_Email_Address__c
        FROM Case
        WHERE Id =: caseId];

        for(Case cse : lstMainRecordCase){

            if (!mapContactInfoByObject.containsKey(strFunderDisplayName)) {
                mapContactInfoByObject.put(strFunderDisplayName, new List<ContactInfoWrapper>());
            }

            if(cse.CM_Funder__c != null){
    
                ContactInfoWrapper funderWrapper = getContactInfo(cse.CM_Funder__r.CM_Accounts_Email_Address__c, cse.CM_Funder__r.CM_Account_Name__c, 'Funder Accounts');

                mapContactInfoByObject.get(strFunderDisplayName).add(funderWrapper);
 
            }
        }
        System.debug('@@ Case: mapContactInfoByObject: '+mapContactInfoByObject);
        */

    }

    /**
    * @description: Apply Lightning Email templates
    * @param caseId - String, Case Id or Invoice Id
    * @param emailTemplateId - Email template selected id.
    * @return EmailTemplateWrap - EmailTemplateWrap record with rendered template body
    */
    @AuraEnabled
    public static EmailTemplateWrap fetchEmailBody(String recordId, String emailTemplateId, String objectType) {
        /*
        if(objectType == INVOICE_OBJECT_NAME){
            List<CM_Invoice__c> myInvoice = [SELECT  Id,
                                            CM_Case__c
                                        FROM CM_Invoice__c
                                        WHERE Id = :recordId LIMIT 1];
            if(!myInvoice.isEmpty()){
                recordId = Id.valueOf(myInvoice[0].CM_Case__c);
            }
        }
        */

        /*
        EmailTemplateWrap etWrap = new EmailTemplateWrap();
        
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplateId, null, recordId);
        etWrap.etSubject = email.getSubject();
        etWrap.etBody = email.getHtmlBody();

        return etWrap;
        */
        return null;
    }

    
    /**
    * @description get Object Name given an Object ID - get the object where the custom email is orginated from 
    * @param recordIdOrPrefix - String, record ID or prefix - first 3 digits
    * @return String - Object Name 
    */
    @AuraEnabled(cacheable = true)
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
             
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){

                //if (!sObj.contains('__')) to exclude managed package objects

                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                 
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;

    }

  
    /**
    *******************************************************************************
    * @description: get contact info 
    * @param strContactName - String, Contact name
    * @param strContactEmail - String, Contact email
    * @param strContactTitle - String, Contact Title
    * @return ContactInfoWrapper - ContactInfoWrapper record
    *******************************************************************************
    */
    public static ContactInfoWrapper getContactInfo(String strContactName, String strContactEmail, String strContactTitle){
        ContactInfoWrapper wrapper = new ContactInfoWrapper();
            wrapper.strEmail = strContactName;
            wrapper.strName = strContactEmail;
            wrapper.strTitle = strContactTitle;
        return wrapper;
    }

    /**
    *******************************************************************************
    * @description Contains all the attributes to be shown on the limited receipient contacts
    *******************************************************************************
    */
    public Class ContactInfoWrapper{
        @AuraEnabled public String strEmail { get; set; }
        @AuraEnabled public String strName { get; set; }
        @AuraEnabled public String strTitle { get; set; }
    }
    /**
    *******************************************************************************
    * @description Contains all the attributes for the email details
    *******************************************************************************
    */
    Class EmailWrapper {
        public List<String> toAddress;
        public List<String> ccAddress;
        public List<String> bccAddress;
        public String subject;
        public String body;
        public String plainTextBody;
        public List<String> files;
        public Id orgId {get; set { orgId = Id.valueOf(value); }}
    }
    /**
    *******************************************************************************
    * @description Contains all the attributes to be shown on front End For Send Email Component
    *******************************************************************************
    */
    public class EmailTemplateWrap {
        @AuraEnabled public String etSubject {get; set;}
        @AuraEnabled public String etBody {get; set;}
    }

    /**
    *******************************************************************************
    * @description Wrapper class to store option data
    *******************************************************************************
    */
    public class OptionWrap {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}
    }

    /**
    *******************************************************************************
    * @description Wrapper class to store related files for attachement
    *******************************************************************************
    */
    public class RelatedFilesWrap {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public Datetime createdDate {get;set;}
    }

    
}