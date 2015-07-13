-- Exam Solutions (12 July 2015)
-- Author: RoYaL
--1
SELECT Name FROM Characters ORDER BY Name

--2
SELECT TOP 50 Name Game, cast(Start as date) Start FROM Games WHERE YEAR(Start) BETWEEN 2011 AND 2012 ORDER BY Start

--3
SELECT Username, SUBSTRING(Email, CHARINDEX('@', Email, 0) + 1, LEN(Email)) [Email Provider] FROM Users ORDER BY [Email Provider], Username

--4
SELECT Username, IpAddress [IP Address] FROM Users WHERE IpAddress LIKE '___.1%.%.___' ORDER BY Username

--5
SELECT Name Game,
	CASE
		WHEN DATEPART(hh, Start) >= 0 AND DATEPART(hh, Start) < 12 THEN 'Morning'
		WHEN DATEPART(hh, Start) >= 12 AND DATEPART(hh, Start) < 18 THEN 'Afternoon'
		WHEN DATEPART(hh, Start) >= 18 AND DATEPART(hh, Start) < 24 THEN 'Evening'
	END [Part of the Day],
	CASE
		WHEN Duration <= 3 THEN 'Extra Short'
		WHEN Duration BETWEEN 4 AND 6 THEN 'Short'
		WHEN Duration > 6 THEN 'Long'
		WHEN Duration IS NULL THEN 'Extra Long'
	END [Duration]
 FROM Games
 ORDER BY Game, Duration, [Part of the Day]

 --6
 SELECT SUBSTRING(Email, CHARINDEX('@', Email, 0) + 1, LEN(Email)) [Email Provider], COUNT(Id) [Number Of Users] FROM Users 
 GROUP BY SUBSTRING(Email, CHARINDEX('@', Email, 0) + 1, LEN(Email))
 ORDER BY [Number Of Users] DESC, [Email Provider] ASC

 --7
 SELECT g.Name Game, (SELECT gt.Name FROM GameTypes gt WHERE gt.Id = g.GameTypeId) [Game Type], Username, [Level], Cash, c.Name [Character]
 FROM Games g JOIN UsersGames ug ON ug.GameId = g.Id JOIN Users u ON u.Id = ug.UserId JOIN Characters c ON ug.CharacterId = c.Id
 ORDER BY [Level] DESC, Username, Game

--8
SELECT Username, g.Name Game, COUNT(i.Id) [Items Count], SUM(i.Price) [Items Price]
 FROM Users u
 LEFT JOIN UsersGames ug ON ug.UserId =u.Id 
 LEFT JOIN Games g ON g.Id = ug.GameId
 LEFT JOIN UserGameItems ugi ON ugi.UserGameId = ug.Id
 LEFT JOIN Items i ON i.Id = ugi.ItemId
 GROUP BY g.Name, Username
 HAVING COUNT(i.Id) >= 10
 ORDER BY [Items Count] DESC, [Items Price] DESC, Username

--9
SELECT Username, g.Name Game, MAX(c.Name) Character, 
SUM(its.Strength) + MAX(chs.Strength) + MAX(gts.Strength) [Strength], 
SUM(its.Defence) + MAX(chs.Defence) + MAX(gts.Defence) [Defence], 
SUM(its.Speed) + MAX(chs.Speed) + MAX(gts.Speed) [Speed], 
SUM(its.Mind) + MAX(chs.Mind) + MAX(gts.Mind) [Mind], 
SUM(its.Luck) + MAX(chs.Luck) + MAX(gts.Luck) [Luck]
 FROM Users u
 LEFT JOIN UsersGames ug ON ug.UserId =u.Id 
 LEFT JOIN Games g ON g.Id = ug.GameId
 LEFT JOIN GameTypes gt ON g.GameTypeId = gt.Id
 LEFT JOIN UserGameItems ugi ON ugi.UserGameId = ug.Id
 LEFT JOIN Items i ON i.Id = ugi.ItemId
 LEFT JOIN Characters c ON c.Id = ug.CharacterId
 LEFT JOIN [Statistics] chs ON chs.Id = c.StatisticId
 LEFT JOIN [Statistics] gts ON gts.Id = gt.BonusStatsId
 LEFT JOIN [Statistics] its ON its.Id = i.StatisticId
 GROUP BY Username, g.Name
 ORDER BY Strength DESC, Defence DESC, Speed DESC, Mind DESC, Luck DESC

 --10
 SELECT i.Name, i.Price, i.MinLevel, s.Strength, s.Defence, s.Speed, s.Luck, s.Mind FROM Items i JOIN [Statistics] s ON i.StatisticId = s.Id 
 WHERE 
	Mind > (SELECT AVG(Mind) FROM [Statistics]) AND
	Speed > (SELECT AVG(Speed) FROM [Statistics]) AND
	Luck > (SELECT AVG(Luck) FROM [Statistics])
 ORDER BY i.Name 

