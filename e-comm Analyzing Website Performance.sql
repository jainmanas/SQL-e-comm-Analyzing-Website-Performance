/* INFORMATION ABOUT THE RELEVANT TABLES:

- TABLE1: website_sessions table contains information about each website_session, at what time the session started (timestamp column),
the user_id, the paid campaigns tracking parameters such as utm_source, utm_campaign, etc., the device type that was used
(mobile or desktop) and the http_referer.   
Whenever someone lands on or logs onto our website, it begins a new website session, identified by the primary key website_session_id.
 
 - TABLE2: website_pageviews table has website_pageview_id as the primary key, which uniquely identifies each new pageview,
 has the created_at column (timestamp) which displays the date and time at which each new page was viewed, 
 followed by website_session_id marking the website_session in which that page was viewed and 
 a pageview_url column which displays the page name such as home, products, cart, billing, etc. 
 
 - TABLE3: orders table has order_id as the primary key which uniquely identifies each order,
 created_at column (timestamp) which specifies the date and time at which the order was placed,
 website_session_id marking the website session in which the order was placed 
 and 2 columns for selling and cost price of goods.
*/


-- ANALYZING TOP WEBSITE CONTENT:

/* Q1. Request received on 9th June, 2012
   Could you help me get my head around the site by pulling the most-viewed website pages, 
   ranked by session volume? */
	
SELECT 
    pageview_url,
    COUNT(DISTINCT website_pageview_id) AS num_of_views
FROM
    website_pageviews
WHERE
    created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY num_of_views DESC;

/* RESULTS:
So, we have a total of 7 webpages, with pageviews being as follows:
home page = 10403 views, products page = 4239 views, the-original-mr-fuzzy (specific product) page = 3037 views,
cart page = 1306 views, shipping page = 869 views, billing page = 716 views and 
thank-you-for-your-order page = 306 views 

INSIGHTS: 
the homepage, the products page, and the Mr. Fuzzy page get the bulk of our traffic. */


-- LANDING PAGE PERFORMANCE & TESTING:

/* Q2. Request received on June 12th, 2012
   Would you be able to pull a list of the top entry pages? I want to confirm where our users are hitting the site. 
   If you could pull all entry pages and rank them on entry volume, that would be great. */

/* SOLUTION STEPS: 
   1. To find top entry/landing pages, we will limit to just the first page 
      a user sees during a given session, using a temporary table. 
   2. Then join that temporary table to the website_pageviews table
      to grab the pageview_url (page name) of the entry/landing page  */

-- SOLUTION:

drop temporary table if exists landing_page;

create temporary table landing_page 
select 
	website_session_id,
    min(website_pageview_id) as landing_pageview_id
from website_pageviews
where created_at < '2012-06-12'
group by website_session_id;

-- Checking the temporary table 
select * from landing_page limit 20;

select 
	website_pageviews.pageview_url as entry_page,
    count(landing_page.landing_pageview_id) as entry_volume
from landing_page
	left join website_pageviews
		on landing_page.landing_pageview_id = website_pageviews.website_pageview_id
group by website_pageviews.pageview_url;

/* RESULTS: 
   Looks like home page is the only entry/landing page right now, meaning all of our traffic lands on the homepage first. */
   

/* Q3. Request received on 14th June, 2012
   The other day you showed us that all of our traffic is landing on the homepage right now. 
   We should check how that landing page is performing. 
   Can you pull bounce rates for traffic landing on the homepage? I would like to see three numbers, viz.
   Sessions, Bounced Sessions, and % of Sessions which Bounced (aka “Bounce Rate”). */
   
   -- SOLUTION:
   
   /* BOUNCE is said to occur when a user leaves the website after landing on the entry/landing page, i.e.
   when the user visits only (one) 1 page of our website and leaves. That 1 page is known as the ENTRY OR LANDING PAGE. 
   So, in order to calculate the bounce rate we, first have to figure out the landing pages of each session  */
   
   -- STEP 1: We will create a temporary table to grab the pageview_id of the landing pages 

drop temporary table if exists landing_page_id;
create temporary table landing_page_id
select 
	website_session_id,
	min(website_pageview_id) as landing_page_id
