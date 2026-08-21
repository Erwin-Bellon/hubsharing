# Design Rationale: Why FHIR Document Bundles

> **Where this page sits in the guide** — *Architecture*, page 2 of 2. This is the **why** behind every specification page: which FHIR paradigms were evaluated, which were rejected, and why `Bundle.type = #document` plus a decoupled `DocumentReference` was mandated. Readers who wonder *"why can't I just `GET /Observation`?"* should start here.
>
> * **Owned by this page:** the carrier-paradigm evaluation, document immutability and legal attestation, and the rationale for a decoupled discovery envelope.
> * **Specified elsewhere:** the envelope fields → [Envelope & Metadata](envelope-and-metadata.html); the transactions that carry these bundles → [Transactions](transactions.html); concrete payloads → [Laboratory Reports](lab-report-sharing.html) and [Telemonitoring](mapping-telemonitoring-to-hub.html).
> * **Previous:** [Architecture & Federation Model](architecture.html) · **Next:** [Envelope & Metadata](envelope-and-metadata.html)

## 1. Context & Architectural Problem

The Belgian eHealth Hub network acts primarily as a **document sharing infrastructure**. When migrating from legacy KMEHR SOAP Web Services to HL7 FHIR R4, architects had to determine the optimal FHIR resource paradigms to balance:
1. **Clinical Integrity & Immutability**: A shared medical record (such as a laboratory report or discharge letter) must represent an authenticated snapshot in time that cannot change retroactively without explicit versioning.
2. **Metadata Discovery vs. Content Retrieval**: Separation between lightweight search operations across millions of records and targeted content retrieval.
3. **Decoupled Architecture**: Preserving autonomy between independent hub source systems (hospital EHRs, laboratory information systems, pharmacy and practice software) and regional hubs without requiring complex cross-enterprise database synchronization.
4. **European Harmonization**: Seamless alignment with the **European Health Data Space (EHDS)** and **IHE MHD** — the resulting alignment is analysed in [EHDS Alignment](ehds-alignment.html).

---

## 2. Evaluation of Evaluated Carrier Paradigms

```mermaid
flowchart TD
    subgraph Evaluation["<b>FHIR Payload Carrier Paradigm Evaluation</b>"]
        direction TB
        subgraph Opt1["<b>1. FHIR Messaging (Bundle type = message)</b>"]
            O1["• Pros: Event routing & MessageHeader semantics<br/>• Cons: Point-to-point only; lacks document registry indexing & long-term archiving<br/>• Status: ❌ <b>Rejected for Interhub Sharing</b>"]
        end
        subgraph Opt2["<b>2. Direct Granular Resource Access (GET /Observation)</b>"]
            O2["• Pros: Fine-grained query flexibility<br/>• Cons: Lacks legal attestation snapshot, document provenance & immutability<br/>• Status: ❌ <b>Rejected for Interhub Document Payloads</b>"]
        end
        subgraph Opt3["<b>3. FHIR Document Bundle (Bundle type = document)</b>"]
            O3["• Pros: Legally attested snapshot, self-contained, human-readable narrative, 100% IHE MHD & EHDS aligned<br/>• Cons: Payload must be retrieved as a whole (mitigated by BeInterhubDocumentReference)<br/>• Status: ✅ <b>SELECTED NATIONAL PARADIGM</b>"]
        end
    end
```

| Option | Pros | Cons / Reason for Rejection | Selection Status |
| :--- | :--- | :--- | :--- |
| **1. FHIR Messaging** (`Bundle.type = #message`) | Built-in MessageHeader and event routing semantics. | Point-to-point oriented; does not support document indexing, search, & archive. | ❌ Rejected |
| **2. Direct Resource Queries** (RESTful `Observation` / `DiagnosticReport`) | Fine-grained queries on individual resources (e.g. `GET /Observation`). | Lacks document integrity, authorship context, legal attestation, & immutability. | ❌ Rejected |
| **3. FHIR Document Bundle** (`Bundle.type = #document` + Root `Composition`) | Self-contained & immutable snapshot, mandatory narrative for safety, complete clinical context & author, 100% aligned with IHE MHD & EHDS. | Requires full bundle retrieval for viewing (addressed by decoupled metadata). | ✅ **SELECTED PARADIGM** (Mandated) |

