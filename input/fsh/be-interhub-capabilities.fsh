// -------------------------------------------------------------------------
// Belgian Interhub Document Responder CapabilityStatement
// -------------------------------------------------------------------------
Instance: BeInterhubDocumentResponder
InstanceOf: CapabilityStatement
Usage: #definition
Title: "Belgian Interhub Document Responder Capability Statement"
Description: "Defines the mandatory capabilities for Belgian eHealth Hubs and repositories responding to Interhub metadata discovery (getTransactionList / MHD ITI-67) and document retrieval (getTransaction / MHD ITI-68) requests."
* status = #active
* date = "2026-08-17"
* kind = #requirements
* fhirVersion = #4.0.1
* format[0] = #json
* format[1] = #xml
* rest.mode = #server
* rest.documentation = "Belgian Federated Interhub Document Sharing Server (MHD ITI-67 Responder / ITI-68 Responder)"

// Resource: DocumentReference (for getTransactionList / ITI-67)
* rest.resource[0].type = #DocumentReference
* rest.resource[0].profile = "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-interhub-documentreference"
* rest.resource[0].interaction[0].code = #read
* rest.resource[0].interaction[1].code = #search-type

* rest.resource[0].searchParam[0].name = "patient.identifier"
* rest.resource[0].searchParam[0].type = #token
* rest.resource[0].searchParam[0].documentation = "Mandatory patient search parameter using national SSIN/INSS (system=https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/ssin or urn:oid:1.3.6.1.4.1.21297.100.1.1)."

* rest.resource[0].searchParam[1].name = "category"
* rest.resource[0].searchParam[1].type = #token
* rest.resource[0].searchParam[1].documentation = "Filters by Belgian CD-TRANSACTION code (e.g. sumehr, labresult, discharge, telemonitoring)."

* rest.resource[0].searchParam[2].name = "type"
* rest.resource[0].searchParam[2].type = #token
* rest.resource[0].searchParam[2].documentation = "Filters by clinical document type (LOINC code)."

* rest.resource[0].searchParam[3].name = "date"
* rest.resource[0].searchParam[3].type = #date
* rest.resource[0].searchParam[3].documentation = "Filters by document creation date range (using ge and le prefixes)."

* rest.resource[0].searchParam[4].name = "author.identifier"
* rest.resource[0].searchParam[4].type = #token
* rest.resource[0].searchParam[4].documentation = "Filters by authoring practitioner or institution NIHDI/SSIN/CBE identifier."

* rest.resource[0].searchParam[5].name = "status"
* rest.resource[0].searchParam[5].type = #token
* rest.resource[0].searchParam[5].documentation = "Document reference status (current, superseded)."

* rest.resource[0].searchParam[6].name = "_id"
* rest.resource[0].searchParam[6].type = #token
* rest.resource[0].searchParam[6].documentation = "Document logical ID."

* rest.resource[0].searchParam[7].name = "identifier"
* rest.resource[0].searchParam[7].type = #token
* rest.resource[0].searchParam[7].documentation = "Universal or local document identifier."

// Resource: Bundle (for getTransaction / ITI-68 document retrieval)
* rest.resource[1].type = #Bundle
* rest.resource[1].profile = "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-interhub-document-bundle"
* rest.resource[1].interaction[0].code = #read
* rest.resource[1].documentation = "Retrieval of complete FHIR Document Bundles (type=document) by ID."

// -------------------------------------------------------------------------
// Belgian Interhub Document Consumer CapabilityStatement
// -------------------------------------------------------------------------
Instance: BeInterhubDocumentConsumer
InstanceOf: CapabilityStatement
Usage: #definition
Title: "Belgian Interhub Document Consumer Capability Statement"
Description: "Defines the capabilities and expectations for client systems (EHRs, regional portals, initiating hubs) querying and retrieving health documents from Belgian Hubs."
* status = #active
* date = "2026-08-17"
* kind = #requirements
* fhirVersion = #4.0.1
* format[0] = #json
* format[1] = #xml
* rest.mode = #client
* rest.documentation = "Belgian Federated Interhub Document Consumer (MHD ITI-67 Consumer / ITI-68 Consumer)"

* rest.resource[0].type = #DocumentReference
* rest.resource[0].profile = "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-interhub-documentreference"
* rest.resource[0].interaction[0].code = #search-type
* rest.resource[0].interaction[1].code = #read

* rest.resource[1].type = #Bundle
* rest.resource[1].profile = "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-interhub-document-bundle"
* rest.resource[1].interaction[0].code = #read
