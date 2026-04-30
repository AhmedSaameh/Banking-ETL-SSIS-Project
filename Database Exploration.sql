

-- First look on data 
select top 2 * from transactions_data
select top 2 * from users_data
select top 2 * from cards_data



select * from users_data 
where id = 1362
-- Check if ID in transactions_data table is unique and not null to make it primary key

select count(id) from transactions_data
select count(distinct(id)) from transactions_data

select id from transactions_data 
where id is null					-- there're no null values in id column and No duplicate ids

-- add primary key constraint for transactions_data table
alter table transactions_data 
add constraint transactions_pk primary key (id)



-- check if ID in users_data table is unique and not null to make it primary key
select count(id) from users_data
select count(distinct(id)) from users_data

select id from users_data
where id is null					-- There're no null values in id column and No duplicate ids 

-- Add PRIMARY KEY constraint for users_data
alter table users_data
add constraint users_pk primary key (id) 


-- The same check conditions for ID in cards_data table 
select count(id) from cards_data
select count(distinct(id)) from cards_data

select id from cards_data
where id is null


-- Add PRIMARY KEY constraint for cards_data
alter table cards_data
add constraint card_pk primary key (id)




/* Now in transactions_data there's a column called 'client_id' describes the users information in users_data table 
		so we need to add a foreign key to make this column references the id column in users_data table 
   The same thing on card_id column 
*/

alter table transactions_data
add constraint fk1 foreign key (client_id) references users_data(id)

alter table transactions_data
add constraint fk2 foreign key (card_id) references cards_data(id)


-- As we see there is a client_id column in cards_data, so there is a relationship between these two tables 

alter table cards_data 
add constraint fk_cards_users foreign key (client_id) references users_data(id)



select max(id) from users_data
select max(client_id)from cards_data



