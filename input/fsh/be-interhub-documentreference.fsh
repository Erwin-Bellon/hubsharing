Profile: BeInterhubDocumentReference
Parent: DocumentReference
Id: be-interhub-documentreference
Title: "Belgian Interhub DocumentReference"
Description: "Belgian metadata carrier profile for health document discovery (MHD ITI-67 / getTransactionList) and document retrieval (MHD ITI-68 / getTransaction) across federated eHealth Hubs. Replaces KMEHR TransactionSummaryType with a modern, EHDS-aligned FHIR metadata envelope. All party references target the national hl7.fhir.be.core profiles (BePatient, BePractitioner, BePractitionerRole, BeOrganization) rather than the HL7 base resources. It derives from the HL7 base DocumentReference rather than from BeDocumentReference for one reason only: BeDocumentReference caps author at 1..1, which cannot express the ordered Belgian Hub author chain — see the note on the author element."

* ^status = #active
* ^version = "0.1.0"

// -------------------------------------------------------------------------
// RELATIONSHIP TO BeDocumentReference (hl7.fhir.be.core)
//
// This profile mirrors every constraint of the Belgian federal
// BeDocumentReference profile
// (https://www.ehealth.fgov.be/standards/fhir/core/StructureDefinition/be-documentreference):
//
//   subject                        1..1, Reference(BePatient)
//   author                         Reference(BeOrganization | BePractitioner |
//                                  BePractitionerRole | BePatient | Device |
//                                  RelatedPerson)
//   content.attachment.contentType 1..1
//   category, content, content.attachment.data, content.attachment.url,
//   context.related                mustSupport
//
// ... with ONE deliberate divergence, which is why Parent is the base
// DocumentReference and not BeDocumentReference:
//
//   *** CHANGE REQUEST TO hl7.fhir.be.core ***
//   BeDocumentReference constrains DocumentReference.author to 1..1.
//   KMEHR has always allowed a transaction to carry SEVERAL <hcparty>
//   author elements (the answering hub, the originating hub source
//   organisation and the authoring physician are three distinct parties,
//   and KMEHR expresses all three), and the HL7 base resource allows
//   author 0..*. The 1..1 cap in be.core is therefore a regression against
//   both KMEHR and the base specification, and it makes federated document
//   sharing impossible to express: there is no way to state both WHICH HUB
//   answered and WHICH CLINICIAN wrote the document in a single entry.
//
//   BeDocumentReference SHOULD be relaxed to author 1..* so that this
//   profile can derive from it directly. Until that change lands in
//   hl7.fhir.be.core, this IG profiles the base resource and re-applies the
//   be.core constraints by hand. Nothing else here conflicts with
//   BeDocumentReference, so an instance valid against this profile is also
//   valid against BeDocumentReference whenever it happens to carry a single
//   author.
// -------------------------------------------------------------------------

// Extensions
* extension contains
    BeExtHomeCommunityId named homeCommunityId 1..1 MS and
    BeExtPatientAccess named patientAccess 0..1 MS and
    BeExtEndToEndEncryption named endToEndEncryption 0..1 MS and
    BeExtRecordDateTime named recordDateTime 0..1 MS

* extension[homeCommunityId] ^short = "Home Community ID of the regional hub hosting the document"
* extension[patientAccess] ^short = "Patient access and visibility metadata"
* extension[endToEndEncryption] ^short = "ETK depot encryption endpoint metadata (if payload is end-to-end encrypted)"
* extension[recordDateTime] ^short = "Timestamp when the document was recorded in the hub source system"

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

* identifier[localId] ^short = "Hub source internal identifier (hospital EHR, LIS, practice software, ...)"
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

