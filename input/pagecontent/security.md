# Interhub Security & Authentication Architecture

## 1. Security Overview & Trust Model

Interhub communications across the Belgian federated health data network demand robust, interoperable security controls. Transitioning from legacy SOAP/WS-Security protocols to RESTful HL7® FHIR® requires modernizing authentication, authorization, and transport security while maintaining full compliance with Belgian health privacy laws, GDPR, and medical confidentiality.

The security architecture of the Belgian Interhub FHIR ecosystem is based on five foundational pillars:
1. **Transport Layer Security**: Mandatory **TLS 1.3** (or TLS 1.2 with strict cipher suites) with mutual certificate authentication (**mTLS**) using official Belgian eHealth organization certificates.
2. **RESTful Identity & Authorization**: Standardized **OAuth 2.0** (RFC 6749) and **OpenID Connect (OIDC)** frameworks conforming to **IHE IUA (Internet User Authorization)** and **SMART on FHIR Backend Services**.
3. **Three Authentication Routes (Proposal)**: Flexible connection models evaluating direct Hub-to-Hub federation, the national eHealth IAM infrastructure, and a bridge for legacy systems via Security Token Service (STS) token exchange.
4. **Replay & Query Tamper-Proofing**: Application-layer cryptographic request binding via **DPoP (RFC 9449)** or **RFC 9421 (HTTP Message Signatures)**, replacing legacy SOAP SAML signatures to prevent query tampering and replay attacks.
5. **Auditability & Traceability**: Comprehensive audit logging conforming to **IHE BALP (Basic Audit Logging Pattern)** and **IHE ATNA (Audit Trail and Node Authentication)**, fulfilling the legal requirements of the legacy `getTransactionAccessList` service.

---

## 2. The Three Authentication & Connection Routes (Proposal)

To accommodate various client environments (modern cloud EHRs, regional hub nodes, mobile applications, and legacy hospital middleware), the Belgian Interhub specification evaluates **three distinct authentication routes**. 

> **Important Architectural Note**: Presenting three connection models is **an architectural proposal**. For the final normative standard, the Belgian healthcare ecosystem **must pick one of these three methods** as the unified national authentication framework.

```mermaid
flowchart TD
    subgraph Routes["<b>Three Interhub Authentication Routes (Proposal Under Evaluation)</b>"]
        direction LR
        subgraph Route1["<b>Proposal 1: Hub/Enterprise JWT</b>"]
            R1["<b>Direct Hub Federation</b><br/>• Asymmetric signed JWTs<br/>• Validated via Hub JWKS"]
        end
        subgraph Route2["<b>Proposal 2: eHealth IAM</b>"]
            R2["<b>National OIDC IdP</b><br/>• eID / itsme® / Enterprise cert<br/>• Automated consent & therapeutic link validation"]
        end
        subgraph Route3["<b>Proposal 3: STS Bridge</b>"]
            R3["<b>Legacy SAML Exchange</b><br/>• eHealth SOAP STS assertions<br/>• RFC 8693 Token Exchange"]
        end
    end

    Responder["<b>BELGIAN INTERHUB FHIR RESPONDER</b><br/>(Validates Signature, SSIN, NIHDI, CBE, & Scopes via JWKS)"]

    Route1 -->|"Bearer JWT<br/>(Hub Private Key)"| Responder
    Route2 -->|"Bearer JWT<br/>(eHealth OIDC AS)"| Responder
    Route3 -->|"1. SAML 2.0 Assertion"| TokenGateway["<b>Token Exchange Gateway</b><br/>(RFC 8693 SAML2 to JWT)"]
    TokenGateway -->|"2. Short-lived Bearer JWT"| Responder
```

---

### 2.1 Route 1: Hub/Enterprise-Issued JWT Bearer Tokens (Federated Trust)

In this route, eHealth Hubs (e.g. CoZo, RSW, RSB, Zodap) or major healthcare enterprises operate their own **OAuth 2.0 Authorization Servers (AS)**. Trust is established bilaterally or through a national hub federation trust registry.

#### Mechanics & Workflow:
1. The initiating client authenticates against its local Hub Authorization Server using the **OAuth 2.0 Client Credentials Flow** with asymmetric private key JWT authentication (`private_key_jwt`).
2. The local Hub AS issues a signed JSON Web Token (JWT) using its private RSA/ECDSA key.
3. The client presents the JWT in the HTTP `Authorization: Bearer <jwt>` header when calling the target hub's FHIR endpoints.
4. The responding hub validates the token signature using the issuer's public keys published at its **JSON Web Key Set (JWKS)** endpoint (`/.well-known/jwks.json`).

