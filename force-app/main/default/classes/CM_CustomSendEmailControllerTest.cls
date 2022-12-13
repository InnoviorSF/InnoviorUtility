/*
 * @author : Innovior - Bowen Li, Sid
 * @description : Test class for CM_CustomSendEmailController class
 *
*/


@isTest
public class CM_CustomSendEmailControllerTest {
    private static Account hospitalAccount;
    private static Account householdAccount;
    private static Contact carecoReferrerContact;
    private static Contact carecoClientContact;
    private static Case ramsayCase;
    private static EmailTemplate emailTemplate;
    private static Product2 serviceProduct;
    private static Document docFile;
    private static Folder emailTemplatefolder;
    private static Folder docFolder;
    private static ContentVersion conentVersion;
    private static ContentDocumentLink contentDocumentLink;

    static final String INVOICE_OBJECT = 'CM_Invoice__c';
    static final String CASE_OBJECT = 'Case';
    

    @testSetup
    static void setup(){
        createCareCoHospitalAccount();
        createCareCoHouseholdAccount();
        createCareCoReferrerContact();
        createCareCoClientContact();
        // queryEmailTemplateFolder();
        // queryDocumentFolder();
        // createDocumentFile();
        createServiceProduct();
        createRamsayCase();
        // createFiles();
    }

    // create test hospital account
    private static void createCareCoHospitalAccount(){
        Account acc = new Account();
            // acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CM_Hospital').getRecordTypeId();
            acc.Name = 'CareCo Hospital Account';
        insert acc;
        
        hospitalAccount = acc;
    }

    // create test household account
    private static void createCareCoHouseholdAccount(){
        Account acc = new Account();
            // acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('CM_Household_Account').getRecordTypeId();
            acc.Name = 'CareCo Household Account';
        insert acc;
        
        householdAccount = acc;
    }

    // create test careco contact
    private static void createCareCoReferrerContact(){
        Contact con = new Contact();
            // con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CM_Contact').getRecordTypeId();
            con.Firstname = 'CareCo Referrer';
            con.Lastname = 'Test Contact';
            con.Email = 'carecoreferrertestcontact@emailadd4testonly.com';
            con.AccountId = householdAccount.Id;
            con.MobilePhone = '+6200000000';
        insert con;
        
        carecoReferrerContact = con;
    }

    // create test careco client contact
    private static void createCareCoClientContact(){
        Contact con = new Contact();
            // con.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CM_Client').getRecordTypeId();
            con.Firstname = 'CareCo Client';
            con.Lastname = 'Test Contact';
            con.Email = 'carecoclienttestcontact@emailadd4testonly.com';
            con.AccountId = householdAccount.Id;
            con.MobilePhone = '+6200000000';
        insert con;
        
        carecoClientContact = con;
    }

    // create test ramsay case
    private static void createRamsayCase(){
        Case cse = new Case();
            // cse.RecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CM_Ramsay_Connect').getRecordTypeId();
            cse.ContactId = carecoClientContact.Id;
        insert cse;
        
        ramsayCase = cse;
    }

    // create test service product
    private static void createServiceProduct(){
        Product2 pd = new Product2();
            pd.Name = 'Test Service Product';
            pd.ProductCode = 'TSTPRD-00001';
            pd.Description = 'Test Product For Service Field';
            pd.IsActive = TRUE;
        insert pd;
        
        serviceProduct = pd;
    }
        
    // create test package product
    /*
    private static void createCarePlanService(){
        CM_Care_Plan_Service__c cps = new CM_Care_Plan_Service__c();
            cps.CM_Service__c = serviceProduct.Id;
            cps.CM_Status__c = 'New';
            cps.CM_Case__c = ramsayCase.Id;
            cps.CM_Service_Provider_Contact__c = carecoClientContact.Id;
        insert cps;
    }
    */
    
    // create test document
    /*
    private static void createDocumentFile(){
        Document doc = new Document();
            doc.Body = Blob.valueOf('Test Test');
            doc.ContentType = 'application/pdf';
            doc.DeveloperName = 'test_document';
            doc.IsPublic = true;
            doc.Name = 'Test Document';
            doc.FolderId = docFolder.id;
        insert doc;
        
        docFile = doc;
    }
    */
    
