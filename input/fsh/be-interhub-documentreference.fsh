Profile: BeInterhubDocumentReference
Parent: DocumentReference
Id: be-interhub-documentreference
Title: "Belgian Interhub DocumentReference"
Description: "Belgian metadata carrier profile for health document discovery (MHD ITI-67 / getTransactionList) and document retrieval (MHD ITI-68 / getTransaction) across federated eHealth Hubs. Replaces KMEHR TransactionSummaryType with a modern, EHDS-aligned FHIR metadata envelope."

* ^status = #active
* ^version = "0.1.0"

// Extensions
* extension contains
    BeExtHomeCommunityId named homeCommunityId 1..1 MS and
    BeExtPatientAccess named patientAccess 0..1 MS and
    BeExtEndToEndEncryption named endToEndEncryption 0..1 MS and
    BeExtRecordDateTime named recordDateTime 0..1 MS

* extension[homeCommunityId] ^short = "Home Community ID of the regional hub hosting the document"
* extension[patientAccess] ^short = "Patient access and visibility metadata"
* extension[endToEndEncryption] ^short = "ETK depot encryption endpoint metadata (if payload is end-to-end encrypted)"
* extension[recordDateTime] ^short = "Timestamp when the document was recorded in the source vault"

// Document Identifiers
* masterIdentifier 0..1 MS
* masterIdentifier ^short = "Master globally unique document identifier (e.g. urn:oid:... or urn:uuid:...)"

* identifier 1..* MS
* identifier ^slicing.discriminator.type = #value
* identifier ^slicing.discriminator.path = "system"
* identifier ^slicing.rules = #open
* identifier contains 
    uniqueId 1..1 MS and
    localId 0..* MS

* identifier[uniqueId] ^short = "Universal document entry identifier (RFC 3986 URI format)"
* identifier[uniqueId].system = "urn:ietf:rfc:3986" (exactly)
* identifier[uniqueId].value 1..1 MS

* identifier[localId] ^short = "Source repository / hospital internal identifier"
* identifier[localId].system 1..1 MS
* identifier[localId].value 1..1 MS

// Document Lifecycle & Status
* status 1..1 MS
* status ^short = "Status of this document reference: current | superseded | entered-in-error"

* docStatus 0..1 MS
* docStatus ^short = "Clinical lifecycle status of the underlying document: preliminary | final | amended | entered-in-error"

// Categories & Clinical Type
* category 1..* MS
* category ^slicing.discriminator.type = #value
* category ^slicing.discriminator.path = "coding.system"
* category ^slicing.rules = #open
* category contains cdTransaction 1..1 MS

* category[cdTransaction] ^short = "Belgian document category (CD-TRANSACTION: sumehr, labresult, discharge, telemonitoring, etc.)"
* category[cdTransaction].coding 1..* MS
* category[cdTransaction].coding.system 1..1 MS
* category[cdTransaction].coding.system = "https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction" (exactly)
* category[cdTransaction].coding.code 1..1 MS
* category[cdTransaction] from BeVSCDTransaction (extensible)

* type 1..1 MS
* type ^short = "Precise clinical document type (LOINC or national Belgian type code)"
* type.coding 1..* MS
* type.coding.system 1..1 MS
* type.coding.code 1..1 MS

// Patient Subject (INSS / SSIN)
* subject 1..1 MS
* subject only Reference(Patient)
* subject ^short = "Patient who is the subject of the document (must carry national SSIN/INSS identifier)"

// Temporal Metadata
* date 1..1 MS
* date ^short = "When this document metadata entry was created/indexed (UTC instant)"

// Authors & Organizations
* author 1..* MS
* author only Reference(Practitioner or PractitionerRole or Organization or Device or Patient)
* author ^short = "Sequence of document authors. In Belgian Hub rules: first author represents the answering/originating hub/hospital, followed by the healthcare practitioner"

* authenticator 0..1 MS
* authenticator only Reference(Practitioner or PractitionerRole or Organization)
* authenticator ^short = "Legal validator of the document content"

* custodian 0..1 MS
* custodian only Reference(Organization)
* custodian ^short = "Custodian organization responsible for document maintenance (e.g. hospital or repository)"

* relatesTo 0..* MS
* relatesTo ^short = "Relationship to other documents (replaces, transforms, appends)"
* relatesTo.code MS
* relatesTo.target MS

* description 0..1 MS
* description ^short = "Human-readable title or clinical summary of the document (from KMEHR caption/text)"

* securityLabel 0..* MS
* securityLabel ^short = "Confidentiality code (e.g. N = Normal, R = Restricted, V = Very Restricted)"
* securityLabel from http://terminology.hl7.org/ValueSet/v3-Confidentiality (extensible)

// Content & Retrieval Attachment
* content 1..* MS
* content.attachment 1..1 MS
* content.attachment.contentType 1..1 MS
* content.attachment.contentType ^short = "MIME type of document payload (e.g. application/fhir+json, application/pdf)"
* content.attachment.language 0..1 MS
* content.attachment.language ^short = "Human language of document (e.g. nl-BE, fr-BE, de-BE, en)"
* content.attachment.url 1..1 MS
* content.attachment.url ^short = "Direct URL endpoint to retrieve the FHIR Document Bundle (ITI-68 retrieve endpoint)"
* content.attachment.size 0..1 MS
* content.attachment.size ^short = "Byte size of the raw document content"
* content.attachment.hash 0..1 MS
* content.attachment.hash ^short = "Base64-encoded SHA-1 or SHA-256 hash of the document content"
* content.attachment.title 0..1 MS
* content.attachment.title ^short = "Document title"

* content.format 0..1 MS
* content.format ^short = "Format code for the document (e.g. urn:be:fgov:ehealth:lab:document:1.0)"
* content.format from BeVSInterhubFormatCodes (extensible)

// Clinical Context
* context 0..1 MS
* context.period 0..1 MS
* context.period ^short = "Time of clinical encounter or monitoring episode (start and end datetime)"
* context.facilityType 0..1 MS
* context.facilityType ^short = "Healthcare facility classification"
* context.practiceSetting 0..1 MS
* context.practiceSetting ^short = "Clinical specialty or practice setting"
