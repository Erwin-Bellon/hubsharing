# Interhub Transactions: getTransactionList & getTransaction

## 1. Overview of Interhub Transactions

The Belgian federated hub architecture relies on two core document-sharing interactions:
1. **Document Discovery (`getTransactionList`)**: Enables an EHR, clinical portal, or initiating hub to discover available clinical documents for a patient across all connected regional hubs.
2. **Document Retrieval (`getTransaction`)**: Enables a consumer to retrieve the complete, immutable clinical document payload for a specific transaction.

In the modernized FHIR-based Belgian Interhub standard, these legacy SOAP operations are mapped directly to the **IHE MHD (Mobile access to Health Documents)** profile family on **HL7® FHIR® R4**:

| Legacy KMEHR SOAP Operation | Target IHE MHD / FHIR Transaction | Target Resource / Action | Payload Returned |
| :--- | :--- | :--- | :--- |
| **`getTransactionList`** | **MHD ITI-67** (`Find DocumentReferences`) | `GET [base]/DocumentReference` (RESTful Search) | `Bundle` (type = `searchset`) containing `BeInterhubDocumentReference` entries |
| **`getTransaction`** | **MHD ITI-68** (`Retrieve Document`) / `$document` | `GET [base]/Bundle/[id]` or `GET [base]/Composition/[id]/$document` | Complete `BeInterhubDocumentBundle` (type = `document`) |

---

## 2. Transaction 1: `getTransactionList` (MHD ITI-67 `Find DocumentReferences`)

### 2.1 Trigger & Scope
A healthcare professional, clinical application, or regional gateway initiates this transaction to query for health documents available for a patient identified by their Belgian **SSIN / INSS**.

### 2.2 HTTP Interaction & Query Parameters

```http
GET [base]/DocumentReference?patient.identifier=https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/ssin|79080412345&category=https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction|labresult&date=ge2026-01-01T00:00:00Z&date=le2026-12-31T23:59:59Z&status=current&_count=50 HTTP/1.1
Host: hub.cozo.be
Accept: application/fhir+json
Authorization: Bearer <eHealth-OAuth-Token>
```

#### Supported Search Parameters:

| FHIR Search Parameter | Syntax & Modifier | KMEHR Concept | Description |
| :--- | :--- | :--- | :--- |
| **`patient.identifier`** *(Mandatory)* | `token` (`system\|value`) | `folder/patient/id[@S="INSS"]` | Patient's national Social Security Identification Number (SSIN). Systems must support both `https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/ssin` and `urn:oid:1.3.6.1.4.1.21297.100.1.1`. |
| **`category`** *(Optional)* | `token` (`system\|code`) | `transaction/cd[@S="CD-TRANSACTION"]` | Filters by Belgian document category (e.g. `sumehr`, `labresult`, `discharge`, `telemonitoring`). |
| **`type`** *(Optional)* | `token` (`system\|code`) | `transaction/cd[@S="CD-CLINICAL"]` | Filters by clinical LOINC code (e.g. `http://loinc.org\|11502-2` for Lab Report, `http://loinc.org\|10185-7` for Holter Study). |
| **`date`** *(Optional)* | `date` (`ge`, `le`, `gt`, `lt`) | `transaction/date` & `time` | Filters document creation timestamp within a date/time range. |
| **`author.identifier`** *(Optional)* | `token` (`system\|value`) | `transaction/author/hcparty/id` | Filters by authoring physician NIHDI (`1.3.6.1.4.1.21297.100.9.1`) or institution NIHDI (`100.11.1`). |
| **`status`** *(Optional)* | `token` (`current`, `superseded`) | Document execution status | Filter on metadata status. Defaults to `current`. |
| **`_id`** / **`identifier`** *(Optional)* | `token` | `transaction/id` | Query for a specific document reference by ID. |
| **`_count`** *(Optional)* | `integer` | `maxrows` | Maximum number of results requested per page. |
| **`_sort`** *(Optional)* | `string` (`-date`, `date`) | Order of results | Defaults to descending by creation date (`-date`). |