    // create invoice 
    /*
    private static void  createInvoice(){
        CM_Invoice__c inv = new CM_Invoice__c();
            inv.CM_Case__c = ramsayCase.Id;
        insert inv;
        invoice = inv;
    }
    */
    
    // query test folder since folder can't be created via apex
    // private static void queryEmailTemplateFolder(){
    //     Folder fldr = [SELECT Id FROM Folder WHERE Name = 'CareCo Ramsay Connect Email Templates' LIMIT 1];
        
    //     emailTemplatefolder = fldr;
    // }
    
    // query test folder since folder can't be created via apex
    // private static void queryDocumentFolder(){
    //     Folder fldr = [SELECT Id FROM Folder WHERE type = 'document' AND Name like '%CareCo%'];
        
    //     docFolder = fldr;
    // }

    // create test ramsay email template
    /*
    private static void createEmailTemplate() {

        EmailTemplate tmp = new EmailTemplate();
            tmp.Name = 'Test Template Name';
            tmp.FolderId = emailTemplatefolder.Id;
            tmp.Subject = 'Test Subject';
            tmp.HtmlValue = '<div> {!Case.CaseNumber} </div>';

        insert tmp;

        emailTemplate = tmp;
        
    }
    */
    
    private static void createFiles() {
        ContentVersion cv = new ContentVersion();
        cv.Description  = 'test description';
        cv.PathOnClient ='test_file.txt';
        cv.Title = 'test file '+DateTime.now();
        cv.versiondata=Blob.valueOf('test file body');
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        Case c = [SELECT Id FROM Case LIMIT 1];
        cdl.LinkedEntityId = c.Id; 
        cdl.ShareType = 'V';
        insert cdl;
        
        conentVersion = cv;
        contentDocumentLink = cdl;
    }



    /** TEST SCENARIOS **/
    
    
    /*
     * @description: test getContactEmails method
     *
    */
    @isTest
    private static void getContactEmailsTest(){
        Test.startTest();
            Case cse = [SELECT Id FROM Case LIMIT 1];
        
            Map<String, List<CM_CustomSendEmailController.ContactInfoWrapper>> result = CM_CustomSendEmailController.getContactEmails(cse.Id, CASE_OBJECT);

            System.assert(result.size() == 0);
        Test.stopTest();
    }

    
    
    /*
     * @description: test getDefaultFromEmailAddress method
     *
    */
    @isTest
    private static void getDefaultFromEmailAddressTest(){
        Test.startTest();
            Case cse = [SELECT Id FROM Case LIMIT 1];
        
            OrgWideEmailAddress emailAddress = CM_CustomSendEmailController.getDefaultFromEmailAddress(cse.Id, CASE_OBJECT);
            // String strOrgWideEAddress = string.valueOf(emailAddress.Address);

            System.assert(emailAddress == null);
        Test.stopTest();
    }
    
    /*
     * @description: test fetchEmailTemplate method 
     *
    */
    @isTest
    private static void fetchEmailTemplateTest(){
        Test.startTest();
            List<CM_CustomSendEmailController.OptionWrap> lstOptionWrap = CM_CustomSendEmailController.fetchEmailTemplate();

            System.assert(lstOptionWrap.isEmpty());
        Test.stopTest();
    }
    
    /*
     * @description: test getEmailAttachments method
     *
    */
    @isTest
    private static void getEmailAttachmentsTest(){
        Test.startTest();
            Case cse = [SELECT Id FROM Case LIMIT 1];
      
            ContentVersion content = new ContentVersion(); 
                content.Title = 'Header_Picture1'; 
                content.PathOnClient = '/' + content.Title + '.jpg'; 
                content.VersionData = Blob.valueOf('Unit Test ContentVersion Body');
                content.origin = 'H';
            insert content;
            
            ContentVersion cv = [SELECT contentdocumentid FROM ContentVersion WHERE id =: content.Id];
            
            ContentDocumentLink contentlink = new ContentDocumentLink();
                contentlink.LinkedEntityId = cse.id;
                contentlink.contentdocumentid = cv.contentdocumentid;
                contentlink.ShareType = 'I';
                contentlink.Visibility = 'AllUsers'; 
            insert contentlink;
            
            List<Id> lstIDs = new List<Id>{cv.contentdocumentid};
        
            List<Messaging.EmailFileAttachment> lstEmailAttachment = CM_CustomSendEmailController.getEmailAttachments(cse.Id, lstIDs);
            System.assert(!lstEmailAttachment.isEmpty());
        Test.stopTest();
    }
    
