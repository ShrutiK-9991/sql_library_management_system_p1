select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from return_status;
select * from members;

-- Project 1

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books(isbn, book_title, category, rental_price, status, author, publisher)
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', '6.00', 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
select * from books;

-- Task 2: Update an Existing Member's Address
update members
set  member_address = '213 Maple Station'
where member_id = 'C105';
select * from members;

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
delete from issued_status
where issued_id = 'IS121';
select * from issued_status;

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
select issued_book_name, issued_emp_id
from issued_status
where issued_emp_id = 'E101';
-- or
select * 
from issued_status
where issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_emp_id,count(issued_id) as "Total_book_issued"
from issued_status
group by 1
having count(issued_id) > 1;

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
--(ethe join kabara getla - karn books tables madhe fakta books chi info dili aahe.
--  ani aplyala each book ani techya total issued count la kahadicha aahe)

--(select issued_book_name, issued_book_isbn, count(issued_member_id) as "book_issued_count"
--from issued_status
--group by 1,2;)
create table book_counts
as
select b.isbn, b.book_title, count(i.issued_book_isbn) as "Total_issued_count"
from books b
join issued_status i
on b.isbn = i.issued_book_isbn
group by 1,2;

select * from book_counts;

-- Task 7: find how many books issued in a week.
select extract(week from i.issued_date), b.book_title, count(b.isbn) as "Total_count_in_a_week"
from books b
join issued_status i
on b.isbn = i.issued_book_isbn
group by 1,2;

select date_trunc('week', i.issued_date), count(b.isbn) as "Total_count_in_a_week"
from books b
join issued_status i
on b.isbn = i.issued_book_isbn
group by 1;

-- Task 8: find how many books issued in a week.
select extract(month from i.issued_date), count(b.isbn) as "Total_count_in_a_month"
from books b
join issued_status i
on b.isbn = i.issued_book_isbn
group by 1;

-- Task 9. Retrieve All Books in a Specific Category
select * 
from books
where category = 'Fantasy';

-- Task 10: What are the different categories of books?
select distinct(category)
from books;

-- Task 11: How many books are there in each category?
select count(isbn), category
from books
group by 2;

-- Task 12: Find Total Rental Income by Category.
select sum(b.rental_price) as "Total_Rental_Income", b.category, count(isbn) as "No_time_book_issued" --no. of time the book is issued
from books b
join issued_status i
on b.isbn = i.issued_book_isbn
group by 2;

-- Task 13: List Members Who Registered in the Last 180 Days:
select * from members
where reg_date >= current_date - interval '180 days';

insert into members(member_id, member_name, member_address, reg_date)
values
('C116', 'Daniel', '579 Walnut St', '2026-01-01'),
('C120', 'Stella', '400 Elm St', '2025-12-01');


-- Task 14: List Employees with Their Branch Manager's Name and their branch details.
select e1.emp_name, e2.emp_name as "Manager", e1.branch_id, e1.salary, e1.position, b.manager_id
from employees e1
join branch b
on e1.branch_id = b.branch_id
join employees e2
on e2.emp_id = b.manager_id;

-- Task 15:  Create a Table of Books with Rental Price Above a Certain Threshold
create table high_rental_price_books
as
select * from books
where rental_price > 7;

select * from high_rental_price_books;

-- Task 16: Retrieve the List of Books Not Yet Returned
select i.issued_id, i.issued_book_isbn, i.issued_book_name, i.issued_date, r.return_date
from issued_status i
left join return_status r
on i.issued_id = r.issued_id
where r.return_date is null;

-- ADVANCED SQL OPERATIONS

-- Task 17: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.
select m.member_id, m.member_name, b.book_title, i.issued_date, /*r.return_date ,*/ current_date - i.issued_date as "Overdue_Days"
from issued_status i
join members m
on i.issued_member_id = m.member_id
join books b
on b.isbn = i.issued_book_isbn
left join return_status r
on r.issued_id = i.issued_id
where
r.return_date is null 
and
(current_date - i.issued_date) > 30
order by 1;

/*
-- Task 18: Update Book Status on Return
Write a query to update the status of books in the books table 
to "Yes" when they are returned (based on entries
in the return_status table).
*/

-- MANUALLY STATUS CHANGE

select * from books
where isbn = '978-0-553-29698-2';

update books
set status = 'no'
where isbn = '978-0-553-29698-2';

select * from issued_status
where issued_book_isbn = '978-0-553-29698-2';

select * from return_status
where issued_id = 'IS137' ;

-- now if the above book is returned today by the
-- member then we need to add it in return table

insert into return_status(return_id, issued_id, return_date, book_quality) 
values
('RS120', 'IS137', current_date, 'Good');

select * from return_status
where issued_id = 'IS137' ;

update books
set status = 'yes'
where isbn = '978-0-553-29698-2';


