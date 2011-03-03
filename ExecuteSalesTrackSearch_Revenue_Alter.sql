/****** Object:  StoredProcedure [dbo].[SS_ExecuteSalesTrackSearch]    Script Date: 12/09/2010 09:12:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Frank Wyton
-- Create date: 9 Sept 2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SS_ExecuteSalesTrackSearch] 
	@Title varchar(500),
	@PriorityIds xml,
	@StatusIds xml,
	@TypeIds xml,
	@DueDates xml,
	@PriorityOperator bit,
	@StatusOperator bit,
	@TypeOperator bit,
	@DueDateOperator int,
	@OfficeIds xml,
	@ClientId int,
	@ClientFilter varchar(50),
	@AssignedToUserIds xml,
	@IncludeHistoricAssignee bit	
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	SELECT	I.RDIItemId,
			I.SalesItemId,     
			I.Title,
			ISNULL(I.[Description], '') AS [Description],
			ISNULL(I.Comments, '') AS Comments,
			I.StatusID,
			S.[Status],
			I.PriorityID,
			P.Priority,
			I.ItemTypeID, 
			T.IssueType,
			I.ClientId, 
			O.LOCATION AS Location,
			I.ProjectNo,
			I.Phase,
			I.Task,
			(CAST(I.ClientId AS varchar(10)) + '.' + RIGHT('000' + CAST(I.ProjectNo AS varchar(10)), 3)) 
				+ '.' + CAST(I.Phase AS varchar(5)) + '.' + CAST(I.Task AS varchar(5)) AS Project,
			C.CO_NAME + ' ' + PR.PROJ_NAME AS ClientProjectName,
			C.CO_NAME AS ClientName,
			PR.PROJ_NAME AS ProjectName,
			PH.[DESCRIPTION] AS PhaseDesc,
			TA.[DESCRIPTION] AS TaskDesc,
			I.ParentItemId,
			I.DueDate,
			I.ProposalDueDate,
			CAST(I.Revenue AS float) AS Revenue,
			I.CreateDate,
			ISNULL(I.CreatedBy, 0) AS CreatedByUserId,
			ISNULL(I.UpdatedBy, 0) AS UpdatedByUserId,
			ISNULL(I.AssignedTo, 0) AS AssignedToUserId,
			ISNULL(U1.FirstName, '') + ' ' + ISNULL(U1.LastName, '') AS AssignedTo,
			ISNULL(U2.FirstName, '') + ' ' + ISNULL(U2.LastName, '') AS CreatedBy,
			ISNULL(U3.FirstName, '') + ' ' + ISNULL(U3.LastName, '') AS UpdatedBy,
			I.upd_date AS UpdateDate
						
	FROM	SalesItemFull AS I INNER JOIN IssueTracking_Priority AS P ON I.PriorityID = P.PriorityID
			LEFT OUTER JOIN [RDI OFFICES] AS O ON I.RDIOfficeId = O.code
			LEFT OUTER JOIN IssueTracking_Status AS S ON I.StatusID = S.StatusID 
			LEFT OUTER JOIN IssueTracking_Type AS T ON I.ItemTypeID = T.IssueTypeID
			LEFT OUTER JOIN AllUsers AS U1 ON I.AssignedTo = U1.UserID
			LEFT OUTER JOIN AllUsers AS U2 ON I.CreatedBy = U2.UserID
			LEFT OUTER JOIN AllUsers AS U3 ON I.UpdatedBy = U3.UserID
			LEFT OUTER JOIN CLIENTS AS C ON I.ClientId = C.CLIENT_ID
			LEFT OUTER JOIN PROJ_NO AS PR ON I.ClientId = PR.CLIENT_ID AND I.ProjectNo = PR.PROJECT_NO
			LEFT OUTER JOIN PHASE AS PH ON I.ClientId = PH.CLIENT_ID AND I.ProjectNo = PH.PROJECT_NO AND I.Phase = PH.PHASE
			LEFT OUTER JOIN TASK AS TA ON I.ClientId = TA.CLIENT_ID AND I.ProjectNo = TA.PROJECT_NO AND I.Phase = TA.PHASE AND I.Task = TA.TASK

	WHERE 1=1 
		
			
			/* ASSIGNED TO / HISTORIC ASSIGNEES*/ 
	AND		((dbo.SS_XMLListLength(@AssignedToUserIds) = 0 OR 
			I.AssignedTo IN (SELECT item FROM dbo.SS_XMLIntList(@AssignedToUserIds))) OR
			
			(@IncludeHistoricAssignee = 1 AND
			I.RDIItemId IN (
				SELECT	DISTINCT IssueID 
				FROM	IssueTracking_History
				WHERE	OldAssignedTo IN (SELECT item FROM dbo.SS_XMLIntList(@AssignedToUserIds)))))
			
		
			/* DUE DATES */
	AND		(dbo.SS_XMLListLength(@DueDates) = 0 OR 
			 dbo.SS_XMLDatePairOperation(@DueDates, @DueDateOperator, I.DueDate) = 1)			
			
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
			(@TypeOperator = 0 AND I.ItemTypeID IN (SELECT item FROM dbo.SS_XMLIntList(@TypeIds))) OR 
			(@TypeOperator = 1 AND I.ItemTypeID NOT IN (SELECT item FROM dbo.SS_XMLIntList(@TypeIds))))			 			 

	AND	
			/* OFFICE */
			(dbo.SS_XMLListLength(@OfficeIds) = 0 OR 
			I.RDIOfficeID IN (SELECT item FROM dbo.SS_XMLIntList(@OfficeIds)))
			
			/* TITLE */
	AND		(@Title IS NULL OR (LTRIM(RTRIM(@Title)) = '' OR I.Title LIKE '%' + @Title + '%'))

			/* CLIENT */
	AND		(@ClientId = 0 OR @ClientId = I.ClientId)
		
			/* CLIENT FILTER */
	AND		(@ClientId <> 0 OR @ClientFilter = '' OR C.CO_NAME LIKE '%' + @ClientFilter + '%')

END