--11
SELECT i.Name Item, Price, MinLevel, gt.Name [Forbidden Game Type] 
FROM Items i 
LEFT JOIN GameTypeForbiddenItems gtfi ON gtfi.ItemId = i.Id
LEFT JOIN GameTypes gt ON gt.Id = gtfi.GameTypeId
ORDER BY [Forbidden Game Type] DESC, [Item] ASC

--12
DECLARE @GameId int = (SELECT Id FROM Games WHERE Name = 'Edinburgh')
DECLARE @UserId int = (SELECT Id FROM Users WHERE Username = 'Alex')
DECLARE @UserGameId int = (SELECT Id FROM UsersGames WHERE UserId = @UserId AND GameId = @GameId)

INSERT INTO UserGameItems (UserGameId, ItemId)
	SELECT @UserGameId, Id FROM Items WHERE Name IN ('Blackguard', 'Bottomless Potion of Amplification', 'Eye of Etlich (Diablo III)', 'Gem of Efficacious Toxin', 'Golden Gorget of Leoric', 'Hellfire Amulet')

UPDATE UsersGames SET Cash = Cash -(SELECT SUM(Price) FROM Items WHERE Name IN ('Blackguard', 'Bottomless Potion of Amplification', 'Eye of Etlich (Diablo III)', 'Gem of Efficacious Toxin', 'Golden Gorget of Leoric', 'Hellfire Amulet'))
WHERE Id = @UserGameId

SELECT Username, g.Name, Cash, i.Name [Item Name]
FROM Users u
LEFT JOIN UsersGames ug ON u.Id = ug.UserId
LEFT JOIN Games g ON g.Id = ug.GameId
LEFT JOIN Characters c ON c.Id = ug.CharacterId
LEFT JOIN UserGameItems ugi ON ugi.UserGameId = ug.Id
LEFT JOIN Items i ON i.Id = ugi.ItemId
WHERE g.Name = 'Edinburgh'
GROUP BY Username, g.Name, i.Name, Cash, u.Id, g.Id
ORDER BY [Item Name]
GO

--13

CREATE PROCEDURE usp_BuyItemsInRange(@userId int, @gameId int, @minLevel int, @maxLevel int)
AS
BEGIN
	BEGIN TRY
		BEGIN TRAN

			DECLARE @UserGameId int = (SELECT Id FROM UsersGames WHERE UserId = @userId AND GameId = @gameId)
			INSERT INTO UserGameItems (UserGameId, ItemId)
				SELECT @UserGameId, Id FROM Items WHERE MinLevel IN (@minLevel, @maxLevel)

			UPDATE UsersGames SET Cash = Cash -(SELECT SUM(Price) FROM Items WHERE MinLevel IN (@minLevel, @maxLevel))
			WHERE Id = @UserGameId

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN
	END CATCH
END
GO

DECLARE @GameId int = (SELECT Id FROM Games WHERE Name = 'Safflower')
DECLARE @UserId int = (SELECT Id FROM Users WHERE Username = 'Stamat')
EXEC usp_BuyItemsInRange 
	@userId = @UserId, 
	@gameId = @GameId, 
	@minLevel = 11, 
	@maxLevel = 12
EXEC usp_BuyItemsInRange 
	@userId = @UserId, 
	@gameId = @GameId, 
	@minLevel = 19, 
	@maxLevel = 21

DECLARE @UserGameId int = (SELECT Id FROM UsersGames WHERE UserId = @UserId AND GameId = @GameId)
SELECT Name [Item Name] FROM Items WHERE Id IN (SELECT ItemId FROM UserGameItems WHERE UserGameId = @UserGameId) ORDER BY [Item Name]
GO

--14
CREATE FUNCTION fn_CashInUserGames(@gameName nvarchar(max))
RETURNS TABLE
AS
	RETURN 
		WITH cash AS 
		(
			SELECT 
				ug.Cash [Cash], 
				ROW_NUMBER() OVER(ORDER BY ug.Cash DESC) RowId 
			FROM 
				UsersGames ug 
			INNER JOIN 
				Games g 
			ON g.Id = ug.GameId 
			WHERE 
				g.Name = @gameName
		)
		SELECT SUM(Cash) [SumCash] FROM cash WHERE RowId % 2 != 0
