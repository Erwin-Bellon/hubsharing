# Interhub Security & Authentication Architecture

> **Where this page sits in the guide** — *Specification*, page 3 of 4. [Architecture §5](architecture.html#5-trust-model-security-architecture--connection-routes-proposal) introduces the trust model in a few paragraphs as part of the ecosystem overview; **this page is the full specification and takes precedence** over that summary.
>
> * **Owned by this page:** the Interhub trust model, the three authentication routes, DPoP / RFC 9421 tamper-proofing, the initiating/responding responsibility split, and IHE BALP auditing.
> * **Not covered here:** payload (application-layer) encryption, which is a separate and non-normative discussion → [End-to-End Encryption](end-to-end-encryption.html); the transactions being secured → [Transactions](transactions.html); the patient-access metadata the initiating hub enforces → [Envelope & Metadata](envelope-and-metadata.html#32-belgian-patient-access-metadata-beextpatientaccess).
> * **Previous:** [Transactions](transactions.html) · **Next:** [End-to-End Encryption](end-to-end-encryption.html)

## 1. Security Overview & Trust Model

This page specifies security for **Interhub connections only**: the hub-to-hub channel between an **initiating hub** and a **responding hub**. It does not specify how a hub decides whether a given practitioner may see a given patient's records — that decision belongs entirely to the initiating hub (see §1.1).

Transitioning from legacy SOAP/WS-Security protocols to RESTful HL7® FHIR® requires modernizing authentication and transport security while maintaining full compliance with Belgian health privacy laws, GDPR, and medical confidentiality.

The security architecture of the Belgian Interhub FHIR ecosystem is based on four foundational pillars:
1. **Transport Layer Security**: Mandatory **TLS 1.3** (or TLS 1.2 with strict cipher suites) with mutual certificate authentication (**mTLS**) using official Belgian eHealth organization certificates.
2. **Three Hub Authentication Routes (Proposal)**: Flexible connection models evaluating direct Hub-to-Hub federation, the national eHealth IAM infrastructure, and a bridge for legacy systems via Security Token Service (STS) token exchange. These routes establish **which hub is calling**, nothing more.
3. **Replay & Query Tamper-Proofing**: Application-layer cryptographic request binding via **DPoP (RFC 9449)** or **RFC 9421 (HTTP Message Signatures)**, replacing legacy SOAP SAML signatures to prevent query tampering and replay attacks.
4. **Auditability & Traceability**: Comprehensive audit logging conforming to **IHE BALP (Basic Audit Logging Pattern)** and **IHE ATNA (Audit Trail and Node Authentication)**, fulfilling the legal requirements of the legacy `getTransactionAccessList` service.

Payload (application-layer) encryption is deliberately **not** one of these pillars. Whether Belgium should keep KMEHR-style end-to-end encryption in FHIR is an open architectural question, analysed separately in [End-to-End Encryption](end-to-end-encryption.html#4-architectural-analysis-should-belgium-continue-e2ee-in-fhir).

### 1.1 Trust Model: Access Control Is the Initiating Hub's Responsibility

Interhub is a **trusted federation of hubs**. Once a responding hub has authenticated the calling hub (mTLS plus one of the three routes below), it **inherently trusts that hub** and answers the request. A responding hub does **not** re-evaluate whether the end user behind the request is entitled to the patient's data.

* **The initiating hub performs all access control**, before it issues any Interhub call. How it does so is a local matter and outside the scope of this specification. For example, a hub may query the **Metahub** to confirm that an informed consent (IC) and/or a therapeutic link exists for the patient/practitioner pair, or it may resolve the same facts from its own local database and local patient/practitioner administration.
* **The responding hub performs technical validation only**: transport and hub authentication, request freshness and tamper-proofing, syntactic validity of the query, and audit logging. It does not verify informed consent, therapeutic links, practitioner entitlement, or end-user roles, and it does not issue access decisions on the initiating hub's behalf.
* **The initiating hub is accountable** for the lawfulness of every Interhub request it emits, and its audit trail is the record of the access decision that justified it.

The Metahub and the federation of hubs referred to here are described in [Architecture §1](architecture.html#1-the-belgian-federated-health-ecosystem); the same trust model appears in summary form in [Architecture §5.1](architecture.html#51-trust-model-the-initiating-hub-owns-access-control). The document-level access rules an initiating hub applies (`access`, `accessDate`, `deniedReason`) are carried in the metadata envelope specified in [Envelope & Metadata §3.2](envelope-and-metadata.html#32-belgian-patient-access-metadata-beextpatientaccess).

```mermaid
flowchart LR
    User["<b>End User / Local System</b><br/>(Practitioner, EHR, Portal)"]
    subgraph Init["<b>INITIATING HUB</b>"]
        AC["<b>Access Control (local responsibility)</b><br/>• e.g. Metahub query: does an IC exist?<br/>• e.g. local database: therapeutic link,<br/>&nbsp;&nbsp;patient administration, local rules<br/>• Decision recorded in local audit trail"]
    end
    subgraph Resp["<b>RESPONDING HUB</b>"]
        Tech["<b>Technical validation only</b><br/>• mTLS + calling hub authentication<br/>• Replay / tamper-proofing (DPoP or RFC 9421)<br/>• Query syntax<br/>• AuditEvent logging"]
    end

    User --> AC
    AC -->|"Interhub request<br/>(only if the local check passed)"| Tech
    Tech -->|"Trusted response"| AC
```

---

## 2. The Three Authentication & Connection Routes (Proposal)

To accommodate various client environments (modern cloud EHRs, regional hub nodes, mobile applications, and legacy hub source middleware), the Belgian Interhub specification evaluates **three distinct authentication routes**. All three answer a single question — *which hub is calling, and is the request untampered?* — and none of them carries an access decision about the patient's records. 

> **Important Architectural Note**: Presenting three connection models is **an architectural proposal**. For the final normative standard, the Belgian healthcare ecosystem **must pick one of these three methods** as the unified national authentication framework.

```mermaid
flowchart TD
    subgraph Routes["<b>Three Interhub Authentication Routes (Proposal Under Evaluation)</b>"]
        direction LR
        subgraph Route1["<b>Proposal 1: Hub/Enterprise JWT</b>"]
            R1["<b>Direct Hub Federation</b><br/>• Asymmetric signed JWTs<br/>• Validated via Hub JWKS"]
        end
        subgraph Route2["<b>Proposal 2: eHealth IAM</b>"]
            R2["<b>National OIDC IdP</b><br/>• eID / itsme® / Enterprise cert<br/>• Federated hub & organisation identity"]
        end
        subgraph Route3["<b>Proposal 3: STS Bridge</b>"]
            R3["<b>Legacy SAML Exchange</b><br/>• eHealth SOAP STS assertions<br/>• RFC 8693 Token Exchange"]
        end
    end

    Responder["<b>BELGIAN INTERHUB FHIR RESPONDER</b><br/>(Authenticates the calling hub: signature via JWKS;<br/>records SSIN, NIHDI, CBE claims for audit)"]

    Route1 -->|"Bearer JWT<br/>(Hub Private Key)"| Responder
    Route2 -->|"Bearer JWT<br/>(eHealth OIDC AS)"| Responder
    Route3 -->|"1. SAML 2.0 Assertion"| TokenGateway["<b>Token Exchange Gateway</b><br/>(RFC 8693 SAML2 to JWT)"]
    TokenGateway -->|"2. Short-lived Bearer JWT"| Responder
```

---

### 2.1 Route 1: Hub/Enterprise-Issued JWT Bearer Tokens (Federated Trust)

In this route, eHealth Hubs (e.g. CoZo, RSW, BHN, Zodap) or major healthcare enterprises operate their own **OAuth 2.0 token issuers**. Trust between hubs is established bilaterally or through a national hub federation trust registry. The token asserts the identity of the calling hub and carries the contextual claims needed for the responding hub's audit trail; it does not convey an access decision, which the initiating hub has already made locally.

#### Mechanics & Workflow:
1. The initiating client authenticates against its local Hub Authorization Server using the **OAuth 2.0 Client Credentials Flow** with asymmetric private key JWT authentication (`private_key_jwt`).
2. The local Hub AS issues a signed JSON Web Token (JWT) using its private RSA/ECDSA key.
3. The client presents the JWT in the HTTP `Authorization: Bearer <jwt>` header when calling the target hub's FHIR endpoints.
4. The responding hub validates the token signature using the issuer's public keys published at its **JSON Web Key Set (JWKS)** endpoint (`/.well-known/jwks.json`), confirms the issuer is a trusted hub, and records the asserted claims in its audit trail.

#### Sample Interhub JWT Claims Payload:
```json
{
  "iss": "https://auth.cozo.be",
  "sub": "client-source-uzl",
  "aud": "https://hub.bhn.be/fhir",
  "exp": 1773766800,
  "nbf": 1773763200,
  "iat": 1773763200,
  "jti": "b3e94a8c-9c71-4e78-9e51-12f8e12a4b89",
  "be:hub_origin": "urn:oid:1.3.6.1.4.1.21297.1.3",
  "be:practitioner": {
    "nihdi": "19876543201",
    "ssin": "65031212345",
    "name": "Dr. Jean Depondt",
    "role": "persphysician"
  },
  "be:organization": {
    "nihdi": "71000012",
    "cbe": "0419052173",
    "name": "UZ Leuven"
  },
  "be:patient_context": {
    "ssin": "79080412345"
  }
}
```

> The `be:practitioner`, `be:organization`, and `be:patient_context` claims exist so that the responding hub can write a complete, legally usable `AuditEvent`. They are **not** inputs to an access decision at the responding hub: the initiating hub has already established the practitioner's entitlement before emitting the call.

---

### 2.2 Route 2: eHealth Platform IAM (National Identity Provider)

In this route, authentication of the calling party is centralized through the **Belgian eHealth Platform IAM** infrastructure. IAM is used here purely as an identity provider for hubs, organisations, and their users; the access decision on the patient's records remains with the initiating hub.

#### Mechanics & Workflow:
1. **User Authentication**:
   * Interactive users (physicians, nurses, patients) authenticate via **eID**, **itsme®**, or TOTP mobile tokens.
   * Automated systems authenticate using **eHealth Enterprise Certificates**.
2. **Identity & Role Resolution**:
   * eHealth IAM validates the professional's credentials against federal authoritative databases: **CoBRHA** (healthcare institutions), **Federal Health Professionals Database** (NIHDI licenses), and **Crossroads Bank for Enterprises (CBE)**.
3. **Token Issuance**:
   * eHealth IAM issues signed OAuth 2.0 Access Tokens and OIDC ID Tokens containing standardized federal health claims (`https://ehealth.fgov.be/claims/...`).
4. **Consumption**:
   * Any participating regional hub or repository verifies the token against the official eHealth JWKS endpoint (`https://iam.ehealth.fgov.be/.well-known/jwks.json`) to establish the identity of the calling hub, and logs the resolved identities.

---

### 2.3 Route 3: Derived System Based on STS (SAML 2.0 to OAuth 2.0 Bridge)

Many Belgian hub source systems (hospital EHRs, laboratory information systems, pharmacy and practice software) and legacy connector middleware already integrate with the **eHealth Security Token Service (STS)** using SOAP WS-Trust and SAML 2.0 tokens (signed with physical eHealth X.509 keystores).

To enable these legacy systems to consume modern FHIR RESTful Interhub endpoints without an immediate, costly rewrite of their authentication stack, an **STS Token Exchange Gateway** is deployed:

```mermaid
sequenceDiagram
    autonumber
    participant Src as Legacy Hub Source System (Hospital / Lab / Practice)
    participant STS as eHealth Platform STS (WS-Trust)
    participant Bridge as Interhub Token Exchange Service (RFC 8693)
    participant Responder as Belgian Interhub FHIR Responder

    Src->>STS: 1. Request SAML 2.0 Token (SOAP WS-Trust with Keystore)
    STS-->>Src: 2. Return Signed SAML 2.0 Assertion
    Src->>Bridge: 3. POST /oauth/token<br/>(grant_type=token-exchange, subject_token=SAML2, audience=hub)
    Note over Bridge: • Validates SAML signature against eHealth Trust Chain<br/>• Extracts NIHDI, CBE, SSIN, and Role assertions (for audit)<br/>• Verifies validity window
    Bridge-->>Src: 4. Return short-lived OAuth 2.0 JWT Access Token
    Src->>Responder: 5. GET /fhir/DocumentReference (Authorization: Bearer JWT)
    Responder-->>Src: 6. HTTP 200 OK (FHIR Response)
```

#### RFC 8693 Token Exchange Request Example:
```http
POST /oauth/token HTTP/1.1
Host: auth-gateway.ehealth.fgov.be
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:token-exchange
&client_id=hubsource-connector-uzl
&subject_token=PHNhbWwycDpBc3NlcnRpb24geG1sbnM6c2FtbDJwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXNzZXJ0aW9uIi...
&subject_token_type=urn:ietf:params:oauth:token-type:saml2
&audience=https://hub.cozo.be/fhir
```

#### Response:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

## 3. Replay Attack Prevention & Query Tamper-Proofing: DPoP (RFC 9449) & RFC 9421

### 3.1 The Challenge: Replacing Legacy SOAP SAML Request Signatures

In the legacy KMEHR SOAP ecosystem, every outbound transaction was protected by **WS-Security** and **SAML 2.0 XML-DSig**. The calling client signed the complete SOAP envelope (including `<wsu:Timestamp>`, `<wsse:Nonce>`, and the entire request body/query parameters) using its physical eHealth certificate. This guaranteed two essential security properties:
1. **Anti-Replay**: An eavesdropper or malicious actor could not capture an authorization token or query and re-execute it later.
2. **Query Tamper-Proofing**: A compromised proxy or rogue intermediary could not modify the query parameters (e.g. altering the patient SSIN or manipulating clinical category filters in transit).

In a RESTful HL7® FHIR® environment, bearer tokens alone (`Authorization: Bearer <token>`) are vulnerable to interception and can theoretically be reused with altered URL parameters or replayed until expiration. To achieve cryptographic equivalence with legacy SOAP SAML signatures, the Belgian Interhub specification evaluates two standardized HTTP-level tamper-proofing mechanisms:

```mermaid
flowchart TD
    subgraph Request["<b>Initiating Client / Hub Request</b>"]
        URI["<b>HTTP Target URI & Query</b><br/>GET /DocumentReference?patient.identifier=ssin|79080412345&category=labresult"]
        Key["<b>Sender Private Key</b><br/>(DPoP Key or eHealth Enterprise Key)"]
    end

    subgraph SecurityHeaders["<b>Cryptographic Proof Headers</b>"]
        direction TB
        DPoP["<b>Option A: DPoP Proof (RFC 9449)</b><br/>• htu: https://hub.cozo.be/fhir/DocumentReference<br/>• htm: GET<br/>• jti: unique-nonce-uuid<br/>• iat: current-timestamp"]
        HTTPsig["<b>Option B: HTTP Message Signature (RFC 9421)</b><br/>• @method: GET<br/>• @target-uri: full query string<br/>• Signature-Input: keyid, created, nonce"]
    end

    subgraph TargetHub["<b>Responding eHealth Hub (Verification)</b>"]
        direction TB
        V1["1. Validate Bearer Token & Issuer Signature"]
        V2["2. Verify Proof Signature against Sender Key"]
        V3["3. Match Target URI / Query against Signed Proof"]
        V4["4. Check Freshness Window (30-60s) & Nonce Cache"]
    end

    URI --> SecurityHeaders
    Key --> SecurityHeaders
    SecurityHeaders -->|"HTTP Request + Proof Headers"| TargetHub
```

---

### 3.2 Option A: Demonstrating Proof-of-Possession (DPoP - RFC 9449)

**DPoP (RFC 9449)** is the IETF and SMART on FHIR standard for sender-constraining OAuth 2.0 access tokens and binding individual REST calls to an asymmetric key-pair held by the client.

#### Mechanics & Workflow:
1. The calling hub generates an asymmetric key-pair (RSA or ECDSA) and creates a signed **DPoP Proof JWT** for every outbound HTTP request.
2. The DPoP header binds the exact HTTP method (`htm`), target HTTP URI (`htu`), timestamp (`iat`), unique identifier (`jti`), and an optional server-provided `nonce`.
3. The responding hub:
   * Validates that the access token is thumbprint-bound (`cnf.jkt`) to the public key in the DPoP header.
   * Confirms that `htu` and `htm` match the incoming request.
   * Verifies that the `iat` timestamp is within the acceptable freshness window (**30 to 60 seconds**) and checks `jti` against a replay cache.
   * Rejects any request where query parameters or URIs were manipulated in transit.

#### Sample DPoP HTTP Request:
```http
GET /fhir/DocumentReference?patient.identifier=https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/ssin|79080412345&category=labresult HTTP/1.1
Host: hub.cozo.be
Authorization: DPoP eyJhbGciOiJSUzI1NiIsInR5cCI6ImF0K2p3dCIsImN0eSI6IkpXVCJ9...
DPoP: eyJ0eXAiOiJkcG9wK2p3dCIsImFsZyI6IkVTMjU2IiwiandrIjp7Imt0eSI6IkVDIiwiY3J2IjoiUC0yNTYiLCJ4IjoiZ...
```

#### Decoded DPoP Proof Header (`DPoP` JWT):
```json
{
  "header": {
    "typ": "dpop+jwt",
    "alg": "ES256",
    "jwk": {
      "kty": "EC",
      "crv": "P-256",
      "x": "f83OJ3D2xFmT4v7...",
      "y": "x_da7WjWiqOW0C6..."
    }
  },
  "payload": {
    "jti": "b59a86a6-9907-4279-8b6a-939e4a3b1a8d",
    "htm": "GET",
    "htu": "https://hub.cozo.be/fhir/DocumentReference",
    "iat": 1773763200,
    "nonce": "k3L90xPz-1m9"
  }
}
```

---

### 3.3 Option B: HTTP Message Signatures (RFC 9421)

If Belgian healthcare regulations or legal frameworks mandate an immutable audit trail signed directly with the healthcare institution's official **eHealth Enterprise Certificate (X.509)** rather than an ephemeral OAuth client key, **RFC 9421 (HTTP Message Signatures)** provides cryptographic signing of HTTP messages.

#### Mechanics & Workflow:
1. The calling system signs the HTTP request components (`@method`, `@target-uri`, `authorization`, and optional `content-digest` for POST/PUT payloads) using its official Belgian eHealth private key.
2. The request carries standard `Signature-Input` and `Signature` headers.
3. The responding hub validates the signature against the eHealth certificate trust chain, verifying that no query parameters (including `patient.identifier` and `category`) were altered.

#### Sample RFC 9421 HTTP Request:
```http
GET /fhir/DocumentReference?patient.identifier=https://www.ehealth.fgov.be/standards/fhir/core/NamingSystem/ssin|79080412345&category=labresult HTTP/1.1
Host: hub.cozo.be
Authorization: Bearer eyJhbGciOiJSUzI1Ni...
Signature-Input: sig1=("@method" "@target-uri" "authorization");created=1773763200;keyid="ehealth:cbe:0419052173";nonce="8f2a9e3d";alg="rsa-v1_5-sha256"
Signature: sig1=:MEUCIQDxZ8Y7j...kL9A1wP==:
```

---

### 3.4 Alignment with the Three Proposed Authentication Routes

The table below illustrates how Replay & Query Tamper-Proofing integrates into each of the 3 proposed authentication routes:

| Security Dimension | Proposal 1: Hub-Issued JWTs (Direct Federation) | Proposal 2: eHealth Platform IAM (National OIDC) | Proposal 3: STS Token Exchange Bridge (RFC 8693) |
| :--- | :--- | :--- | :--- |
| **Tamper-Proofing Standard** | **DPoP (RFC 9449)** or **RFC 9421** | **DPoP (RFC 9449)** with eHealth IAM AS | **RFC 9421** / Gateway-enforced DPoP |
| **Signing Key** | Hub private key (published via JWKS) | Client DPoP key or eHealth Enterprise Cert | Legacy X.509 Keystore / STS Gateway Key |
| **Signed Elements** | `htm`, `htu` (Target URI), `jti`, `iat`, `nonce` | `htm`, `htu`, `jti`, `iat`, IAM Nonce | `@method`, `@target-uri`, SAML assertions |
| **Freshness Window** | 30–60 seconds | 30–60 seconds | Enforced by STS token exchange TTL |
| **SOAP Equivalence** | 100% equivalent to SAML XML-DSig | 100% equivalent to SAML XML-DSig | Translates SAML XML-DSig directly |

---

## 4. Division of Responsibility Between Initiating and Responding Hub

The table below restates the trust model of §1.1 as a checklist for implementers:

| Concern | Initiating Hub | Responding Hub |
| :--- | :--- | :--- |
| **Identifying and authenticating the end user** (practitioner, application, patient portal) | Yes — locally, before any Interhub call | No |
| **Establishing informed consent (IC) and therapeutic links** | Yes — e.g. by querying the Metahub, or from its own local database | No |
| **Applying local rules on confidentiality and patient access metadata** | Yes | No |
| **Deciding that an Interhub request is lawful** | Yes | No — it trusts the calling hub |
| **mTLS and calling-hub authentication** | Presents its credentials | Yes |
| **Replay / tamper-proofing (DPoP or RFC 9421)** | Signs the request | Verifies the proof |
| **Query syntax and profile conformance** | Builds a valid query | Yes |
| **Audit logging (IHE BALP `AuditEvent`)** | Yes — including the access decision | Yes — including the identity of the calling hub |

Consequently, a responding hub **MUST NOT** answer an Interhub query with an access-related refusal such as *"no therapeutic link"* or *"no informed consent"*: it has neither the information nor the mandate to make that determination. Requests that fail hub authentication or tamper-proofing are of course rejected on technical grounds (`401` / `403`), and a hub may still refuse a syntactically invalid or unsupported query.

---

## 5. Audit Trail & Traceability (`getTransactionAccessList` $\longleftrightarrow$ IHE BALP)

Under Belgian law (Patient Rights Act & eHealth Platform Law), every access, search, and retrieval of medical records must be immutably recorded for auditability. In the legacy KMEHR world, the `getTransactionAccessList` SOAP service exposed access logs.

Because the responding hub trusts the calling hub, the audit trail on both sides is what makes an Interhub exchange reconstructable after the fact: the initiating hub logs the access decision it made and the identity of the end user it made it for, and the responding hub logs which hub asked for what.

In the FHIR Interhub standard, auditing is standardized using **IHE BALP (Basic Audit Logging Pattern)** and **IHE ATNA** generating FHIR **`AuditEvent`** resources. The `subtype` values below (`ITI-67`, `ITI-68`) refer to the two transactions specified in [Transactions](transactions.html), and the document identifiers logged as entities come from the envelope specified in [Envelope & Metadata](envelope-and-metadata.html):

```mermaid
classDiagram
    class AuditEvent {
        +type: DCM #110112 ("Query") / #110106 ("Export")
        +subtype: ITI-67 ("FindDocumentReferences") / ITI-68 ("RetrieveDocument")
        +action: "E" (Execute) / "R" (Read)
        +recorded: 2026-03-15T10:30:05Z (instant)
        +outcome: "0" (Success) / "4" (Minor failure)
    }
    class AgentPractitioner {
        +type: Practitioner (Requestor)
        +identifier: NIHDI 19876543201 / SSIN 65031212345
        +name: Dr. Jean Depondt
    }
    class AgentOrganization {
        +type: Healthcare Organization
        +identifier: NIHDI 71000012 / CBE 0419052173
        +name: UZ Leuven
    }
    class AgentHub {
        +type: Regional Hub Gateway
        +identifier: urn:oid:1.3.6.1.4.1.21297.1.3 (CoZo)
    }
    class EntityPatient {
        +type: Patient (Subject)
        +identifier: SSIN 79080412345
    }
    class EntityDocument {
        +type: DocumentReference / Bundle
        +what: urn:oid:1.3.6.1.4.1.21297.100.2.1.815933567
    }

    AuditEvent --> AgentPractitioner : agent[0]
    AuditEvent --> AgentOrganization : agent[1]
    AuditEvent --> AgentHub : agent[2]
    AuditEvent --> EntityPatient : entity[0]
    AuditEvent --> EntityDocument : entity[1]
```

These `AuditEvent` records are retained by the answering hubs for the legally mandated period (minimum 10 years in Belgium) and made accessible to patients via national transparency portals.

---

## Continue reading

* **Previous:** [Transactions](transactions.html) — the ITI-67 / ITI-68 calls secured by this page.
* **Next:** [End-to-End Encryption](end-to-end-encryption.html) — the separate, non-normative question of encrypting the payload itself on top of the transport security specified here.
* **Related:** [Architecture §5](architecture.html#5-trust-model-security-architecture--connection-routes-proposal) for the same trust model in summary form; [Envelope & Metadata §3.2](envelope-and-metadata.html#32-belgian-patient-access-metadata-beextpatientaccess) for the patient-access metadata an initiating hub enforces.