from website_pageviews 
where created_at < '2012-06-14'
group by website_session_id;

select * from landing_page_id;  -- to check the temporary table

/* STEP 2: Joining landing_page_id table with website_pageviews to grab the name of landing pages (pageview_url)
   and creating another temporary table. */

drop temporary table if exists landing_page_name;
create temporary table landing_page_name
select 
	landing_page_id.website_session_id,
    landing_page_id.landing_page_id,
    website_pageviews.pageview_url as landing_page
from landing_page_id
	inner join website_pageviews
		on landing_page_id.landing_page_id = website_pageviews.website_pageview_id;
        
select * from landing_page_name; -- to check the temporary table

/* STEP 3: Joining landing_page_name table with website_pageviews table on website_session_id to 
   evaluate all the website sessions that landed on the home page. 
   And then, evaluating how many of those sessions had only 1 pageview and how many of them had more than 1 pageview. */
   
select 
	landing_page_name.website_session_id,
    count(distinct website_pageviews.website_pageview_id) as num_of_pageviews
from landing_page_name
	inner join website_pageviews
		on landing_page_name.website_session_id = website_pageviews.website_session_id
group by 
	website_session_id;  
    
-- The above query returns the num of webpages viewed in each website session.
   
/* STEP 4: Using the above query in STEP 3 as a subquery in the from clause to calculate the total number of sessions,
   number of bounced sessions and the bounce rate  */
   
select 
	count(website_session_id) as total_num_of_sessions,
    count(case when num_of_pageviews = 1 then website_session_id end) as num_of_bounced_sessions,
    count(case when num_of_pageviews = 1 then website_session_id end)/count(website_session_id) as bounce_rate
from 
(
	select 
		landing_page_name.website_session_id,
		count(distinct website_pageviews.website_pageview_id) as num_of_pageviews
	from landing_page_name
		inner join website_pageviews
			on landing_page_name.website_session_id = website_pageviews.website_session_id
	group by 
		website_session_id) as pageviews_per_session ;
   
/* RESULTS:
   The total number of sessions landing on home page are 11048,
   number of bounced session are 6538 and bounce rate = 59.18% 
   
   INSIGHTS from the Website Manager: almost a 60% bounce rate! That’s pretty high especially for paid 
   search, which should be high quality traffic. */
 

/* Q4. Request received on 28th July, 2012
   Based on your bounce rate analysis, we ran a new custom landing page (/lander-1) in a 50/50 test against the 
   homepage (/home) for our gsearch nonbrand traffic. 
   Can you pull bounce rates for the two groups so we can evaluate the new page? Make sure to just look at the time 
   period where /lander-1 was getting traffic, so that it is a fair comparison.  */
   
   
/* SOLUTION:
   STEP 1: We need to figure out the time-frame of our analysis and we will do that by finding out 
   the first instance of lander-1 in our website_pageviews table */
   
select * 
from website_pageviews 
where created_at < '2012-07-28'  -- Since, request was received on 28th July, 2012
and pageview_url = '/lander-1'
order by created_at;   -- So, the very first instance of lander-1 was on 19th June, 2012. 

-- So, the time-frame of our analysis is between 19th June and 28th July, 2012.

/* STEP 2: 
   i. Joining the website_pageviews table to website_sessions table to grab all the pageviews
   from gsearch nonbrand paid traffic. 
   ii. Grouping by the website_session_id to grab the first_page_view_id (landing_page_id) of each session
   iii. Creating a temporary table entry_page_id to grab the entry_page_id of each session.  */

drop temporary table if exists entry_page_id;

create temporary table entry_page_id
select 
	website_pageviews.website_session_id,
    min(website_pageviews.website_pageview_id) as entry_page_id
from website_pageviews 
	inner join website_sessions
		on website_pageviews.website_session_id = website_sessions.website_session_id
where 
	website_sessions.created_at between '2012-06-19' and '2012-07-28'
    and website_sessions.utm_source = 'gsearch'    
    and website_sessions.utm_campaign = 'nonbrand'
group by 
	website_pageviews.website_session_id;
    
