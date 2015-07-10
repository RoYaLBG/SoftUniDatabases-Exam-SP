CREATE PROCEDURE fn_TeamsJSON AS
	
	DECLARE match CURSOR FOR
		SELECT
			t.TeamName, 
			(SELECT TeamName FROM Teams homeTeams WHERE homeTeams.Id = tm.HomeTeamId) [HomeTeam],
			HomeGoals,
			(SELECT TeamName FROM Teams awayTeams WHERE awayTeams.Id = tm.AwayTeamId) [AwayTeam],
			AwayGoals,
			CONVERT(nvarchar(max), tm.MatchDate, 103) [Dt]
		FROM Teams t
		LEFT JOIN TeamMatches tm
		ON t.Id = tm.HomeTeamId OR t.Id = tm.AwayTeamId
		WHERE t.CountryCode = 'BG'
		ORDER BY t.TeamName, tm.MatchDate DESC

	DECLARE @previousTeam nvarchar(max) = ''

	DECLARE @currentTeam nvarchar(max),
			@homeTeam nvarchar(max),
			@awayTeam nvarchar(max),
			@homeGoals int,
			@awayGoals int,
			@date nvarchar(max)

	OPEN match

	FETCH NEXT FROM match INTO
		@currentTeam,
		@homeTeam,
		@homeGoals,
		@awayTeam,
		@awayGoals,
		@date


	PRINT '{"teams":['
	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		DECLARE @oneMatch nvarchar(max) = '{"'+@homeTeam+'":'+CAST(@homeGoals AS nvarchar(10))+',"'+@awayTeam+'":'+CAST(@awayGoals AS nvarchar(10))+',"date":'+ @date +'}'
		IF @homeTeam IS NULL AND @awayTeam IS NULL
		BEGIN
			SET @oneMatch = ''
		END

		IF @previousTeam != @currentTeam
		BEGIN
			IF @previousTeam != ''
			BEGIN
				PRINT ']},' 
			END
			PRINT '{"name":"'+@currentTeam+'","matches":[' + @oneMatch
		END

		IF @previousTeam = @currentTeam
		BEGIN
			PRINT ',' + @oneMatch
		END

		SET @previousTeam = @currentTeam
		FETCH NEXT FROM match INTO
			@currentTeam,
			@homeTeam,
			@homeGoals,
			@awayTeam,
			@awayGoals,
			@date
	END

	PRINT ']}]}'

	CLOSE match
	DEALLOCATE match
GO
