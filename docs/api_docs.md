# MoMo SMS Transactions API

Base URL: `http://127.0.0.1:8000`

Authentication: Basic Auth (default `admin` / `admin123`).
Change with environment variables `API_USER` and `API_PASS`.

## Thunder Client (how I tested)
- New Request
- Auth tab: Basic → `admin` / `admin123`
- For POST/PUT: Body tab → JSON
- Unauthorized test: remove auth or use a wrong password to get `401`.

---

## GET /transactions
Thunder Client:
- Method: GET
- URL: `http://127.0.0.1:8000/transactions`

Response example (200 OK):
```json
[
  {
    "id": "1",
    "type": "received",
    "amount": "5000",
    "sender": "2507xxxxxxx",
    "receiver": "2507xxxxxxx",
    "timestamp": "1700000000000"
  }
]
```

Error codes:
- 401 Unauthorized
- 400 Bad Request

---

## GET /transactions/{id}
Thunder Client:
- Method: GET
- URL: `http://127.0.0.1:8000/transactions/1`

Response example (200 OK):
```json
{
  "id": "1",
  "type": "received",
  "amount": "5000",
  "sender": "2507xxxxxxx",
  "receiver": "2507xxxxxxx",
  "timestamp": "1700000000000"
}
```

Error codes:
- 401 Unauthorized
- 404 Not Found

---

## POST /transactions
Thunder Client:
- Method: POST
- URL: `http://127.0.0.1:8000/transactions`
- Body (JSON):
```json
{
  "type": "sent",
  "amount": "1500",
  "sender": "250700000001",
  "receiver": "250700000002",
  "timestamp": "1700000001234"
}
```

Response example (201 Created):
```json
{
  "id": "42",
  "type": "sent",
  "amount": "1500",
  "sender": "250700000001",
  "receiver": "250700000002",
  "timestamp": "1700000001234"
}
```

Error codes:
- 400 Bad Request
- 401 Unauthorized
- 409 Conflict

---

## PUT /transactions/{id}
Thunder Client:
- Method: PUT
- URL: `http://127.0.0.1:8000/transactions/42`
- Body (JSON):
```json
{
  "type": "sent",
  "amount": "2500"
}
```

Response example (200 OK):
```json
{
  "id": "42",
  "type": "sent",
  "amount": "2500"
}
```

Error codes:
- 400 Bad Request
- 401 Unauthorized
- 404 Not Found

---

## DELETE /transactions/{id}
Thunder Client:
- Method: DELETE
- URL: `http://127.0.0.1:8000/transactions/42`

Response example (200 OK):
```json
{
  "deleted": "42"
}
```

Error codes:
- 401 Unauthorized
- 404 Not Found
