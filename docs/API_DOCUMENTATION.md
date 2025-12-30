# WatchHub API Documentation

Complete REST API documentation for the WatchHub backend.

## Base URL

```
Development: http://localhost:3000/api
Production: https://your-domain.com/api
```

## Authentication

Most endpoints require authentication using JWT tokens.

### Headers

```http
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json
```

## Response Format

### Success Response
```json
{
  "success": true,
  "message": "Success message",
  "data": { ... }
}
```

### Error Response
```json
{
  "error": {
    "message": "Error message"
  }
}
```

## Endpoints

### Authentication

#### Register User
```http
POST /auth/register
```

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "phone": "+1234567890"  // optional
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "user": { ... },
    "token": "jwt_token"
  }
}
```

#### Login
```http
POST /auth/login
```

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:** `200 OK`

---

### Watches

#### Get All Watches
```http
GET /watches?page=1&limit=10&search=rolex&category=Luxury&minPrice=1000&maxPrice=10000&sortBy=price&sortOrder=asc
```

**Query Parameters:**
- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 10)
- `search` (string): Search query
- `brandId` (string): Filter by brand
- `category` (string): Filter by category
- `minPrice` (number): Minimum price
- `maxPrice` (number): Maximum price
- `sortBy` (string): Sort field (default: createdAt)
- `sortOrder` (string): asc or desc (default: desc)

**Response:** `200 OK`

#### Get Featured Watches
```http
GET /watches/featured?limit=10
```

#### Get Watch by ID
```http
GET /watches/:id
```

**Response:** `200 OK`
```json
{
  "data": {
    "watch": { ... },
    "relatedWatches": [ ... ]
  }
}
```

---

### Cart (Protected)

#### Get Cart
```http
GET /cart
```

**Response:** `200 OK`
```json
{
  "data": {
    "cartItems": [ ... ],
    "subtotal": 1500.00,
    "itemCount": 3
  }
}
```

#### Add to Cart
```http
POST /cart
```

**Body:**
```json
{
  "watchId": "uuid",
  "quantity": 1
}
```

#### Update Cart Item
```http
PUT /cart/:id
```

**Body:**
```json
{
  "quantity": 2
}
```

#### Remove from Cart
```http
DELETE /cart/:id
```

#### Clear Cart
```http
DELETE /cart
```

---

### Wishlist (Protected)

#### Get Wishlist
```http
GET /wishlist
```

#### Add to Wishlist
```http
POST /wishlist
```

**Body:**
```json
{
  "watchId": "uuid"
}
```

#### Remove from Wishlist
```http
DELETE /wishlist/:id
```

#### Move to Cart
```http
POST /wishlist/:id/move-to-cart
```

---

### Orders (Protected)

#### Create Payment Intent
```http
POST /orders/create-payment-intent
```

**Body:**
```json
{
  "amount": 1500.00
}
```

**Response:** `200 OK`
```json
{
  "data": {
    "clientSecret": "pi_xxx_secret_xxx",
    "paymentIntentId": "pi_xxx"
  }
}
```

#### Create Order
```http
POST /orders
```

**Body:**
```json
{
  "addressId": "uuid",
  "paymentIntentId": "pi_xxx"
}
```

#### Get User Orders
```http
GET /orders?page=1&limit=10
```

#### Get Order by ID
```http
GET /orders/:id
```

---

### User Profile (Protected)

#### Get Profile
```http
GET /users/profile
```

#### Update Profile
```http
PUT /users/profile
```

**Body:**
```json
{
  "name": "John Doe",
  "phone": "+1234567890"
}
```

#### Get Addresses
```http
GET /users/addresses
```

#### Add Address
```http
POST /users/addresses
```

**Body:**
```json
{
  "addressLine": "123 Main St",
  "city": "New York",
  "state": "NY",
  "zip": "10001",
  "country": "USA",
  "isDefault": false
}
```

#### Update Address
```http
PUT /users/addresses/:id
```

#### Delete Address
```http
DELETE /users/addresses/:id
```

---

### Reviews

#### Get Watch Reviews
```http
GET /reviews/watch/:watchId?page=1&limit=10&sortBy=createdAt&sortOrder=desc
```

#### Create Review (Protected)
```http
POST /reviews
```

**Body:**
```json
{
  "watchId": "uuid",
  "rating": 5,
  "comment": "Excellent watch!"
}
```

#### Update Review (Protected)
```http
PUT /reviews/:id
```

#### Delete Review (Protected)
```http
DELETE /reviews/:id
```

#### Mark Review Helpful (Protected)
```http
POST /reviews/:id/helpful
```

---

### Support

#### Get FAQs
```http
GET /faq?category=Shipping&search=delivery
```

#### Create Support Ticket (Protected)
```http
POST /support/tickets
```

**Body:**
```json
{
  "subject": "Order Issue",
  "message": "My order hasn't arrived"
}
```

#### Get User Tickets (Protected)
```http
GET /support/tickets
```

#### Get Ticket Details (Protected)
```http
GET /support/tickets/:id
```

#### Add Message to Ticket (Protected)
```http
POST /support/tickets/:id/messages
```

**Body:**
```json
{
  "message": "Follow-up message"
}
```

---

### Admin (Protected - Admin Only)

#### Dashboard Stats
```http
GET /admin/dashboard/stats
```

#### Manage Watches
```http
GET /admin/watches?page=1&limit=20&search=rolex
POST /admin/watches (with multipart/form-data for images)
PUT /admin/watches/:id
DELETE /admin/watches/:id
```

#### Manage Orders
```http
GET /admin/orders?page=1&limit=20&status=PROCESSING
PUT /admin/orders/:id/status
```

**Body:**
```json
{
  "status": "SHIPPED"
}
```

#### Manage Users
```http
GET /admin/users?page=1&limit=20
PUT /admin/users/:id/role
```

#### Manage Reviews
```http
DELETE /admin/reviews/:id
```

#### Manage FAQs
```http
POST /admin/faqs
PUT /admin/faqs/:id
DELETE /admin/faqs/:id
```

#### Manage Support Tickets
```http
GET /admin/support/tickets?page=1&limit=20&status=OPEN
PUT /admin/support/tickets/:id/status
```

---

## Status Codes

- `200 OK`: Request successful
- `201 Created`: Resource created
- `400 Bad Request`: Invalid request
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource already exists
- `500 Internal Server Error`: Server error

## Rate Limiting

API requests are limited to prevent abuse:
- 100 requests per 15 minutes per IP for unauthenticated requests
- 1000 requests per 15 minutes per user for authenticated requests

## Pagination

List endpoints support pagination:

**Request:**
```http
GET /watches?page=2&limit=20
```

**Response:**
```json
{
  "data": {
    "watches": [ ... ],
    "pagination": {
      "page": 2,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

## Webhooks

### Stripe Webhook
```http
POST /webhooks/stripe
```

Handle Stripe payment events for order confirmation.

---

For more information, see the backend source code or contact the development team.

