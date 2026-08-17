# Document Envelope & Metadata Specification

## 1. Overview of the Metadata Model

In the Belgian Interhub ecosystem, document discovery is strictly separated from document retrieval. When querying for available health records (`getTransactionList`), client applications receive a lightweight metadata envelope: the **`BeInterhubDocumentReference`**.

This metadata envelope provides:
1. **Clinical Context**: Document category (`CD-TRANSACTION`), precise clinical type (LOINC), clinical encounter period, and confidentiality level.
2. **Author & Institutional Attribution**: Answering hub, originating hospital, and authoring healthcare practitioner.
3. **Retrieval & Routing Endpoints**: The exact RESTful URL to fetch the full FHIR Document Bundle (`type = #document`), accompanied by the repository Home Community ID.
4. **Integrity & Technical Payload Characteristics**: Cryptographic hash (SHA-1/SHA-256), exact byte size, MIME content type (`application/fhir+json`), and document format code.
5. **Belgian Governance & Access Rules**: Granular patient portal access permissions, release dates, and end-to-end encryption metadata.

---

## 2. Element-by-Element Specification (`BeInterhubDocumentReference`)

| Element | Card. | Type | Description & Belgian Mapping Rule |
| :--- | :--- | :--- | :--- |
| **`masterIdentifier`** | `0..1` | `Identifier` | Globally unique master identifier for this version of the document, formatted as an RFC 3986 URI (e.g., `urn:oid:1.3.6.1.4.1.21297.100.2.1.815933567` or `urn:uuid:...`). |
| **`identifier[uniqueId]`** | `1..1` | `Identifier` | Universal document entry identifier. Must use `system = "urn:ietf:rfc:3986"`. Directly maps to `XDSDocumentEntry.uniqueId` and KMEHR `transactionSummary/id`. |
| **`identifier[localId]`** | `0..*` | `Identifier` | Local identifier assigned by the originating hospital vault or laboratory system (e.g. `LAB-2026-03-815933567`). |
| **`status`** | `1..1` | `code` | Metadata lifecycle status: `current` (approved and active), `superseded` (replaced by a newer version), or `entered-in-error`. |
| **`docStatus`** | `0..1` | `code` | Clinical status of the underlying document: `preliminary`, `final`, `amended`. Mapped from KMEHR `iscomplete` / `isvalidated`. |
| **`category[cdTransaction]`** | `1..1` | `CodeableConcept` | Document category coded using the Belgian `CD-TRANSACTION` code system (`https://www.ehealth.fgov.be/standards/fhir/core/CodeSystem/cd-transaction`, OID `1.3.6.1.4.1.21297.100.3.1`). Examples: `sumehr`, `labresult`, `discharge`, `telemonitoring`, `note`, `referral`. |
| **`type`** | `1..1` | `CodeableConcept` | Precise clinical document type. Must use LOINC (e.g., `11502-2` for Laboratory Report, `10185-7` for Holter Study, `34133-9` for Summarization of Episode) or Belgian clinical type codes. |
| **`subject`** | `1..1` | `Reference(Patient)` | Reference to the patient. The referenced Patient resource must contain the official Belgian Social Security Identification Number (**SSIN / INSS**). |
| **`date`** | `1..1` | `instant` | Timestamp when the document metadata entry was created/indexed, standardized in **UTC (Z)** format (ISO 8601 `YYYY-MM-DDThh:mm:ssZ`). |
| **`author`** | `1..*` | `Reference(...)` | Sequence of authors. In Belgian Hub rules, author references follow a specific order of granularity: (1) Answering Hub, (2) Originating Hospital / Institution, (3) Authoring Practitioner / Physician. |
| **`authenticator`** | `0..1` | `Reference(...)` | Healthcare professional or organization legally validating/attesting the document. |
| **`custodian`** | `0..1` | `Reference(Organization)` | Organization responsible for the long-term maintenance of the document record (e.g., hospital vault). |
| **`relatesTo`** | `0..*` | `BackboneElement` | Explicit relationships to previous documents (e.g., `replaces` for amended documents, `appends` for addenda). |
| **`description`** | `0..1` | `string` | UTF-8 human-readable document title or caption (e.g., *"Comprehensive Blood Biochemistry and Hematology Laboratory Report"*). |
| **`securityLabel`** | `0..*` | `CodeableConcept` | Confidentiality classification from HL7 v3 Confidentiality (`N` = Normal, `R` = Restricted, `V` = Very Restricted / Secret). |
| **`content.attachment.contentType`** | `1..1` | `code` | MIME type of the document payload. For Belgian Interhub document sharing, this is **`application/fhir+json`** (or `application/fhir+xml`). Fallback binary formats like `application/pdf` are also supported. |
| **`content.attachment.language`** | `0..1` | `code` | BCP-47 / RFC 5646 language tag (`nl-BE`, `fr-BE`, `de-BE`, `en`). |
| **`content.attachment.url`** | `1..1` | `url` | Direct RESTful URL to retrieve the full FHIR Document Bundle (MHD ITI-68 retrieve endpoint, e.g. `https://hub.cozo.be/fhir/Bundle/bundle-lab-report-example-01`). |
| **`content.attachment.size`** | `0..1` | `unsignedInt` | Uncompressed byte size of the document payload. |
| **`content.attachment.hash`** | `0..1` | `base64Binary` | Cryptographic SHA-1 (or SHA-256) hash of the raw document payload, Base64-encoded. |
| **`content.attachment.title`** | `0..1` | `string` | Display title for the attachment. |
| **`content.format`** | `0..1` | `Coding` | Format code identifying the document specification (e.g. `urn:be:fgov:ehealth:lab:document:1.0`, `urn:be:fgov:ehealth:telemonitoring:document:1.0`). |
| **`context.period`** | `0..1` | `Period` | Start and end date/time of the clinical encounter, hospital stay, or telemonitoring monitoring session. |
| **`context.facilityType`** | `0..1` | `CodeableConcept` | Healthcare facility classification (Belgian Facility Type OID `1.3.6.1.4.1.21297.100.4.1`). |
| **`context.practiceSetting`** | `0..1` | `CodeableConcept` | Clinical medical specialty / practice setting (Belgian Practice Setting OID `1.3.6.1.4.1.21297.100.5.1`). |