### 2.3 Response Structure (`Bundle` type = `searchset`)

The answering hub returns an **HTTP 200 OK** with a FHIR `Bundle` of type `searchset`:
* `Bundle.total`: Total number of matching document entries.
* `Bundle.entry[]`: Array of matching `BeInterhubDocumentReference` resources.
* If no matching documents exist, an empty searchset Bundle is returned (`total = 0`, `entry = []`).

```json
{
  "resourceType": "Bundle",
  "id": "bundle-transaction-list-response",
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "fullUrl": "https://hub.cozo.be/fhir/DocumentReference/docref-lab-example-01",
      "resource": {
        "resourceType": "DocumentReference",
        "id": "docref-lab-example-01",
        "meta": {
          "profile": [
            "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-interhub-documentreference"
          ]
        },
        "extension": [
          {
            "url": "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-home-community-id",
            "valueUri": "urn:oid:1.3.6.1.4.1.21297.1.3"
          },
          {
            "url": "https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-patient-access",
            "extension": [
              { "url": "access", "valueCode": "yes" },
              { "url": "accessDate", "valueDate": "2026-03-15" }
            ]
          }
        ],
        "masterIdentifier": {
          "system": "urn:ietf:rfc:3986",
          "value": "urn:oid:1.3.6.1.4.1.21297.100.2.1.815933567"
        },
        "identifier": [
          {
            "system": "urn:ietf:rfc:3986",
            "value": "urn:oid:1.3.6.1.4.1.21297.100.2.1.815933567"
          }
        ],
        "status": "current",
        "docStatus": "final",
        "category": [
          {
            "coding": [
              {
                "system": "https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction",
                "code": "labresult",
                "display": "Laboratory Result"
              }
            ]
          }
        ],
        "type": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "11502-2",
              "display": "Laboratory report"
            }
          ]
        },
        "subject": {
          "identifier": {
            "system": "https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/ssin",
            "value": "79080412345"
          }
        },
        "date": "2026-03-15T10:30:00Z",
        "author": [
          { "display": "CoZo Regional Hub" },
          { "display": "UZ Leuven" },
          { "display": "Dr. Danièle Govaerts" }
        ],
        "content": [
          {
            "attachment": {
              "contentType": "application/fhir+json",
              "language": "nl-BE",
              "url": "https://hub.cozo.be/fhir/Bundle/bundle-lab-report-example-01",
              "size": 28450,
              "hash": "f8b65287e00a30b2c39d881e155209d840a32e42",
              "title": "Lab Report - Peeters Jan"
            },
            "format": {
              "system": "https://www.ehealth.fgov.be/standards/fhir/interhub/CodeSystem/be-cs-interhub-format-codes",
              "code": "urn:be:fgov:ehealth:lab:document:1.0",
              "display": "Belgian Lab Report FHIR Document (v1.0)"
            }
          }
        ]
      }
    }
  ]
}
```

### 2.4 Multi-Hub Aggregation & Partial Failure Handling

When an Initiating Hub federates a query across multiple responding regional hubs:
1. **Aggregation**: The gateway merges the document entries into a unified searchset bundle.
2. **Deduplication**: Identical documents indexed across multiple hubs (sharing the same `masterIdentifier` or `uniqueId`) are consolidated.
3. **Partial Failures (`OperationOutcome`)**: If one regional hub is unreachable or returns an error, the initiating gateway returns **HTTP 200 OK** containing all successfully retrieved entries, alongside a contained `OperationOutcome` resource with severity `warning` detailing the failed community:

```json
{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "warning",
      "code": "timeout",
      "diagnostics": "Timeout communicating with Responding Hub Bruhealth (urn:oid:1.3.6.1.4.1.21297.1.1). Results from this hub may be omitted."
    }
  ]
}
```

---

## 3. Transaction 2: `getTransaction` (MHD ITI-68 `Retrieve Document`)

### 3.1 Trigger & Scope
Triggered when a consumer selects a document from the search results to view or import the full clinical payload.