select * from entry_page_id;
   
/* STEP 3: 
   i. Joining entry_page_id table to the website_pageviews table to grab the entry/landing page names
   ii. Creating a temporary table entry_page_per_session  */

drop temporary table if exists entry_page_per_session;

create temporary table entry_page_per_session
select 
	entry_page_id.website_session_id,
    entry_page_id.entry_page_id,
    website_pageviews.pageview_url
from entry_page_id
	inner join website_pageviews
		on entry_page_id.entry_page_id = website_pageviews.website_pageview_id
order by 
	website_pageviews.pageview_url;
	
select * from entry_page_per_session order by website_session_id; -- checking the temp table

/* STEP 4: 
   i. Joining entry_page_per_session table to website_pageviews table to 
   grab all the pageviews of each website session where the landing pages are home and lander-1 
   ii. grouping by website_session_id to count number of pageviews per session
   iii. creating a temporary table */
  
drop temporary table if exists pageviews_per_session;

create temporary table pageviews_per_session
select 
	entry_page_per_session.website_session_id,
    count(website_pageviews.website_pageview_id) as pageviews_per_session
from entry_page_per_session
	inner join website_pageviews
		on entry_page_per_session.website_session_id = website_pageviews.website_session_id
where 
	entry_page_per_session.pageview_url in ('/home','/lander-1')
group by 
	entry_page_per_session.website_session_id;
    
select * from pageviews_per_session order by website_session_id;

/* STEP 5: 
   i. Joining pageviews_per_session to entry_page_per_session to grab the landing/entry page names (pageview_url)
   ii. Grouping by pageview_url(page name) and using count and case to 
	   calculate the total_sessions and bounce rates of home and lander-1 pages
*/
select 
	entry_page_per_session.pageview_url,
    count(distinct pageviews_per_session.website_session_id) as total_sessions,
    count(case when pageviews_per_session.pageviews_per_session = 1 then pageviews_per_session.website_session_id end) as bounced_sessions,
    count(case when pageviews_per_session.pageviews_per_session = 1 then pageviews_per_session.website_session_id end)/
    count(distinct pageviews_per_session.website_session_id) as bounce_rate
from pageviews_per_session
	inner join entry_page_per_session
		on pageviews_per_session.website_session_id = entry_page_per_session.website_session_id
group by 
	entry_page_per_session.pageview_url;
    

/* RESULTS:
   For home page (as the landing/entry page):
   total_sessions = 2261, bounced sessions = 1319 and bounce rate = 58.34%
   For the test lander-1 page (as the landing/entry page):
   total_sessions = 2316, bounced sessions = 1233 and bounce rate = 53.24%
   
   INSIGHTS: The custom landing page 'lander-1' succeeded the test against the home page
   by having a lower bounce rate of 53.24% vs the 58.34% bounce rate of the home page */
   
   
   -- ANALYZING & TESTING CONVERSION FUNNELS:
   
/* Q5. Mail Received on 5th September,2012
I’d like to understand where we lose our gsearch nonbrand visitors between the new /lander-1 page and placing an order. 
Can you build us a full conversion funnel, analyzing how many customers make it to each step?
Start with /lander-1 and build the funnel all the way to our thank you page. Please use data since August 5th.
*/


/* SOLUTION: The request places the following constraints:
   i. date/ created_at must be between '2012-08-05' and '2012-09-05'
   ii. utm_source = 'gsearch' and utm_campaign = 'nonbrand' (website_sessions table)  */


/* STEP 1: We have to figure out the flow/sequence of steps that the user goes through for placing an order. 
This helps us understand our conversion funnel/user path to be analyzed. 
For this we will have to have to explore the website_pageviews table as it contains info on all the web pages. 

Exploring the website_pageviews table to find one session where the user 
began with the lander-1 page and reached the final thank-you-for-your-order page  */

select *
from website_pageviews
where 
	created_at between '2012-08-05' and '2012-09-05'
	and pageview_url in ('/lander-1','/thank-you-for-your-order')
order by 
	website_session_id;     
  
/* From the query above, website_session_id = 18867 began on the lander-1 page and ended on the thank-you page
   This session corresponds to a completed funnel. Let's explore this session.  */

