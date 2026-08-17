// -------------------------------------------------------------------------
// Belgian Interhub Document Bundle Profile
// -------------------------------------------------------------------------
Profile: BeInterhubDocumentBundle
Parent: Bundle
Id: be-interhub-document-bundle
Title: "Belgian Interhub Document Bundle"
Description: "The canonical document bundle exchanged between Belgian eHealth Hubs and repositories during getTransaction (MHD ITI-68) operations. Under the Belgian Interhub specification, only Bundles of type 'document' are shared across hubs."

* ^status = #active
* ^version = "0.1.0"

* identifier 1..1 MS
* identifier ^short = "Global unique identifier for this document bundle (e.g. system=urn:ietf:rfc:3986 or Belgian Hub namespace)"
* identifier.system 1..1 MS
* identifier.value 1..1 MS

* type = #document (exactly)
* type ^short = "Type of bundle - MUST be 'document' for all Interhub sharing"

* timestamp 1..1 MS
* timestamp ^short = "Document bundle generation timestamp (ISO 8601 UTC)"

* entry 1..* MS
* entry ^slicing.discriminator.type = #profile
* entry ^slicing.discriminator.path = "resource"
* entry ^slicing.rules = #open
* entry contains composition 1..1 MS

* entry[composition] ^short = "The mandatory root Composition resource representing the document clinical header and narrative sections"
* entry[composition].resource only Composition

// -------------------------------------------------------------------------
// Belgian Interhub Laboratory Report Composition Profile
// -------------------------------------------------------------------------
Profile: BeInterhubLabComposition
Parent: Composition
Id: be-interhub-lab-composition
Title: "Belgian Interhub Laboratory Report Composition"
Description: "Root Composition resource for Belgian Laboratory Report Document Bundles. Aligned with both HL7 Belgium BeLaboratoryReportComposition and EHDS EU Laboratory Report specifications (Composition-eu-lab)."

* ^status = #active
* ^version = "0.1.0"

* identifier 0..1 MS
* identifier ^short = "Unique identifier for this laboratory report composition"

* status MS
* status ^short = "Document status: preliminary | final | amended | entered-in-error"

* type MS
* type = $LNC#11502-2 "Laboratory report"
* type ^short = "Document type code (fixed to LOINC 11502-2 for Lab Reports)"

* category 0..1 MS
* category = https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction#labresult "Laboratory Result"
* category ^short = "Belgian document category (fixed to labresult for Lab Reports)"

* subject 1..1 MS
* subject only Reference(Patient)
* subject ^short = "Patient who is the subject of the lab report"

* date 1..1 MS
* date ^short = "Document composition date/time"

* author 1..* MS
* author only Reference(Practitioner or PractitionerRole or Organization or Device)
* author ^short = "Authoring laboratory, laboratory physician, or device"

* title 1..1 MS
* title ^short = "Human-readable title of the laboratory report (e.g. 'Comprehensive Hematology and Biochemistry Report')"

* confidentiality 0..1 MS
* confidentiality ^short = "Confidentiality level of the document"

* attester 0..* MS
* attester.mode MS
* attester.time MS
* attester.party MS

* custodian 0..1 MS
* custodian only Reference(Organization)
* custodian ^short = "Custodian laboratory or hospital organization"

* section 1..* MS
* section ^short = "Sections containing laboratory findings, specialty panels, and observations"
* section.title 0..1 MS
* section.code 0..1 MS
* section.text 1..1 MS
* section.text ^short = "Human-readable narrative summary for the section"
* section.entry 0..* MS
* section.entry only Reference(DiagnosticReport or Observation or Specimen or DocumentReference)

// -------------------------------------------------------------------------
// Belgian Interhub Telemonitoring Composition Profile
// -------------------------------------------------------------------------
Profile: BeTelemonitoringComposition
Parent: Composition
Id: be-telemonitoring-composition
Title: "Belgian Interhub Telemonitoring Composition"
Description: "Root Composition resource for Belgian Telemonitoring / Remote Patient Monitoring Document Bundles. Encapsulates telemonitoring sessions, carepaths, remote diagnostic reports, and patient observations into a shareable FHIR document."

* ^status = #active
* ^version = "0.1.0"

* identifier 0..1 MS
* identifier ^short = "Unique identifier for this telemonitoring document composition"

* status MS
* status ^short = "Document status: preliminary | final | amended | entered-in-error"

* type MS
* type ^short = "Document type code (e.g. LOINC 10185-7 for Holter study or remote monitoring code)"

* category 0..1 MS
* category = https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction#telemonitoring "Telemonitoring / Remote Patient Monitoring"
* category ^short = "Belgian document category (fixed to telemonitoring for Telemonitoring documents)"

* subject 1..1 MS
* subject only Reference(Patient)
* subject ^short = "Patient who is monitored"

* date 1..1 MS
* date ^short = "Document composition date/time"

* author 1..* MS
* author only Reference(Practitioner or PractitionerRole or Organization or Device)
* author ^short = "Authoring prescriber, monitoring service, or remote monitoring platform"

* title 1..1 MS
* title ^short = "Human-readable title of the telemonitoring report (e.g. '24-Hour Continuous Holter Monitoring Report')"

* custodian 0..1 MS
* custodian only Reference(Organization)

* section 1..* MS
* section ^short = "Sections containing telemonitoring summaries, diagnostic reports, and observation series"
* section.title 0..1 MS
* section.code 0..1 MS
* section.text 1..1 MS
* section.text ^short = "Human-readable narrative summary for the telemonitoring section"
* section.entry 0..* MS
* section.entry only Reference(DiagnosticReport or Observation or CarePlan or Device or QuestionnaireResponse)
