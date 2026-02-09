# MoMo SMS Transactions API

Base URL: `http://127.0.0.1:8000`

Authentication: Basic Auth is required for all endpoints.

Header example:
```http
Authorization: Basic base64(username:password)
```

Default credentials (change with environment variables):
- `API_USER=admin`
- `API_PASS=admin123`

---

## GET /transactions
Returns all transactions.

Request example:
```bash
curl -u admin:admin123 http://127.0.0.1:8000/transactions
```

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

Query params:
- `limit` (optional): integer to limit number of records.

Error codes:
- 401 Unauthorized
- 400 Bad Request

---

## GET /transactions/{id}
Returns a single transaction by id.

Request example:
```bash
curl -u admin:admin123 http://127.0.0.1:8000/transactions/1
```

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
Adds a new transaction. If `id` is missing, one is generated.

Request example:
```bash
curl -u admin:admin123 -X POST http://127.0.0.1:8000/transactions \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"sent\",\"amount\":\"1500\",\"sender\":\"2507xxxxxxx\",\"receiver\":\"2507xxxxxxx\",\"timestamp\":\"1700000001234\"}"
```

Response example (201 Created):
```json
{
  "id": "42",
  "type": "sent",
  "amount": "1500",
  "sender": "2507xxxxxxx",
  "receiver": "2507xxxxxxx",
  "timestamp": "1700000001234"
}
```

Error codes:
- 400 Bad Request
- 401 Unauthorized
- 409 Conflict

---

## PUT /transactions/{id}
Updates an existing transaction. The `id` in the URL is authoritative.

Request example:
```bash
curl -u admin:admin123 -X PUT http://127.0.0.1:8000/transactions/42 \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"sent\",\"amount\":\"2500\"}"
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
Deletes a transaction.

Request example:
```bash
curl -u admin:admin123 -X DELETE http://127.0.0.1:8000/transactions/42
```

Response example (200 OK):
```json
{
  "deleted": "42"
}
```

Error codes:
- 401 Unauthorized
- 404 Not Found