select *
from website_pageviews 
where website_session_id = 18867;

/* From the query above, we extract the following sequence/conversion funnel:
 /lander-1 -> /products -> /the-original-mr-fuzzy -> cart -> /shipping -> /billing -> /thank-you-for-your-order  
 
 One thing to keep in mind is that we have several products, 'the-original-mr-fuzzy' is one of them. 
 So, it's possible to have several different conversion funnels that land on lander-1 and end on the thank you page 
 Let's just grab the number of products and their names from the products table. */
 
select * from products; 

/* So, we have 4 different products, viz. 'The Original Mr. Fuzzy', 'The Forever Love Bear',
   'The Birthday Sugar Panda' and 'The Hudson River Mini bear'. Given this, 
   we can have 4 different CONVERSION FUNNELS such as:
   /lander-1 -> /products -> /the-forever-love-bear -> cart -> /shipping -> /billing -> /thank-you-for-your-order  
   /lander-1 -> /products -> /the-birthday-sugar-panda -> cart -> /shipping -> /billing -> /thank-you-for-your-order etc.

   If that's the case we will have to evaluate each conversion funnel separately.
   This is something we have to keep in mind for later  */


/* STEP 2: 
   i. Grab all the website pageviews for gsearch nonbrand sessions only by 
      joining website_pageviews table to the website_sessions table.
   ii. Grab the pageview_id(landing_page_id) of all the landing pages of each session
   iii. Create a temporary table called landing_page_id to join it later to website_pageviews table to
        grab the pageview_url or names of all the landing pages.  */ 


drop temporary table if exists landing_page_id;

create temporary table landing_page_id
select 
	website_session_id,
    min(website_pageview_id) as landing_page_id
from (
	select 
	website_pageviews.website_pageview_id,     -- This subquery grabs all the website pageviews  
    website_pageviews.created_at,              -- for gsearch nonbrand sessions only
    website_pageviews.website_session_id,
    website_pageviews.pageview_url
from website_pageviews
	left join website_sessions
		on website_pageviews.website_session_id = website_sessions.website_session_id
where 
	website_sessions.created_at between '2012-08-05' and '2012-09-05'
	and website_sessions.utm_source = 'gsearch'
    and website_sessions.utm_campaign = 'nonbrand') as gsearch_nonbrand_pageviews
group by 
	website_session_id;
  
  
/* STEP 3: 
   i. Joining the landing_page_id temp table to website_pageviews table to grab the names of all landing_pages
   ii. Then, restricting to only those website sessions that landed on lander-1 
   iii. Creating a temporary table called landing_page  */

drop temporary table if exists landing_page;

create temporary table landing_page
select 
	landing_page_id.website_session_id,
    landing_page_id.landing_page_id,
    website_pageviews.pageview_url as landing_page_name
from landing_page_id
	inner join website_pageviews
		on landing_page_id.landing_page_id = website_pageviews.website_pageview_id
where 
	website_pageviews.pageview_url = '/lander-1';
    
select * from landing_page;


/* STEP 4: 
   i. Joining the landing_page temp table to website_pageviews table to grab all the pageviews 
      for all the website sessions that landed on/began with lander-1.
   ii. Then, checking how many different product pages we have to confirm all the possible conversion funnels.  */
   
select
    website_pageviews.pageview_url,
    count(landing_page.website_session_id) as count
from landing_page
	inner join website_pageviews
		on landing_page.website_session_id = website_pageviews.website_session_id
