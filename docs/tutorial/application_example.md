# Applicatin example

The business we're going to cover is very simple.

We have a simple book library and we need to allow logged users to create new
books and rent it.

### Initial rules

- Each book has a title, author and can have many genres
- The books view is public
- **Only** logged users can edit the books
- Logged users can **edit** or **remove** a book

### The Rental system

- All available book can be **rented**
- Logged users can rent a book
- A book is not **available** when it's rented to someone
- A book is **available** after it's delivered back

### Books wishlist

The logged user can manage a **wishlist** considering:

- When a book is **not available** and the user "**didn't read** it
- If the person **already read** the book, also **doesn't make sense add it in the wishlist
- When the book become available, the system should notify people that are with this book in the wishlist
- When the book is rented by someone that have the book in the wishlist, it should be removed after delivered back

The application domain is very simple and we're going to build step by step
this small logic case to show how granite can be useful and abstract a few
steps of your application.