* category[cdTransaction] ^short = "Belgian document category (CD-TRANSACTION: sumehr, labresult, discharge, telemonitoring, etc.), optionally accompanied by local translations of the same category"
* category[cdTransaction] ^definition = "Document category of this entry. The CD-TRANSACTION coding is mandatory so that every hub can filter on a single national vocabulary. Additional codings expressing the SAME category in another code system (a local hub source category such as 'daghospitalisatieVerslag', a regional catalogue code, or a LOINC/SNOMED CT equivalent) MAY be added to this CodeableConcept and MUST NOT be dropped when a document is relayed between hubs. A category that is a genuinely DIFFERENT concept belongs in an additional category element, not as an extra coding here."
* category[cdTransaction] from BeVSCDTransaction (extensible)
* category[cdTransaction].coding 1..* MS
* category[cdTransaction].coding ^slicing.discriminator.type = #value
* category[cdTransaction].coding ^slicing.discriminator.path = "system"
* category[cdTransaction].coding ^slicing.rules = #open
* category[cdTransaction].coding ^short = "One or more codings of the same document category; the CD-TRANSACTION coding is mandatory, local/alternative codings are allowed alongside it"
* category[cdTransaction].coding contains cdTransactionCode 1..1 MS
* category[cdTransaction].coding[cdTransactionCode] ^short = "The Belgian national CD-TRANSACTION coding (mandatory)"
* category[cdTransaction].coding[cdTransactionCode].system 1..1 MS
* category[cdTransaction].coding[cdTransactionCode].system = "https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction" (exactly)
* category[cdTransaction].coding[cdTransactionCode].code 1..1 MS
* category[cdTransaction].text 0..1 MS
* category[cdTransaction].text ^short = "Local human-readable label of the category, when no coded local equivalent exists"

// Additional category elements (other than the CD-TRANSACTION one) remain allowed by the
// open slicing above, for categories that are a different concept rather than a translation.

* type 1..1 MS
* type ^short = "Precise clinical document type (LOINC and/or national or local Belgian type codes)"
* type ^definition = "Precise clinical type of the document. As for category, several codings MAY be present in this single CodeableConcept when they express the same document type in different code systems (e.g. a LOINC code plus a local hub source document-type code); at least one coding SHOULD be LOINC for cross-border and EHDS compatibility."
* type.coding 1..* MS
* type.coding.system 1..1 MS
* type.coding.code 1..1 MS
* type.text 0..1 MS

// Patient Subject (INSS / SSIN)
* subject 1..1 MS
* subject only Reference($BePatient)
* subject ^short = "Patient who is the subject of the document (must carry national SSIN/INSS identifier)"
* subject.identifier MS
* subject.identifier ^short = "Patient SSIN / INSS carried inline, so a consumer does not need to resolve the Patient reference to identify the subject"

// Temporal Metadata
* date 1..1 MS
* date ^short = "When this document metadata entry was created/indexed (UTC instant)"

// Authors & Organizations
* author 1..* MS
* author only Reference($BePractitioner or $BePractitionerRole or $BeOrganization or Device or $BePatient or RelatedPerson)
* author ^short = "Sequence of document authors. In Belgian Hub rules: first author represents the answering hub / originating hub source organisation, followed by the healthcare practitioner"
* author ^definition = "Authors of the document. Any party type of the KMEHR CD-HCPARTY table can be represented: person types (persphysician, persnurse, persdentist, ...) as BePractitioner or BePractitionerRole, organisation types (orghospital, orglaboratory, orgpharmacy, orgpractice, orgretirementhome, ...) as BeOrganization, department and specialty types (dept...) as BeOrganization or BePractitionerRole, software or automated senders (application) as Device, the patient as BePatient, and other involved persons as RelatedPerson. The CD-HCPARTY code itself is carried inline by the hcPartyType extension so that consumers do not have to resolve the reference to learn what kind of party it is.\n\nCARDINALITY NOTE: the federal BeDocumentReference profile caps author at 1..1. This IG keeps author 1..* because KMEHR permits several hcparty authors per transaction and Belgian Hub rules require the answering hub, the originating hub source organisation and the authoring practitioner to be identifiable in one and the same entry. A relaxation of BeDocumentReference.author to 1..* has been requested against hl7.fhir.be.core; once it is published this profile will derive from BeDocumentReference directly."
* author.extension contains BeExtHcPartyType named hcPartyType 0..1 MS
* author.extension[hcPartyType] ^short = "KMEHR CD-HCPARTY type of this author (persphysician, orghospital, orglaboratory, application, ...)"
* author.identifier MS
* author.identifier ^short = "Business identifier of the author (practitioner NIHDI, organisation NIHDI or CBE, hub OID). SHOULD be populated so the entry is usable without resolving the reference"
* author.display MS
* author.display ^short = "Human-readable name of the author, so a search result can be rendered without resolving the reference"