#### Sample Interhub JWT Claims Payload:
```json
{
  "iss": "https://auth.cozo.be",
  "sub": "client-hospital-uzl",
  "aud": "https://hub.rsb.be/fhir",
  "exp": 1773766800,
  "nbf": 1773763200,
  "iat": 1773763200,
  "jti": "b3e94a8c-9c71-4e78-9e51-12f8e12a4b89",
  "scope": "system/DocumentReference.read system/Bundle.read",
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

---

### 2.2 Route 2: eHealth Platform IAM (National Identity & Access Management)

In this route, authentication and authorization are centralized through the **Belgian eHealth Platform IAM** (Identity and Access Management) infrastructure.

#### Mechanics & Workflow:
1. **User Authentication**:
   * Interactive users (physicians, nurses, patients) authenticate via **eID**, **itsme®**, or TOTP mobile tokens.
   * Automated systems authenticate using **eHealth Enterprise Certificates**.
2. **Identity & Role Resolution**:
   * eHealth IAM validates the professional's credentials against federal authoritative databases: **CoBRHA** (healthcare institutions), **Federal Health Professionals Database** (NIHDI licenses), and **Crossroads Bank for Enterprises (CBE)**.
3. **Consent & Therapeutic Link Verification**:
   * eHealth IAM can perform pre-authorization checks against national consent registers and the central therapeutic links database.
4. **Token Issuance**:
   * eHealth IAM issues signed OAuth 2.0 Access Tokens and OIDC ID Tokens containing standardized federal health claims (`https://ehealth.fgov.be/claims/...`).
5. **Consumption**:
   * Any participating regional hub or repository verifies the token against the official eHealth JWKS endpoint (`https://iam.ehealth.fgov.be/.well-known/jwks.json`).

---

### 2.3 Route 3: Derived System Based on STS (SAML 2.0 to OAuth 2.0 Bridge)

Many Belgian hospital EHRs, laboratory information systems (LIS), and legacy connector middleware already integrate with the **eHealth Security Token Service (STS)** using SOAP WS-Trust and SAML 2.0 tokens (signed with physical eHealth X.509 keystores).

To enable these legacy systems to consume modern FHIR RESTful Interhub endpoints without an immediate, costly rewrite of their authentication stack, an **STS Token Exchange Gateway** is deployed:

```mermaid
sequenceDiagram
    autonumber
    participant Hosp as Legacy Hospital System
    participant STS as eHealth Platform STS (WS-Trust)
    participant Bridge as Interhub Token Exchange Service (RFC 8693)
    participant Responder as Belgian Interhub FHIR Responder

    Hosp->>STS: 1. Request SAML 2.0 Token (SOAP WS-Trust with Keystore)
    STS-->>Hosp: 2. Return Signed SAML 2.0 Assertion
    Hosp->>Bridge: 3. POST /oauth/token<br/>(grant_type=token-exchange, subject_token=SAML2, audience=hub)
    Note over Bridge: • Validates SAML signature against eHealth Trust Chain<br/>• Extracts NIHDI, CBE, SSIN, and Role assertions<br/>• Verifies validity window
    Bridge-->>Hosp: 4. Return short-lived OAuth 2.0 JWT Access Token
    Hosp->>Responder: 5. GET /fhir/DocumentReference (Authorization: Bearer JWT)
    Responder-->>Hosp: 6. HTTP 200 OK (FHIR Response)
```

#### RFC 8693 Token Exchange Request Example:
```http
POST /oauth/token HTTP/1.1
Host: auth-gateway.ehealth.fgov.be
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:token-exchange
&client_id=hospital-connector-uzl
&subject_token=PHNhbWwycDpBc3NlcnRpb24geG1sbnM6c2FtbDJwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXNzZXJ0aW9uIi...
&subject_token_type=urn:ietf:params:oauth:token-type:saml2
&audience=https://hub.cozo.be/fhir
&scope=system/DocumentReference.read system/Bundle.read
```

#### Response:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "system/DocumentReference.read system/Bundle.read"
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
        V1["1. Validate Bearer Token Scope & Signatures"]
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

## 4. Authorization Scopes & Access Control (SMART on FHIR / IUA)

All Interhub endpoints enforce fine-grained scope-based access controls based on SMART on FHIR and IHE IUA:

| Scope | Allowed Interaction | Semantic Description |
| :--- | :--- | :--- |
| `system/DocumentReference.read` | `GET [base]/DocumentReference` | Search and read document metadata across all accessible patients (Hub-to-Hub federation). |
| `system/Bundle.read` | `GET [base]/Bundle/{id}` | Retrieve complete FHIR Document Bundles (type = `document`). |
| `patient/DocumentReference.read`| `GET [base]/DocumentReference?patient=...` | Restricted metadata search for a specific patient in context. |
| `patient/Bundle.read` | `GET [base]/Bundle/{id}` | Retrieve document bundles belonging to the authorized patient. |

---

## 5. Audit Trail & Traceability (`getTransactionAccessList` $\longleftrightarrow$ IHE BALP)

Under Belgian law (Patient Rights Act & eHealth Platform Law), every access, search, and retrieval of medical records must be immutably recorded for auditability. In the legacy KMEHR world, the `getTransactionAccessList` SOAP service exposed access logs.

In the FHIR Interhub standard, auditing is standardized using **IHE BALP (Basic Audit Logging Pattern)** and **IHE ATNA** generating FHIR **`AuditEvent`** resources:

```mermaid
classDiagram
    class AuditEvent {
        +type: DCM #110112 ("Query") / #110106 ("Export")
        +subtype: ITI-67 ("FindDocumentReferences") / ITI-68 ("RetrieveDocument")
        +action: "E" (Execute) / "R" (Read)
        +recorded: 2026-03-15T10:30:05Z (instant)
        +outcome: "0" (Success) / "4" (Minor failure / Denied)
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