where 
	website_pageviews.pageview_url not in ('/lander-1','/products', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
group by 
	website_pageviews.pageview_url;

/* From the query above, we have only one product in the sequence that begins with lander-1
   and ends on the thank-you page. The product is '/the-original-mr-fuzzy'. 
   So, we have only one CONVERSION FUNNEL and that is 
  /lander-1 -> /products -> /the-original-mr-fuzzy -> cart -> /shipping -> /billing -> /thank-you-for-your-order  */
  

/* STEP 5:  
   i. Joining the landing_page temp table to website_pageviews table to grab all the pageviews 
      for all the website sessions that landed on/began with lander-1. 
   ii. Then, we are flagging different web pages of each session using case statements. 
       Basically, if in a session, someone moved to the products page from lander-1 page, we are flagging/marking it as a 1,
       if not, we are marking it as a 0 and we are doing it for all the pages in the conversion funnel  */

drop temporary table if exists flagged_webpages;

create temporary table flagged_webpages
select
	landing_page.website_session_id,
    website_pageviews.created_at,
    website_pageviews.pageview_url,
    case when website_pageviews.pageview_url = '/products' then 1 else 0 end as products_flagged,
    case when website_pageviews.pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mr_fuzzy_flagged,
    case when website_pageviews.pageview_url = '/cart' then 1 else 0 end as cart_flagged,
    case when website_pageviews.pageview_url = '/shipping' then 1 else 0 end as shipping_flagged,
    case when website_pageviews.pageview_url = '/billing' then 1 else 0 end as billing_flagged,
    case when website_pageviews.pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thanku_order_flagged
from landing_page
	inner join website_pageviews
		on landing_page.website_session_id = website_pageviews.website_session_id
order by 
	landing_page.website_session_id,
    website_pageviews.created_at;
    
select * from flagged_webpages;  -- Checking the temporary table 

/* STEP 6: 
   i. Now, we will group by the website_session_id (website sessions) to prepare a summary of all the web pages that were 
   hit/opened during every session (website_session_id).
   If, a page was hit/opened during a session, it will be marked as 1 else it will be marked with 0
   ii. Then, we will create a temporary table called 'hit_webpages_per_session'  */
 
drop temporary table if exists hit_webpages_per_session;

create temporary table hit_webpages_per_session
select 
	website_session_id,
    max(products_flagged) as products_hit,
    max(mr_fuzzy_flagged) as mr_fuzzy_hit,
    max(cart_flagged) as cart_hit,
    max(shipping_flagged) as shipping_hit,
    max(billing_flagged) as billing_hit,
    max(thanku_order_flagged) as thanku_order_hit
from flagged_webpages
group by website_session_id;

select * from hit_webpages_per_session;  -- checking the temporary table 

/* STEP 7: 
   We will calculate the click through rates of each web page in the conversion funnel by using 
   the count and case method and 'hit_webpages_per_session temp table'  */

select 
    count(case when products_hit = 1 then website_session_id else null end)/count(website_session_id) 
		as lander1_to_products_click_rt,
    count(case when mr_fuzzy_hit = 1 then website_session_id else null end)/count(case when products_hit = 1 then website_session_id else null end)
		as products_to_mr_fuzzy_click_rt,
    count(case when cart_hit = 1 then website_session_id else null end)/count(case when mr_fuzzy_hit = 1 then website_session_id else null end)
		as mr_fuzzy_to_cart_click_rt,
    count(case when shipping_hit = 1 then website_session_id else null end)/count(case when cart_hit = 1 then website_session_id else null end)
		as cart_to_shipping_click_rt,
    count(case when billing_hit = 1 then website_session_id else null end)/count(case when shipping_hit = 1 then website_session_id else null end)
		as shipping_to_billing_click_rt,
    count(case when thanku_order_hit = 1 then website_session_id else null end)/count(case when billing_hit = 1 then website_session_id else null end)
		as billing_to_thanku_click_rt
from hit_webpages_per_session;

/* RESULTS: 
   Of all the users who land on lander-1, 47.07% of them move on to the products page.
   74.09% of those users move on to 'the-original-mr-fuzzy' page.
   43.59% of those users move on to the cart.
   66.62% of those users move on to the shipping page.
   79.34% of those users move on to the billing page and 
   Of all the people who reach the billing page, only 43.77% of those users 
   move on to the final thank-you-for-your-order page. 
   
   INSIGHTS: 
   In our CONVERSION FUNNEL, we are losing most of our customer on lander-1, the-original-mr-fuzzy and the billing page.
   We should focus on these 3 pages, with an early empahsis on the billing page. People might not be comfortable 
   wntering their credit card details at this stage, that's y the fall off. 
   We could build a new custom test billing page and gauge it's performance.  */
   

   
   