---

## 3. Belgian Extensions Deep-Dive

### 3.1 Home Community ID (`BeExtHomeCommunityId`)
* **URL**: `https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-home-community-id` (or `urn:ihe:iti:xds:2023:homeCommunityId`)
* **Cardinality**: `1..1` (Mandatory for Interhub exchanges)
* **Value**: `uri` (e.g., `urn:oid:1.3.6.1.4.1.21297.1.3` for CoZo, `urn:oid:1.3.6.1.4.1.21297.1.1` for Bruhealth / Abrumet)
* **Purpose**: Identifies the regional hub responsible for managing the document. Essential for cross-community federation, allowing initiating gateways to route retrieve calls to the correct responding hub.

### 3.2 Belgian Patient Access Metadata (`BeExtPatientAccess`)
In the Belgian healthcare system, patients have a legal right to access their medical records via certified national/regional portals (e.g. MaSanté / MijnGezondheid). However, physicians may withhold or delay document release under specific clinical circumstances (therapeutic exception or pending consultation).

* **URL**: `https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-patient-access`
* **Sub-extensions**:
  1. `access` (`code`, `1..1`, ValueSet: `BeVSPatientAccess`):
     * `yes`: Document is accessible to the patient (subject to optional release date).
     * `no`: Document is temporarily not accessible to the patient. May be released later by the treating physician.
     * `never`: Document is permanently restricted from patient access.
  2. `accessDate` (`date`, `0..1`): Release date (inclusive) after which the document becomes visible on patient portals. Only valid when `access = yes`.
  3. `deniedReason` (`string`, `0..1`): Textual explanation why the document is withheld from the patient (applicable when `access = no` or `never`).

### 3.3 End-to-End Encryption Metadata (`BeExtEndToEndEncryption`)
For cross-enterprise transmissions requiring application-level encryption:
* **URL**: `https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-end-to-end-encryption`
* **Sub-extensions**:
  1. `actorId` (`string`, `1..1`): Identifier of the encryption recipient (NIHDI number, CBE number, or SSIN).
  2. `actorType` (`code`, `1..1`, ValueSet: `BeVSETKEncryptionActor`): `NIHII`, `NIHII-HOSPITAL`, `NIHII-PHARMACY`, `CBE`, `SSIN`, `EHP`.
  3. `applicationId` (`string`, `0..1`): Specific IT application identifier registered in the eHealth ETK depot.
  4. `keyId` (`string`, `0..1`): Encryption Token Key (ETK) identifier.

### 3.4 Source Vault Recording Timestamp (`BeExtRecordDateTime`)
* **URL**: `https://www.ehealth.fgov.be/standards/fhir/interhub/StructureDefinition/be-ext-record-datetime`
* **Cardinality**: `0..1`
* **Value**: `instant` (UTC ISO 8601)
* **Purpose**: Records the exact timestamp when the document was persisted in the originating hospital vault (corresponds to KMEHR `recorddatetime`).

---

## 4. Technical Algorithms & Developer Rules

### 4.1 Cryptographic Hash Conversion (Hexadecimal $\longleftrightarrow$ Base64)

* **Legacy KMEHR / XDS**: SHA-1 hashes are represented as a **40-character hexadecimal string** (e.g. `f8b65287e00a30b2c39d881e155209d840a32e42`).
* **FHIR R4**: `content.attachment.hash` requires a **Base64-encoded binary representation** (`base64Binary`).

#### Python Reference Implementation:
```python
import base64
import binascii

def hex_hash_to_fhir_base64(hex_str: str) -> str:
    """Converts a 40-character hex hash into FHIR base64Binary."""
    raw_bytes = binascii.unhexlify(hex_str.strip())
    return base64.b64encode(raw_bytes).decode('ascii')

def fhir_base64_to_hex_hash(b64_str: str) -> str:
    """Converts FHIR base64Binary hash into a 40-character hex string."""
    raw_bytes = base64.b64decode(b64_str.strip())
    return binascii.hexlify(raw_bytes).decode('ascii')
```

### 4.2 Timezone Normalization to UTC (Z)
In KMEHR messages, dates and times are often transmitted with local Belgian offsets (CET `+01:00` / CEST `+02:00`) or separated into `<date>` and `<time>` elements. During transformation to FHIR Interhub metadata:
1. Concatenate date and time strings.
2. Apply the correct seasonal timezone offset.
3. Standardize into **UTC ISO 8601 (`YYYY-MM-DDThh:mm:ssZ`)**.
