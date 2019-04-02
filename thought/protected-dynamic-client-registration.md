---
title: "Protected Dynamic Client Registration"
date: 2018-03-30T15:37:06-04:00
draft: false
tags:
- oauth2
- dcrp
- jws
- cryptography
---

Thoughts on Protected Dynamic Client Registration.
==================================================

This proposes a method of trust intended for [software
statements](https://tools.ietf.org/html/rfc7591#section-2.3) that can be
Endorsed by trusted 3rd parties, and used by an authorization server
that has little or no knowledge of the Developer.

This uses the [General JWS JSON Serialization
Syntax](https://tools.ietf.org/html/rfc7515#section-7.2.1) to exchange
data and signatures between parties.

Payload
-------

MUST contain at least one of
[kid](https://tools.ietf.org/html/rfc7515#section-4.1.4),
[jku](https://tools.ietf.org/html/rfc7515#section-4.1.2),
[jwk](https://tools.ietf.org/html/rfc7515#section-4.1.3) to allow
identification of the Developer.

Signatures
----------

### Endorsement Signature(s)

MAY contain `exp` with a timestamp of the expiration time. MAY contain
`iss` identifying the Endorser. Which endorsement bodies the
authorization server chooses to trust and how it verifies these
signatures is outside the scope of this document.

### Developer Signature

The [protected
header](https://tools.ietf.org/html/rfc7515#section-7.2.1) MUST contain
`exp` with a timestamp of the expiration time.

    {
        "crit": ["exp"],
        "exp": 1363284000,
    }

The authorization server MAY specify that this expiration cannot be too
far in the future.

MUST contain ONE OF
[jwk](https://tools.ietf.org/html/rfc7515#section-4.1.3) or
[kid](https://tools.ietf.org/html/rfc7515#section-4.1.4) that must match
or be used to identify the key in the payload used to create this
signature.

MUST be the last entry in signature array.

Example usage
=============

[![protected dcrp
flow](flow.png)](/images/protected_dynamic_client_registration.png)
