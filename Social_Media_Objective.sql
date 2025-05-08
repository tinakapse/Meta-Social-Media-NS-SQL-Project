USE ig_clone;

## =================================================== OBJECTIVE QUESTIONS ==================================================


-- --------------------------------------------------------------------------------------------------------------------------
## Q1. Are there any tables with duplicate or missing null values? If so, how would you handle them?
-- --------------------------------------------------------------------------------------------------------------------------

-- Checking for DUPLICATE values in the users table
SELECT username, COUNT(*)
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

--  Checking for NULL values in the users table
SELECT *
FROM users
WHERE username IS NULL;

-- --------------------------------------------------------------------------------------------------------------------------
## Q2. What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?
-- --------------------------------------------------------------------------------------------------------------------------
SELECT u.id AS user_id, u.username,
       COUNT(DISTINCT p.id) AS num_posts,
       COUNT(DISTINCT l.photo_id) AS num_likes,
       COUNT(DISTINCT c.id) AS num_comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username;

-- --------------------------------------------------------------------------------------------------------------------------
## Q3. Calculate the average number of tags per post (photo_tags and photos tables).
-- --------------------------------------------------------------------------------------------------------------------------

SELECT AVG(tags) AS avg_tags_per_post
FROM (SELECT p.id,COUNT(t.tag_id) AS tags
FROM photos p
LEFT JOIN photo_tags t ON p.id = t.photo_id 
GROUP BY p.id) AS num_tags;

-- --------------------------------------------------------------------------------------------------------------------------
## Q4. Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.
-- --------------------------------------------------------------------------------------------------------------------------

select u.id, u.username,
	coalesce(l.total_likes,0) as total_likes,
	coalesce(c.total_comments,0) as total_comments,
	(coalesce(l.total_likes, 0) + coalesce(c.total_comments, 0)) as total_engagements,
	rank() over(order by (coalesce(l.total_likes,0) + coalesce(c.total_comments,0)) desc ) as engagement_rankings
from users u 
left join ( select user_id,count(*) as total_likes from likes group by user_id) l on u.id=l.user_id
left join ( select user_id, count(*) as total_comments from comments group by user_id) c on u.id=c.user_id
order by engagement_rankings;

-- --------------------------------------------------------------------------------------------------------------------------
## Q5. Which users have the highest number of followers and followings?
-- --------------------------------------------------------------------------------------------------------------------------

with cte1 as (
	select 
    followee_id, 
    count(follower_id) as followers_count 
    from follows 
    group by followee_id
),
cte2 as (
	select 
		follower_id, 
        count(followee_id) as followings_count 
        from follows 
        group by follower_id
)
select
	u.id, 
    u.username,
	coalesce(cte1.followers_count,0)as followers_count,
	coalesce(cte2.followings_count,0) as followings_count
from users u
left join cte1 on u.id=cte1.followee_id
left join cte2 on u.id=cte2.follower_id 
order by followers_count desc, followings_count desc;
 
-- --------------------------------------------------------------------------------------------------------------------------
## Q6. Calculate the average engagement rate (likes, comments) per post for each user.
-- --------------------------------------------------------------------------------------------------------------------------

SELECT 
	u.id as user_id,
	u.username,
	COALESCE(p.num_posts, 0) AS num_posts,
	COALESCE(l.num_likes, 0) AS num_likes,
	COALESCE(c.num_comments, 0) AS num_comments,
	CASE 
		WHEN COALESCE(p.num_posts, 0) = 0 THEN 0
		ELSE (COALESCE(l.num_likes, 0) + COALESCE(c.num_comments, 0)) / COALESCE(p.num_posts, 0)
	END AS avg_engagement_rate
FROM users u
LEFT JOIN (SELECT user_id, COUNT(*) AS num_posts FROM photos
     GROUP BY user_id) p ON u.id = p.user_id
LEFT JOIN (SELECT user_id, COUNT(*) AS num_likes
     FROM likes
     GROUP BY user_id) l ON u.id = l.user_id
LEFT JOIN (SELECT user_id, COUNT(*) AS num_comments FROM comments GROUP BY user_id) c ON u.id = c.user_id
	ORDER BY avg_engagement_rate DESC;

-- --------------------------------------------------------------------------------------------------------------------------    
## Q7. Get the list of users who have never liked any post (users and likes tables)
-- --------------------------------------------------------------------------------------------------------------------------

SELECT
	u.id,
    u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

-- --------------------------------------------------------------------------------------------------------------------------    
## Q8. How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad
--     campaigns?
-- --------------------------------------------------------------------------------------------------------------------------

