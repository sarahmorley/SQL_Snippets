	--CREATE TABLE Table1(
	--		[Name] VARCHAR (50) NULL,
	--		[importanceLevel] INT NULL,
	--		[ImportTime] DATETIME2(3)
	--)

	--INSERT INTO Table1
	--SELECT 'Name1', 1, GETUTCDATE()
	--UNION ALL
	--SELECT 'Name2', 2, GETUTCDATE()
	--UNION ALL
	--SELECT 'Name3', 3, GETUTCDATE()
	--UNION ALL
	--SELECT 'Name4', 1, DATEADD(Minute, -40, GETUTCDATE())
	--UNION ALL
	--SELECT 'Name5', 2, DATEADD(Minute, -40, GETUTCDATE())
	--UNION ALL
	--SELECT 'Name6', 3, DATEADD(Minute, -40, GETUTCDATE())


	IF OBJECT_ID('tempdb..##SelectedData') IS NOT NULL
		DROP TABLE ##SelectedData

	CREATE TABLE ##SelectedData (
			[Name] VARCHAR (50) NULL,
			[importanceLevel] INT NULL,
			[ImportTime] DATETIME2(3)
	)

	--Insert into the temp table, all records from table1 where the import time is older than 30 minutes but not older than an hour
	INSERT INTO ##SelectedData
	SELECT Name,
		   importanceLevel,
		   ImportTime
	FROM Table1
	WHERE ImportTime < DATEADD(minute, -30, GETUTCDATE()) AND ImportTime > DATEADD(Minute, -60, GETUTCDATE())

	--Create the body of the Email
	DECLARE @body NVARCHAR(MAX) =
	'<html>
		<body>
			<p>Dear All,
			  <br />
			  <br />
	          Here is the data with an importance level of '
		
	DECLARE @middleBody VARCHAR(MAX)= '	
			 </p>
			 <table border = 1 style="border-collapse:collapse; padding:6px">
				<tr style="background-color: #806ECB;">
					<th style="color:white"> Name </th>
					<th style="color:white"> Importance </th>
					<th style="color:white"> Import Time </th>
				</tr>' 

	DECLARE @endBody NVARCHAR(MAX) =
			'</table>
			 <br />
			 <p> Regards, 
				 <br />
				 Sarah. 
			 </p>
		</body>
	</html>'

	--List of recipients that will receive emails
	DECLARE @recipients VARCHAR(MAX) = 'xxxxxxxxx@hotmail.com'


	--Records with an importance level of 1 - Send email straight away
	IF (SELECT COUNT(*) FROM ##SelectedData WHERE importanceLevel = 1) > 0
	BEGIN
		DECLARE @xmlHigh NVARCHAR(MAX) = CAST(( SELECT [Name] AS 'td','',
													   [importanceLevel] AS 'td','',
													   CAST([ImportTime] as VARCHAR) AS 'td',''
												FROM ##SelectedData
												WHERE importanceLevel = 1
										 FOR XML PATH('tr'), ELEMENTS) AS NVARCHAR(MAX))
	
		DECLARE @bodyHigh NVARCHAR(MAX) = @body + '1' + @middleBody + @xmlHigh + @endBody
		DECLARE @SP_alertSubjectHigh VARCHAR (100) = 'Level One email ' + LEFT(CONVERT(VARCHAR, GETUTCDATE(), 120), 10)

		EXEC msdb..sp_send_dbmail
		@recipients = @recipients,
		@from_address = '"No Reply" <no-reply@xxxxxx.xx>',
		@subject = @SP_alertSubjectHigh,
		@body = @bodyHigh,
		@body_format ='HTML',
		@importance = 'HIGH';

	END

	--Records with an importance level of 2 -Send email between 9am and 6pm, Monday to Friday only
	IF (SELECT COUNT(*) FROM ##SelectedData WHERE importanceLevel = 2 ) > 0
	AND DATEPART(hour, GETUTCDATE()) BETWEEN 9 AND 18
	AND DATEPART(dw, GETUTCDATE()) in (2,3,4,5,6)
	BEGIN
		DECLARE @xmlMed NVARCHAR(MAX) = CAST(( SELECT [Name] AS 'td','',
													  [importanceLevel] AS 'td','',
													  CAST([ImportTime] as VARCHAR) AS 'td',''
												FROM ##SelectedData
												WHERE importanceLevel = 2
										FOR XML PATH('tr'), ELEMENTS) AS NVARCHAR(MAX))

		DECLARE @bodyMed NVARCHAR(MAX) = @body +'2' + @middleBody + @xmlMed + @endBody
		DECLARE @SP_alertSubjectMed VARCHAR (100) = 'Level Two email ' + LEFT(CONVERT(VARCHAR, GETUTCDATE(), 120), 10)

		EXEC msdb..sp_send_dbmail
		@recipients = @recipients,
		@from_address = '"No Reply" <no-reply@xxxxxxxx.ie>',
		@subject = @SP_alertSubjectMed,
		@body = @bodyMed,
		@body_format ='HTML',
		@importance = 'HIGH';

	END

