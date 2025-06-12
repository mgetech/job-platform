# Job Platform API

This repository hosts the Fullstack API for a dynamic job platform.

---

## 🚀 Key Features & Functionalities

### User Management & Authentication:

- **User Registration**: Allows new users to create accounts with a unique email, name, and password. Ensures automatic assignment of a **default user role**. `users/update_role` **endpoint can be used to change user's role to admin or user**.
- **User Login**: Authenticates existing users and provides a secure JSON Web Token (JWT) for subsequent API interactions.

### Job Management:

- Enables administrators to create and manage job listings.
- Allows viewers to search for the jobs based on title and language.

### Job Application System:

- **Apply for Jobs**: Authenticated users can apply for any available job listing.
- **Duplicate Prevention**: Prevents users from applying to the same job more than once.
- **View Applications**: Users can retrieve a comprehensive list of all jobs they have applied for.

### Comprehensive API Documentation:

- Interactive OpenAPI 3 (Swagger UI) documentation is available for all API endpoints, generated directly from tests.

---

## 💻 Technologies Used

- **Ruby on Rails (v8.0.2)**
- **PostgreSQL**
- **SOLID principles**
- **JWT (JSON Web Tokens)**: For secure, stateless authentication.
- **RSpec**: The testing framework for robust unit and controller tests.
- **Rswag / OpenAPI 3**: For automated API documentation generation and interactive Swagger UI.

---

## 📋 Setup Instructions

Follow these steps to get the project up and running on your local machine.

---

### Prerequisites

Please ensure you have the following installed:

- **Ruby**: Version 3.4.x (e.g., 3.4.4).
- **Rails**: Version 8.0.2.
- **PostgreSQL**: Version 15 or later. Ensure it's running and you have a user with appropriate permissions.

---

### Installation Steps

#### Clone the repository:

```bash
git clone https://github.com/mgetech/job-platform.git
cd job-platform
```

### Install Ruby Gems:

Install all required Ruby gems using Bundler:

```bash
bundle install
```
### Configure Database Credentials:
Rails connects to your PostgreSQL database using `config/database.yml`.
The development environment configuration expects environment variables for database connection: `DATABASE_USERNAME`, `DATABASE_PASSWORD`, and `DATABASE_HOST`.

Create a `.env` file in the root of your project based on the provided `.env` example template:


Then, open `.env` and fill in your PostgreSQL username and password.
For local development, `DATABASE_HOST` can typically be `localhost`.

### Example `.env` content:
```
# .env
DATABASE_USERNAME=your_pg_username
DATABASE_PASSWORD=your_pg_password
DATABASE_HOST=localhost
```
### Create and Migrate the Database:
Set up your development database and run all migrations:

```bash
rails db:create db:migrate
```
### Seed the Database:
Populate your development database with initial data (e.g., languages):

```bash
rails db:seed
```
### Start the Rails Server:
Once the setup is complete, you can start the API server:

```bash
rails s
```
The API will be running on http://localhost:3000.

## ✅ Testing & API Documentation
## Running Tests
To run the full RSpec test suite:

```bash
bundle exec rspec
```

### Accessing API Documentation (Swagger UI)

Open your web browser and navigate to:
http://localhost:3000/api-docs

This page provides a live, interactive view of all documented API endpoints, including request/response schemas and the ability to **"Try it out"**.

### Important note:
To authenticate, **copy the token** returned after login or registration, click the `Authorize` button at the top of the page, and paste the token to **access protected features**. 