-- MOST USED TAGS:
SELECT 
    t.tag_name, 
    COUNT(pt.photo_id) AS tag_usage_count
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.tag_name
ORDER BY tag_usage_count DESC;

-- USER SEGMENT
SELECT 
    u.id AS user_id,
    u.username, 
    t.tag_name
FROM users u
JOIN likes l ON u.id = l.user_id
JOIN photos p ON l.photo_id = p.id
JOIN photo_tags pt ON p.id = pt.photo_id
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name,u.username,u.id;

-- --------------------------------------------------------------------------------------------------------------------------    
## Q9. Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How 
--     can this information guide content creation and curation strategies?
-- --------------------------------------------------------------------------------------------------------------------------

-- ****** Answered in Documented pdf file ******

-- --------------------------------------------------------------------------------------------------------------------------
## Q10. Calculate the total number of likes, comments, and photo tags for each user.
-- --------------------------------------------------------------------------------------------------------------------------

SELECT 
	u.id as id, 
    u.username,
	COALESCE(l.total_likes, 0) AS total_likes,
	COALESCE(c.total_comments, 0) AS total_comments,
	COALESCE(pt.total_photo_tags, 0) AS total_photo_tags
FROM users u
LEFT JOIN (
	SELECT 
		user_id, 
		COUNT(*) AS total_likes 
    FROM likes 
    GROUP BY user_id
) l ON u.id = l.user_id
LEFT JOIN (
	SELECT 
		user_id, 
        COUNT(*) AS total_comments 
        FROM comments 
        GROUP BY user_id
) c ON u.id = c.user_id
LEFT JOIN (
	SELECT 
		tag_id, 
        COUNT(*) AS total_photo_tags 
        FROM photo_tags 
        GROUP BY tag_id
) pt ON u.id = pt.tag_id;
	
-- --------------------------------------------------------------------------------------------------------------------------
## Q11. Rank users based on their total engagement (likes, comments, shares) over a month.
-- --------------------------------------------------------------------------------------------------------------------------

WITH MonthlyEngagement AS (
    SELECT u.id AS user_id, u.username, 
	COALESCE(l.total_likes, 0) AS total_likes, 
	COALESCE(c.total_comments, 0) AS total_comments,
	(COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) AS total_engagement
    FROM users u
    LEFT JOIN (
        SELECT user_id, COUNT(photo_id) AS total_likes
        FROM likes
        WHERE DATE(created_at) >= '2024-07-01' OR DATE(created_at) <= '2024-07-31'
        GROUP BY user_id) l ON u.id = l.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(id) AS total_comments
        FROM comments
        WHERE DATE(created_at) >= '2024-07-01' OR DATE(created_at) <= '2024-07-31'
        GROUP BY user_id) c ON u.id = c.user_id)
SELECT 
	user_id, 
    username, 
    total_likes, 
    total_comments, 
    total_engagement, 
    RANK() OVER (ORDER BY total_engagement DESC)
AS engagement_rank
FROM MonthlyEngagement
ORDER BY engagement_rank;

-- --------------------------------------------------------------------------------------------------------------------------
## Q12. Retrieve the hashtags that have been used in posts with the highest average number of likes.
-- 		Use a CTE to calculate the average likes for each hashtag first.
-- --------------------------------------------------------------------------------------------------------------------------

WITH Hashtag_Likes AS (
    SELECT ht.tag_name, COUNT(l.photo_id) AS total_likes, COUNT(DISTINCT p.id) AS total_posts
    FROM tags ht
    JOIN photo_tags pt ON ht.id = pt.tag_id
    JOIN photos p ON pt.photo_id = p.id
    LEFT JOIN likes l ON p.id = l.photo_id
    GROUP BY ht.tag_name),
Average_Likes_Per_Hashtag AS (
    SELECT tag_name, (CAST(total_likes AS FLOAT) / total_posts) AS avg_likes
    FROM Hashtag_Likes)
SELECT tag_name, round(avg_likes,2) as avg_Likes
FROM Average_Likes_Per_Hashtag
order by avg_likes desc
limit 5;

-- --------------------------------------------------------------------------------------------------------------------------
## Q13. Retrieve the users who have started following someone after being followed by that person
-- --------------------------------------------------------------------------------------------------------------------------

SELECT 
	f1.follower_id, 
    f1.followee_id
FROM follows f1
JOIN follows f2 ON f1.follower_id = f2.followee_id AND f1.followee_id = f2.follower_id
WHERE f1.created_at > f2.created_at;
 