### 2.1 Why FHIR Messaging (`Bundle.type = #message`) Was Not Selected
FHIR Messaging is designed for event-driven, asynchronous routing between known communication endpoints (similar to HL7 v2 messages). However, the Belgian Hub ecosystem is an **indexing, discovery, and retrieval** network, where documents must be registered, cataloged, searched years later, and retrieved on demand. Messaging lacks standard document registry query semantics (`ITI-67`).

### 2.2 Why Direct Granular RESTful Resource Access Was Not Selected
Allowing consumers to query isolated `Observation` or `DiagnosticReport` resources directly across federated hub source databases would expose operational source systems to high query loads, introduce security risks, and strip away crucial provenance, institutional authorship, and legal signatures. Furthermore, changes in the underlying source tables could mutate historical records.

### 2.3 The Mandated Solution: FHIR Document Bundles (`Bundle.type = #document`)
The Belgian Interhub standard mandates that **all shared clinical payloads are strictly exchanged as FHIR Bundles of type `document`**:
1. **Immutability & Legal Validity**: A FHIR Document is a legally attested, digitally signable snapshot in time. Once generated, its content is fixed. Revisions require creating a new document version linked via `relatesTo`.
2. **Clinical Safety Narrative (`Composition.section.text`)**: Every document section includes a human-readable XHTML narrative. Clinicians can safely view the content on any workstation, even if the receiving system does not support all discrete code systems.
3. **Self-Contained Completeness**: All resources referenced by the Composition are bundled within the `Bundle.entry` list, eliminating external URL dependencies during retrieval or long-term archiving.

The normative constraints implementing this decision (`Bundle.type`, `entry[0]`, narrative and completeness requirements) are specified in [Transactions §3.3](transactions.html#33-payload-structure-strictly-fhir-bundles-of-type-document), and shown in practice in [Laboratory Reports](lab-report-sharing.html) and [Telemonitoring](mapping-telemonitoring-to-hub.html).

---

## 3. The Role of `DocumentReference` as Discovery Envelope

In accordance with **IHE MHD (ITI-67 / ITI-68)**, the metadata envelope (`BeInterhubDocumentReference`) is decoupled from the document payload. Every element of that envelope is specified in [Envelope & Metadata](envelope-and-metadata.html#2-element-by-element-specification-beinterhubdocumentreference), and the two phases below are specified as transactions in [Transactions](transactions.html):

```mermaid
flowchart LR
    Client["Client / EHR"]
    
    subgraph Discovery["<b>1. Discovery Phase (MHD ITI-67)</b>"]
        Search["GET /DocumentReference?patient=..."]
        DocRef["<b>BeInterhubDocumentReference</b><br/>• Category: CD-TRANSACTION<br/>• Type: LOINC<br/>• Patient SSIN & Access Rules<br/>• HomeCommunityId<br/>• Payload URL Endpoint"]
        Search --> DocRef
    end

    subgraph Retrieval["<b>2. Retrieval Phase (MHD ITI-68)</b>"]
        GetDoc["GET /Bundle/{id}"]
        DocBundle["<b>BeInterhubDocumentBundle</b><br/>• Type: #document<br/>• Root Composition<br/>• Clinical Resources<br/>• XHTML Narrative"]
        GetDoc --> DocBundle
    end

    Client -->|"Query Metadata"| Discovery
    Client -->|"Fetch Full Payload"| Retrieval
```

* **Lightweight Querying**: Searching `DocumentReference` across multiple federated hubs returns small, highly indexable metadata records containing patient SSIN, CD-TRANSACTION category, LOINC type, author, date, and access rules.
* **On-Demand Retrieval**: The consumer fetches the full document payload (`Bundle` type = `document`) only when the clinician requests it, drastically reducing network bandwidth and hub resource utilization.

---

## Continue reading

* **Previous:** [Architecture & Federation Model](architecture.html) — the network these decisions apply to.
* **Next:** [Envelope & Metadata](envelope-and-metadata.html) — the discovery envelope this page justifies, specified element by element.
* **Related:** [Transactions §3.3](transactions.html#33-payload-structure-strictly-fhir-bundles-of-type-document) for the normative bundle constraints, [Laboratory Reports](lab-report-sharing.html) and [Telemonitoring](mapping-telemonitoring-to-hub.html) for what a mandated document bundle actually looks like.
