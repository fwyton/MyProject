/****** Object:  StoredProcedure [dbo].[SS_ExecuteCandidateTrackSearch]    Script Date: 01/20/2011 17:40:18 ******/
DROP PROCEDURE [dbo].[SS_ExecuteCandidateTrackSearch]
GO
/****** Object:  StoredProcedure [dbo].[SS_ExecuteCandidateTrackSearch]    Script Date: 01/20/2011 17:40:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Frank Wyton
-- Create date: 9 Sept 2010
-- Description:	<Description,,>
-- Modified date: 6 Dec 2010 <Added ApplicanctID>
-- =============================================
CREATE PROCEDURE [dbo].[SS_ExecuteCandidateTrackSearch] 
	@CandidateName varchar(500),
	@StatusIds xml,
	@JobTitleIds xml,
	@DueDates xml,
	@MinRating int,
	@InterviewDates xml,
	@StatusOperator bit,
	@DueDateOperator int,
	@InterviewDateOperator int,
	@OfficeIds xml,
	@AssignedToUserIds xml
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	SELECT	I.CandidateItemId AS CandidateId,     
			I.Title AS CandidateName,
			ISNULL(I.JobTitle, '') AS JobTitle,
			S.[Status],
			I.DueDate,
			I.LastInterviewDate,
			ISNULL(I.MaxRating, 0) AS MaxRating
						
	FROM	CandidateItemFull AS I
			LEFT OUTER JOIN Applicant AS A ON I.ApplicantID = A.ApplicantId 
			LEFT OUTER JOIN IssueTracking_Status AS S ON I.StatusID = S.StatusID 
			LEFT OUTER JOIN IssueTracking_Type AS T ON I.ItemTypeID = T.IssueTypeID
			LEFT OUTER JOIN AllUsers AS U1 ON I.AssignedTo = U1.UserID
			LEFT OUTER JOIN AllUsers AS U2 ON I.CreatedBy = U2.UserID
			LEFT OUTER JOIN AllUsers AS U3 ON I.UpdatedBy = U3.UserID
	WHERE 1=1 
		
			/* ASSIGNED TO / HISTORIC ASSIGNEES*/ 
	AND		(dbo.SS_XMLListLength(@AssignedToUserIds) = 0 OR 
			I.AssignedTo IN (SELECT item FROM dbo.SS_XMLIntList(@AssignedToUserIds)))
			
			/* JOB TITLES */ 
	AND		(dbo.SS_XMLListLength(@JobTitleIds) = 0 OR 
			I.JobTitleId IN (SELECT item FROM dbo.SS_XMLIntList(@JobTitleIds)))

			/* OFFICES */ 
	AND		(dbo.SS_XMLListLength(@OfficeIds) = 0 OR 
			ISNULL(I.RDIOfficeId,0) IN (SELECT item FROM dbo.SS_XMLIntList(@OfficeIds)))
		
			/* DUE DATES */
	AND		(dbo.SS_XMLListLength(@DueDates) = 0 OR 
			 dbo.SS_XMLDatePairOperation(@DueDates, @DueDateOperator, I.DueDate) = 1)			

			/* INTERVIEW DATES */
	AND		(dbo.SS_XMLListLength(@InterviewDates) = 0 OR 
			 dbo.SS_XMLDatePairOperation(@InterviewDates, @InterviewDateOperator, I.LastInterviewDate) = 1)			
			
	AND	
			/* STATUS */
			(dbo.SS_XMLListLength(@StatusIds) = 0 OR 
			(@StatusOperator = 0 AND I.StatusId IN (SELECT item FROM dbo.SS_XMLIntList(@StatusIds))) OR 
			(@StatusOperator = 1 AND I.StatusId NOT IN (SELECT item FROM dbo.SS_XMLIntList(@StatusIds))))			 			 
			
		
			/* TITLE */
	AND		(@CandidateName IS NULL OR (LTRIM(RTRIM(@CandidateName)) = '' OR 
				(A.firstname + ' ' + A.lastname like REPLACE(@CandidateName,' ','%') + '%' OR 
				I.title like '%' + @CandidateName + '%'))								
			)
	
	AND		(I.MaxRating >= @MinRating OR @MinRating = 0)
	
	GROUP BY I.CandidateItemId, I.Title, I.DueDate, I.LastInterviewDate, S.[Status], I.JobTitle, I.MaxRating
		

END
GO


GRANT  EXECUTE  ON [dbo].[SS_ExecuteCandidateTrackSearch]  TO [RDI_Admin]
GO

GRANT  EXECUTE  ON [dbo].[SS_ExecuteCandidateTrackSearch]  TO [RDI_Employee]
GO

GRANT  EXECUTE  ON [dbo].[SS_ExecuteCandidateTrackSearch]  TO [RDI_Project_Manager]
GO

GRANT  EXECUTE  ON [dbo].[SS_ExecuteCandidateTrackSearch]  TO [RDI_Branch_Manager]
GO