    /*
     * @description: test fetchEmailBody method
     *
    */
    @isTest
    private static void fetchEmailBodyTest(){
        Test.startTest();
            Case cse = [SELECT Id FROM Case LIMIT 1];
            // EmailTemplate emTemp = [SELECT Id FROM EmailTemplate LIMIT 1];
            //CM_Invoice__c inv = [SELECT Id FROM CM_Invoice__c LIMIT 1];
            

            CM_CustomSendEmailController.EmailTemplateWrap emTempWrap = CM_CustomSendEmailController.fetchEmailBody(String.valueOf(cse.Id), 'emTemp.Id', CASE_OBJECT);
            System.assert(emTempWrap == null);
        Test.stopTest();
    }
    
    /*
     * @description: test sendEmailController method
     *
    */
    @isTest
    private static void sendEmailControllerTest(){
        Test.startTest();
            Case cse = [SELECT Id FROM Case LIMIT 1];
            // Document doc = [SELECT Id FROM Document LIMIT 1];
            String strJSONEmailDetails = '{"toAddress": ["testEmail@testEmailOnly.test"],"ccAddress": null,"subject": "Test Subject","body": "Test Email Body"}';
            
            List<Id> lstIDs = new List<Id>();
            CM_CustomSendEmailController.sendEmailController(strJSONEmailDetails, lstIDs, cse.Id);
        Test.stopTest();
    }
    
    /*
     * @description: test deleteAttachmentFile method
     *
    */
    @isTest
    private static void deleteAttachmentFileTest(){
        Test.startTest();
            Case cse = [SELECT Id FROM Case LIMIT 1];
        	// ContentVersion cv = [SELECT ID,ContentDocumentId FROM ContentVersion LIMIT 1 ];
        	// ContentDocumentLink cdl = [SELECT ID, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :cv.ContentDocumentId LIMIT 1];
            CM_CustomSendEmailController.deleteAttachmentFile(cse.Id, 'cdl.ContentDocumentId');
        	
        	// List<ContentDocumentLink> deletedDoc = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :cdl.Id ];
        	// System.assert(deletedDoc.isEmpty());
        Test.stopTest();
    }
    
       /*
     * @description: test getAllRelatedFiles method
     *
    */
    @isTest
    private static void getAllRelatedFilesTest(){
        Test.startTest();
            Case cse = [SELECT Id FROM Case LIMIT 1];
            Map<String, List<CM_CustomSendEmailController.RelatedFilesWrap>> result = CM_CustomSendEmailController.getAllRelatedFiles(cse.Id, CASE_OBJECT);
    
        	System.assert(result.containsKey('Case'));
        Test.stopTest();
    }

           /*
     * @description: test findObjectNameFromRecordIdPrefix method
     *
    */
    @isTest
    private static void findObjectNameFromRecordIdPrefixTest() {
        Test.startTest();
        Case cse = [SELECT Id FROM Case LIMIT 1];
        String result = CM_CustomSendEmailController.findObjectNameFromRecordIdPrefix(cse.Id);

        System.assert(result == CASE_OBJECT);
        Test.stopTest();

    }

    @isTest
    private static void getContactInfoTest(){ 
        Test.startTest();
        CM_CustomSendEmailController.ContactInfoWrapper wrapper = CM_CustomSendEmailController.getContactInfo('contactName', 'strContactEmail', 'strContactTitle');
        System.assert(wrapper != null);
        Test.stopTest();

        
    }
    
    
}