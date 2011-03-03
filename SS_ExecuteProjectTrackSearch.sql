/****** Object:  StoredProcedure [dbo].[SS_ExecuteProjectTrackSearch]    Script Date: 02/14/2011 12:24:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Frank Wyton
-- Create date: Sept, 2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SS_ExecuteProjectTrackSearch] 
	@UserId int,
	@Title varchar(500),
	@Description varchar(500),
	@Comments varchar(500),
	@PriorityIds xml,
	@StatusIds xml,
	@TypeIds xml,
	@DueDates xml,
	@CreateDates xml,
	@UpdateDates xml,
	@ProjectIds xml,
	@PriorityOperator bit,
	@StatusOperator bit,
	@TypeOperator bit,
	@DueDateOperator int,
	@CreateDateOperator int,
	@UpdateDateOperator int,
	@AssignedToUserIds xml,
	@CreatedByUserIds xml,
	@IncludeHistoricAssignee bit
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	/* Get UserType */
	DECLARE @UserType varchar(20)

	SELECT	@UserType = [TYPE]
	FROM	AllUsers
	WHERE	userID = @UserID  


	/* Main query */
	SELECT	TOP(1000) I.IssueID,     
			I.Title,
			ISNULL(I.[Description], '') AS [Description],
			I.StatusID,
			I.CreateDate,
			I.upd_date AS UpdateDate,
			I.IssueTypeID, 
			I.CLIENT_ID, 
			I.PROJECT_NO,
			I.PHASE,
			I.TASK,
			I.CLIENT_ID As ClientID,
			I.PROJECT_NO As ProjectNo,
			(CAST(I.Client_ID AS varchar(10)) + '.' + RIGHT('000' + CAST(I.Project_No AS varchar(10)), 3)) 
				+ '.' + CAST(I.Phase AS varchar(5)) + '.' + CAST(I.Task AS varchar(5)) AS Project,
			I.PriorityID,
			I.Issue_DueDate AS DueDate,
			ISNULL(I.CreatedBy, 0) AS CreatedByUserId,
			ISNULL(I.UpdatedBy, 0) AS UpdatedByUserId,
			ISNULL(I.AssignedTo, 0) AS AssignedToUserId,
			S.[Status],
			P.Priority,
			T.IssueType,
			C.CO_NAME + ' ' + PR.PROJ_NAME AS ClientProjectName,
			C.CO_NAME AS ClientName,
			PR.PROJ_NAME AS ProjectName,
			PH.[DESCRIPTION] AS PhaseDesc,
			TA.[DESCRIPTION] AS TaskDesc,
			ISNULL(U1.FirstName, '') + ' ' + ISNULL(U1.LastName, '') AS AssignedTo,
			ISNULL(U2.FirstName, '') + ' ' + ISNULL(U2.LastName, '') AS CreatedBy,
			ISNULL(U3.FirstName, '') + ' ' + ISNULL(U3.LastName, '') AS UpdatedBy
			
	FROM	IssueTracking_Issues AS I INNER JOIN IssueTracking_Priority AS P ON I.PriorityID = P.PriorityID
			LEFT OUTER JOIN IssueTracking_Status AS S ON I.StatusID = S.StatusID 
			LEFT OUTER JOIN IssueTracking_Type AS T ON I.IssueTypeID = T.IssueTypeID
			LEFT OUTER JOIN AllUsers AS U1 ON I.AssignedTo = U1.UserID
			LEFT OUTER JOIN AllUsers AS U2 ON I.CreatedBy = U2.UserID
			LEFT OUTER JOIN AllUsers AS U3 ON I.UpdatedBy = U3.UserID
			LEFT OUTER JOIN CLIENTS AS C ON I.CLIENT_ID = C.CLIENT_ID
			LEFT OUTER JOIN PROJ_NO AS PR ON I.CLIENT_ID = PR.CLIENT_ID AND I.PROJECT_NO = PR.PROJECT_NO
			LEFT OUTER JOIN PHASE AS PH ON I.CLIENT_ID = PH.CLIENT_ID AND I.PROJECT_NO = PH.PROJECT_NO AND I.PHASE = PH.PHASE
			LEFT OUTER JOIN TASK AS TA ON I.CLIENT_ID = TA.CLIENT_ID AND I.PROJECT_NO = TA.PROJECT_NO AND I.PHASE = TA.PHASE AND I.TASK = TA.TASK
			
	WHERE   (1 = 1)
		
			/* HIDE DELETED */
	AND		(dbo.SS_XMLListLength(@StatusIds) = 0 OR 
			(@StatusOperator <> 1 AND 10 NOT IN (SELECT item FROM dbo.SS_XMLIntList(@StatusIds)) AND S.[Status] <> 'Deleted'))
			
			/* ASSIGNED TO / HISTORIC ASSIGNEES*/ 
	AND		((dbo.SS_XMLListLength(@AssignedToUserIds) = 0 OR 
			I.AssignedTo IN (SELECT item FROM dbo.SS_XMLIntList(@AssignedToUserIds))) OR
			
			(@IncludeHistoricAssignee = 1 AND
			I.IssueID IN (
				SELECT	DISTINCT IssueID 
				FROM	IssueTracking_History
				WHERE	OldAssignedTo IN (SELECT item FROM dbo.SS_XMLIntList(@AssignedToUserIds)))))
			
			/* CREATED BY */ 
	AND		(dbo.SS_XMLListLength(@CreatedByUserIds) = 0 OR 
			I.CreatedBy IN (SELECT item FROM dbo.SS_XMLIntList(@CreatedByUserIds)))
			
			/* PROJECTS */
	AND		(dbo.SS_XMLListLength(@ProjectIds) = 0 OR	
			((CAST(I.CLIENT_ID AS varchar(5)) + '.' + 
			CAST(I.PROJECT_NO AS varchar(5)) + '.' + 
			CAST(I.PHASE AS varchar(5)) + '.' + 
			CAST(I.TASK as varchar(5))) IN (SELECT item FROM dbo.SS_XMLStringList(@ProjectIds))) 
			OR			
			((CAST(I.CLIENT_ID AS varchar(5)) + '.' + 
			CAST(I.PROJECT_NO AS varchar(5)) + '.' + 
			CAST(I.PHASE AS varchar(5)) + '.0') IN (SELECT item FROM dbo.SS_XMLStringList(@ProjectIds)))			
			OR			
			((CAST(I.CLIENT_ID AS varchar(5)) + '.' + 
			CAST(I.PROJECT_NO AS varchar(5)) + '.0.0') IN (SELECT item FROM dbo.SS_XMLStringList(@ProjectIds)))			
			OR			
			((CAST(I.CLIENT_ID AS varchar(5)) + '.0.0.0') IN (SELECT item FROM dbo.SS_XMLStringList(@ProjectIds))))
			
			/* DUE DATES */
	AND		(dbo.SS_XMLListLength(@DueDates) = 0 OR 
			 dbo.SS_XMLDatePairOperation(@DueDates, @DueDateOperator, I.Issue_DueDate) = 1)			

			/* CREATE DATES */
	AND		(dbo.SS_XMLListLength(@CreateDates) = 0 OR 
			 dbo.SS_XMLDatePairOperation(@CreateDates, @CreateDateOperator, I.CreateDate) = 1)			

			/* UPDATE DATES */
	AND		(dbo.SS_XMLListLength(@UpdateDates) = 0 OR 
			 dbo.SS_XMLDatePairOperation(@UpdateDates, @UpdateDateOperator, I.upd_date) = 1)			
			
	AND
			/* PRIORITY */
			(dbo.SS_XMLListLength(@PriorityIds) = 0 OR 
			(@PriorityOperator = 0 AND I.PriorityId IN (SELECT item FROM dbo.SS_XMLIntList(@PriorityIds))) OR 
			(@PriorityOperator = 1 AND I.PriorityId NOT IN (SELECT item FROM dbo.SS_XMLIntList(@PriorityIds))))			 			 
	AND	
			/* STATUS */
			(dbo.SS_XMLListLength(@StatusIds) = 0 OR 
			(@StatusOperator = 0 AND I.StatusId IN (SELECT item FROM dbo.SS_XMLIntList(@StatusIds))) OR 
			(@StatusOperator = 1 AND I.StatusId NOT IN (SELECT item FROM dbo.SS_XMLIntList(@StatusIds))))			 			 
	AND	
			/* TYPE */
			(dbo.SS_XMLListLength(@TypeIds) = 0 OR 
			(@TypeOperator = 0 AND I.IssueTypeID IN (SELECT item FROM dbo.SS_XMLIntList(@TypeIds))) OR 
			(@TypeOperator = 1 AND I.IssueTypeID NOT IN (SELECT item FROM dbo.SS_XMLIntList(@TypeIds))))			 			 
			
			/* TITLE */
	AND		(@Title IS NULL OR (LTRIM(RTRIM(@Title)) = '' OR I.Title LIKE '%' + @Title + '%'))
		
			/* DESCRIPTION */
	AND		(@Description IS NULL OR (LTRIM(RTRIM(@Description)) = '' OR I.[Description] LIKE '%' + @Description + '%'))

			/* COMMENTS */
	AND		(@Comments IS NULL OR (LTRIM(RTRIM(@Comments)) = '' OR 
			I.IssueID IN (SELECT DISTINCT IssueID FROM IssueTracking_History WHERE Comments LIKE '%' + @Comments + '%')))
		
			/* Client User Type */
	AND		(@UserType <> 'Client' OR
			(@UserType = 'Client' AND 
			CAST(i.CLIENT_ID AS varchar(5)) + '.' + 
			CAST(i.PROJECT_NO AS varchar(5)) IN 
				(SELECT		CAST(CLIENT_ID AS varchar(5)) + '.' + CAST(PROJECT_NO AS varchar(5)) 
				 FROM		PT_AppSecurityUsers 
				 WHERE		UserID = @UserID)))

			/* IssueType IN IssueTypes for ProjectItems */
	AND		(I.IssueTypeID IN 
				(SELECT IssueTypeID 
				 FROM	IssueTracking_Type 
				 WHERE	ApplicationId IN 
					(SELECT TOP 1 app_id 
					 FROM	[Application] 
					 WHERE	app_name = 'Issue Tracking')))
					
END

GO


GRANT  EXECUTE  ON [dbo].[SS_ExecuteProjectTrackSearch]  TO [RDI_Admin]
GO

GRANT  EXECUTE  ON [dbo].[SS_ExecuteProjectTrackSearch]  TO [RDI_Employee]
GO

GRANT  EXECUTE  ON [dbo].[SS_ExecuteProjectTrackSearch]  TO [RDI_Project_Manager]
GO

GRANT  EXECUTE  ON [dbo].[SS_ExecuteProjectTrackSearch]  TO [RDI_Branch_Manager]
GO