### 3.2 HTTP Interaction

```http
GET https://hub.cozo.be/fhir/Bundle/bundle-lab-report-example-01 HTTP/1.1
Accept: application/fhir+json
Authorization: Bearer <eHealth-OAuth-Token>
```

Alternatively, servers may support the FHIR `$document` operation on the Composition resource:
```http
GET https://hub.cozo.be/fhir/Composition/comp-lab-example-01/$document HTTP/1.1
Accept: application/fhir+json
```

### 3.3 Payload Structure: Strictly FHIR Bundles of Type `document`

In the Belgian Interhub standard, **all retrieved transaction payloads are strictly Bundles of type `document` (`Bundle.type = #document`)**:

```
+-----------------------------------------------------------------------------------+
|                        FHIR BUNDLE (type = "document")                            |
|                                                                                   |
|  Bundle.identifier  : Universal Document ID (urn:oid:... or urn:uuid:...)        |
|  Bundle.timestamp   : Document Creation Timestamp (UTC instant)                   |
|                                                                                   |
|  +-----------------------------------------------------------------------------+ |
|  | entry[0] : ROOT COMPOSITION (BeInterhubLabComposition / BeTelemonitoring)  | |
|  |  - Subject       : Reference(Patient)                                       | |
|  |  - Author        : Reference(Practitioner / Organization)                   | |
|  |  - Title & Date  : Clinical Title & Document Date                           | |
|  |  - Section[]     : Narrative text.div + Entry references                    | |
|  +-----------------------------------------------------------------------------+ |
|                                                                                   |
|  +-----------------------------------------------------------------------------+ |
|  | entry[1..N] : REFERENCED CLINICAL & CONTEXTUAL RESOURCES                    | |
|  |  - DiagnosticReport                                                         | |
|  |  - Observation(s)                                                           | |
|  |  - Specimen / Device / CarePlan                                             | |
|  |  - Patient (with SSIN)                                                      | |
|  |  - Practitioner / Organization / PractitionerRole                           | |
|  +-----------------------------------------------------------------------------+ |
+-----------------------------------------------------------------------------------+
```

#### Bundle Constraints:
* **`Bundle.type`**: Fixed to `#document`. No other bundle types (`collection`, `transaction`, `batch`) are permitted for shared clinical document payloads.
* **`Bundle.entry[0]`**: MUST be a valid `Composition` conforming to the relevant profile (`BeInterhubLabComposition`, `BeTelemonitoringComposition`, etc.).
* **Narrative Requirement (`Composition.section.text`)**: In accordance with FHIR and Belgian clinical safety guidelines, every section MUST include human-readable XHTML narrative (`status = #generated` or `#extensions`), ensuring safe rendering on any clinical workstation.
* **Completeness**: The document bundle must be **self-contained**. All resources referenced in the Composition sections must be bundled inside the `Bundle.entry` array.

---

## 4. Error Codes & Exception Crosswalk

| KMEHR SOAP Fault / Exception | HTTP Status | FHIR `OperationOutcome.issue.code` | Remediation / Clinical Context |
| :--- | :--- | :--- | :--- |
| **`Invalid patient identifier`** | `400 Bad Request` | `value` / `invalid` | The supplied SSIN is malformed or checksum failed. |
| **`Therapeutic link does not exist`** | `403 Forbidden` | `forbidden` / `security` | Requesting practitioner does not have an active therapeutic link with the patient. |
| **`National consent missing`** | `403 Forbidden` | `suppressed` | Patient has not given consent to share health records via the eHealth platform. |
| **`Document withheld by physician`** | `403 Forbidden` | `forbidden` | Patient access is withheld (`PatientAccess = no` or `never`). |
| **`No transaction found with provided id`** | `404 Not Found` | `not-found` | The requested document uniqueId does not exist in the repository. |
| **`Owner outside of network`** | `502 Bad Gateway` | `exception` | The target repository or home community is unreachable. |
| **`Technical error`** | `500 Internal Error` | `transient` / `exception` | Internal repository failure. |