* authenticator 0..1 MS
* authenticator only Reference($BePractitioner or $BePractitionerRole or $BeOrganization)
* authenticator ^short = "Party that legally validated / attested the document content (KMEHR isvalidated)"
* authenticator ^definition = "The healthcare party that legally validated the document. As for author, this may be any CD-HCPARTY party: a person type as BePractitioner or BePractitionerRole, or an organisation / department type as BeOrganization. Its CD-HCPARTY code is carried inline by the hcPartyType extension."
* authenticator.extension contains BeExtHcPartyType named hcPartyType 0..1 MS
* authenticator.extension[hcPartyType] ^short = "KMEHR CD-HCPARTY type of the validating party"
* authenticator.identifier MS
* authenticator.identifier ^short = "Business identifier of the validating party (NIHDI / CBE)"
* authenticator.display MS

* custodian 0..1 MS
* custodian only Reference($BeOrganization)
* custodian ^short = "Custodian organization responsible for long-term document maintenance (the hub source organisation or its repository)"
* custodian ^definition = "Organization accountable for the long-term maintenance and availability of the document. This is a CD-HCPARTY organisation type (orghospital, orglaboratory, orgpharmacy, orgpractice, orgretirementhome, orgpolyclinic, ...) — a hospital is only one of the possible custodians. Its CD-HCPARTY code is carried inline by the hcPartyType extension, and its CBE / NIHDI number by custodian.identifier."
* custodian.extension contains BeExtHcPartyType named hcPartyType 0..1 MS
* custodian.extension[hcPartyType] ^short = "KMEHR CD-HCPARTY organisation type of the custodian"
* custodian.identifier MS
* custodian.identifier ^short = "Business identifier of the custodian organisation (NIHDI institution number or CBE enterprise number)"
* custodian.display MS

* relatesTo 0..* MS
* relatesTo ^short = "Relationship to other documents (replaces, transforms, appends), expressed by business identifier"
* relatesTo.code 1..1 MS
* relatesTo.target 1..1 MS
* relatesTo.target ^short = "The related document, identified by its business identifier (document uniqueId) rather than by a resolvable endpoint URL"
* relatesTo.target ^definition = "Reference to the related document. Belgian Interhub uses a LOGICAL reference: relatesTo.target.identifier SHALL carry the uniqueId of the related document (the same value that appears in that document's identifier[uniqueId], as an RFC 3986 URI). A literal relatesTo.target.reference is OPTIONAL and, when present, is a convenience only: a consumer MUST be able to resolve the relationship from the identifier alone, without issuing an additional query per returned entry (avoiding N+1 round-trips over a federated network)."
* relatesTo.target.identifier 1..1 MS
* relatesTo.target.identifier.system 1..1 MS
* relatesTo.target.identifier.system = "urn:ietf:rfc:3986" (exactly)
* relatesTo.target.identifier.value 1..1 MS
* relatesTo.target.identifier ^short = "uniqueId of the related document (RFC 3986 URI, e.g. urn:oid:... or urn:uuid:...)"
* relatesTo.target.reference 0..1
* relatesTo.target.reference ^short = "Optional literal reference; consumers MUST NOT be required to dereference it"
* relatesTo.target.display 0..1 MS

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
* content.attachment.title 0..1 MS
* content.attachment.title ^short = "Document title"

// Mirrors BeDocumentReference: content.attachment.data is mustSupport there.
// Interhub always retrieves the payload out of band via content.attachment.url
// (ITI-68), so inline base64 data stays optional here.
* content.attachment.data 0..1 MS
* content.attachment.data ^short = "Inline base64 payload. NOT used by Interhub metadata discovery - a getTransactionList entry carries the retrieval URL, never the document body"

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

// Mirrors BeDocumentReference: context.related is mustSupport there.
* context.related 0..* MS
* context.related ^short = "Other resources (encounter, episode of care, order, ...) that place this document in its clinical context"