-- STORE PROCEDURES
create or replace procedure add_return_records(p_return_id varchar(15), p_issued_id varchar(10), p_book_quality varchar(20))
language plpgsql
as $$

declare
   v_isbn varchar(30);
   v_book_name varchar(60);

begin
  	-- all our logic and code will come here
	-- inserting into returns based on users input
	insert into return_status(return_id, issued_id, return_date, book_quality)
	values
	(p_return_id, p_issued_id, current_date, p_book_quality);

	select 
		issued_book_isbn,
		issued_book_name
		into
		v_isbn,
		v_book_name
	from issued_status
	where issued_id = p_issued_id;

	update books
	set status = 'yes'
	where isbn = v_isbn;

	raise notice 'Thank you for returning the book: %', v_book_name;
	
end;
$$

-- TESTING FUNCTION add_return_records

select * from books
where isbn = '978-0-7432-7357-1'

select * from issued_status
where issued_book_isbn = '978-0-7432-7357-1'

select * from return_status
where issued_id = 'IS136'

-- Calling function
call add_return_records('RS130', 'IS136', 'Good');


/*
-- Task 19: Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned,
and the total revenue generated from book rentals.
*/

select br.branch_id, br.manager_id, count(i.issued_id) as "number_book_issued", 
count(r.return_id) as "number_of_book_return", sum(bk.rental_price) as "Total_Revenue" 
from issued_status i
join employees e
on i.issued_emp_id = e.emp_id
join branch br
on br.branch_id = e.branch_id
join books bk
on bk.isbn = i.issued_book_isbn
left join return_status r
on r.issued_id = i.issued_id
group by 1, 2;

/*
-- Task 20: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who 
have issued at least one book in the last 2 months.
*/

create table active_members
as
select * from members
where member_id in(select distinct issued_member_id
                   from issued_status
                   where issued_date >= current_date - interval '2 months');

select * from active_members;

/*
-- Task 21: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.
*/

select e.emp_name, count(i.issued_id) as "no._of_books_issued", b.*
from issued_status i
join employees e
on i.issued_emp_id = e.emp_id
join branch b
on e.branch_id = b.branch_id
group by 1, 3
order by 2 desc
limit 3;

/*
-- Task 22: Stored Procedure Objective: Create a stored procedure
to manage the status of books in a library system. 
Description: Write a stored procedure that updates the 
status of a book in the library based on its issuance. 
The procedure should function as follows: The stored 
procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available 
(status = 'yes'). If the book is available, it should be 
issued, and the status in the books table should be updated 
to 'no'. If the book is not available (status = 'no'), 
the procedure should return an error message indicating 
that the book is currently not available.
*/

create or replace procedure issue_book(p_issued_id varchar(30), p_issued_member_id varchar(10), p_issued_book_isbn varchar(30), p_issued_emp_id varchar(10))
language plpgsql
as $$

declare
-- variable declaration
   v_status varchar(10);
   
begin
-- all the code
       -- checking if the book is available 'yes'
	 select status 
	        into
	        v_status
	 from books
	 where isbn = p_issued_book_isbn;

	 if v_status = 'yes' then

	    insert into issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        values
		(p_issued_id, p_issued_member_id, current_date, p_issued_book_isbn, p_issued_emp_id);

		update books
		    set status = 'no'
		where isbn = p_issued_book_isbn;

		raise notice 'Book records added successfully for book isbn : %', p_issued_book_isbn;

	else

		raise notice 'Sorry to inform you the book you have requested is unavailable book isbn : %', p_issued_book_isbn;

	end if;
	 
end;
$$



select * from books;
-- "978-0-330-25864-8" -- yes
-- "978-0-307-58837-1" -- no
select * from issued_status;

call issue_book('IS155', 'C108', '978-0-330-25864-8', 'E104');

call issue_book('IS156', 'C108', '978-0-307-58837-1', 'E104');

select * from books
where isbn = '978-0-330-25864-8';


/*
Task 23: Create Table As Select (CTAS) Objective: Create a 
CTAS (Create Table As Select) query to identify overdue books 
and calculate fines.

Description: Write a CTAS query to create a new table that
lists each member and the books they have issued but not 
returned within 30 days. The table should include: The 
number of overdue books. The total fines, with each day's
fine calculated at $0.50. The number of books issued by 
each member. The resulting table should show: Member ID 
Number of overdue books Total fines
*/

select m.member_name, i.issued_member_id, b.book_title, 
(current_date - i.issued_date) - 30 as "Overdue_Days",
((current_date - i.issued_date) - 30) * 0.50 as "Total_Fine"
from issued_status i
join members m 
on i.issued_member_id = m.member_id
left join return_status r
on r.issued_id = i.issued_id
join books b 
on b.isbn = i.issued_book_isbn
where r.return_date is null 
and
(current_date - i.issued_date) > 30;

