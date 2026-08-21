// -------------------------------------------------------------------------
// Belgian Patient Access Extension
// -------------------------------------------------------------------------
Extension: BeExtPatientAccess
Id: be-ext-patient-access
Title: "Belgian Patient Access Metadata"
Description: "Carries patient visibility and accessibility rules for a document in the Belgian federated hub ecosystem (replaces KMEHR PatientAccess schemes)."
* ^status = #active
* ^context[0].type = #element
* ^context[0].expression = "DocumentReference"
* ^context[1].type = #element
* ^context[1].expression = "Composition"

* extension contains
    access 1..1 and
    accessDate 0..1 and
    deniedReason 0..1

* extension[access] ^short = "Patient access permission (yes | no | never)"
* extension[access].value[x] only code
* extension[access].valueCode from BeVSPatientAccess (required)

* extension[accessDate] ^short = "Date from which the document is available to the patient (only valid if access is 'yes')"
* extension[accessDate].value[x] only date

* extension[deniedReason] ^short = "Reason explaining why the document is withheld from the patient (applicable when access is 'no' or 'never')"
* extension[deniedReason].value[x] only string

// -------------------------------------------------------------------------
// Home Community ID Extension
// -------------------------------------------------------------------------
Extension: BeExtHomeCommunityId
Id: be-ext-home-community-id
Title: "Belgian Hub Home Community ID"
Description: "Specifies the Home Community ID (as an OID URN, e.g. urn:oid:1.3.6.1.4.1.21297.1.X) of the regional hub hosting the document repository. Essential for federated cross-hub routing."
* ^status = #active
* ^context[0].type = #element
* ^context[0].expression = "DocumentReference"
* ^context[1].type = #element
* ^context[1].expression = "Bundle"
* value[x] only uri or Identifier
* value[x] 1..1

// -------------------------------------------------------------------------
// Belgian End-to-End Encryption (ETEE / ETK) Extension
// -------------------------------------------------------------------------
Extension: BeExtEndToEndEncryption
Id: be-ext-end-to-end-encryption
Title: "Belgian End-to-End Encryption Metadata (ETK Depot)"
Description: "Metadata required for retrieving the recipient's encryption token key (ETK) from the Belgian eHealth ETK depot for end-to-end encrypted Interhub transactions."
* ^status = #active
* ^context[0].type = #element
* ^context[0].expression = "DocumentReference"
* ^context[1].type = #element
* ^context[1].expression = "Bundle"

* extension contains
    actorId 1..1 and
    actorType 1..1 and
    applicationId 0..1 and
    keyId 0..1

* extension[actorId] ^short = "Encryption actor identifier (e.g. NIHDI, CBE, SSIN)"
* extension[actorId].value[x] only string

* extension[actorType] ^short = "Type of encryption actor within the ETK depot"
* extension[actorType].value[x] only code
* extension[actorType].valueCode from BeVSETKEncryptionActor (required)

* extension[applicationId] ^short = "Application / system ID in the ETK depot"
* extension[applicationId].value[x] only string

* extension[keyId] ^short = "Encryption Token Key (ETK) identifier"
* extension[keyId].value[x] only string

// -------------------------------------------------------------------------
// Source Record Date-Time Extension
// -------------------------------------------------------------------------
Extension: BeExtRecordDateTime
Id: be-ext-record-datetime
Title: "Source System Recording Timestamp"
Description: "The exact date and time when the transaction was recorded in the originating hub source system (corresponds to KMEHR recorddatetime)."
* ^status = #active
* ^context[0].type = #element
* ^context[0].expression = "DocumentReference"
* ^context[1].type = #element
* ^context[1].expression = "Composition"
* value[x] only instant
* value[x] 1..1