GO

SELECT [SumCash] FROM fn_CashInUserGames('Bali')
UNION
SELECT [SumCash] FROM fn_CashInUserGames('Lily Stargazer')
UNION
SELECT [SumCash] FROM fn_CashInUserGames('Love in a mist')
UNION
SELECT [SumCash] FROM fn_CashInUserGames('Mimosa')
UNION
SELECT [SumCash] FROM fn_CashInUserGames('Ming fern')
GO

--15
CREATE TRIGGER tr_UserGameItems ON UserGameItems INSTEAD OF INSERT
AS
BEGIN
	INSERT INTO UserGameItems (ItemId, UserGameId)
		SELECT ItemId, UserGameId FROM inserted
		INNER JOIN Items i
		ON i.Id = inserted.ItemId
		INNER JOIN UsersGames ug
		ON ug.Id = inserted.UserGameId
		WHERE i.MinLevel <= ug.[Level]
END

-- bonus
UPDATE UsersGames
SET Cash = Cash + 50000
WHERE 
	UserId IN (SELECT Id FROM Users WHERE Username IN ('baleremuda', 'loosenoise', 'inguinalself', 'buildingdeltoid', 'monoxidecos')) AND
	GameId = (SELECT Id FROM Games WHERE Name = 'Bali')

-- give cash for the already owned items
UPDATE UsersGames
SET Cash = Cash + (SELECT SUM(Price) FROM Items WHERE Id IN (SELECT ItemId FROM UserGameItems WHERE UserGameId = UsersGames.Id))
WHERE 
	UserId IN (SELECT Id FROM Users WHERE Username IN ('baleremuda', 'loosenoise', 'inguinalself', 'buildingdeltoid', 'monoxidecos')) AND
	GameId = (SELECT Id FROM Games WHERE Name = 'Bali')

-- add items

INSERT INTO UserGameItems (ItemId, UserGameId)
	SELECT DISTINCT Items.Id, UsersGames.Id 
	FROM Items, UsersGames 
	WHERE Items.Id BETWEEN 251 AND 299
	AND UsersGames.UserId IN (SELECT Users.Id FROM Users WHERE Username IN ('baleremuda', 'loosenoise', 'inguinalself', 'buildingdeltoid', 'monoxidecos'))
	AND UsersGames.GameId = (SELECT Id FROM Games WHERE Name = 'Bali')

	
INSERT INTO UserGameItems (ItemId, UserGameId)
	SELECT DISTINCT Items.Id, UsersGames.Id 
	FROM Items, UsersGames 
	WHERE Items.Id BETWEEN 501 AND 539
	AND UsersGames.UserId IN (SELECT Users.Id FROM Users WHERE Username IN ('baleremuda', 'loosenoise', 'inguinalself', 'buildingdeltoid', 'monoxidecos'))
	AND UsersGames.GameId = (SELECT Id FROM Games WHERE Name = 'Bali')


-- remove cash for before owned items + newly added items
UPDATE UsersGames
SET Cash = Cash - (SELECT SUM(Price) FROM Items WHERE Id IN (SELECT ItemId FROM UserGameItems WHERE UserGameId = UsersGames.Id))
WHERE 
	UserId IN (SELECT Id FROM Users WHERE Username IN ('baleremuda', 'loosenoise', 'inguinalself', 'buildingdeltoid', 'monoxidecos')) AND
	GameId = (SELECT Id FROM Games WHERE Name = 'Bali')

SELECT Username, g.Name, Cash, i.Name [Item Name]
FROM Users u
LEFT JOIN UsersGames ug ON u.Id = ug.UserId
LEFT JOIN Games g ON g.Id = ug.GameId
LEFT JOIN Characters c ON c.Id = ug.CharacterId
LEFT JOIN UserGameItems ugi ON ugi.UserGameId = ug.Id
LEFT JOIN Items i ON i.Id = ugi.ItemId
WHERE g.Name = 'Bali'
GROUP BY Username, g.Name, i.Name, Cash, u.Id, g.Id
ORDER BY Username, [Item Name]

-- 16
SELECT
	u.username username,
	u.fullname fullname,
	ja.title Job,
	s.from_value 'From Value',
	s.to_value 'To Value'
FROM
	users u
INNER JOIN job_ad_applications jap
ON jap.user_id = u.Id
INNER JOIN
	job_ads ja
ON ja.id = jap.job_ad_id
INNER JOIN
	salaries s
ON
	s.Id = ja.salary_id
ORDER BY u.username, ja.title