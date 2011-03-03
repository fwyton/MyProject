/****** Object:  StoredProcedure [dbo].[CIS_SearchResults]    Script Date: 01/11/2011 11:39:15 ******/
DROP PROCEDURE [dbo].[CIS_SearchResults]
GO
/****** Object:  StoredProcedure [dbo].[CIS_SearchResults]    Script Date: 01/11/2011 11:39:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[CIS_SearchResults]
@ShowInactive bit = 0,
@ContactFirstName varchar(255) = null,
@ContactLastName varchar(255) = null,
@Company varchar(255) = null
as
begin
	set nocount on;

	select		0 AS 'Pending',
				clo.CLIENT_ID,
				null AS 'CLIENT_PENDING_ID',
				clo.CO_NAME,
				clo.DIVISION,
				clo.ADD1,
				clo.ADD2,
				clo.CITY,
				clo.STATE,
				clo.ZIPCODE,
				clo.PHYS_ADDR,
				clo.PHYS_ADDR2,
				clo.PHYS_CITY,
				clo.PHYS_STATE,
				clo.PHYS_ZIP,
				cto.fname + ' ' + cto.lname as fullname,
				cto.TITLE,
				cto.tel_no + isnull(' ' + ext, '') as telephone,
				cto.CELL_NO,
				cto.EMAIL,
				cto.billing_contact,
				cto.contact_key
	from		clients clo with (nolock)
	left join		contacts cto with (nolock) on clo.client_id = cto.client_id
	where		clo.type not in (4,5)-- Exclude Old/Inactive or Out of Business Clients
	and			(
						@ContactFirstName is null
					or	(@ContactFirstName is not null and cto.fname like ('%' + @ContactFirstName + '%'))
						
				)
	and			(
						@ContactLastName is null
					or (@ContactLastName is not null and cto.lname like ('%' + @ContactLastName + '%'))
						
				)
	and			(
						@Company is null
					or	(@Company is not null and clo.co_name like ('%' + @Company + '%'))
					
				)
	and			(
						@ShowInactive = 1
					or  (@ShowInactive = 0 and (cto.active_flag = 1))
					or cto.active_flag is null
				)
	--order by	cl.co_name
	UNION ALL
	select		1 AS 'Pending',
				null AS 'CLIENT_ID',
				clp.CLIENT_PENDING_ID,
				clp.CO_NAME,
				clp.DIVISION,
				clp.ADD1,
				clp.ADD2,
				clp.CITY,
				clp.STATE,
				clp.ZIPCODE,
				clp.PHYS_ADDR,
				clp.PHYS_ADDR2,
				clp.PHYS_CITY,
				clp.PHYS_STATE,
				clp.PHYS_ZIP,
				ctp.fname + ' ' + ctp.lname as fullname,
				ctp.TITLE,
				ctp.tel_no + isnull(' ' + ext, '') as telephone,
				ctp.CELL_NO,
				ctp.EMAIL,
				ctp.billing_contact,
				ctp.contact_key
	from		cis_clients_pending_changes clp with (nolock)
	join		cis_contacts_pending_changes ctp with (nolock) on clp.pc_contact_pending_id = ctp.contact_pending_id
	where		(
						@ContactFirstName is null
					or	(@ContactFirstName is not null and ctp.fname like ('%' + @ContactFirstName + '%'))
						
				)
	and			(
						@ContactLastName is null						
					or (@ContactLastName is not null and ctp.lname like ('%' + @ContactLastName + '%'))
						
				)
	and			(
						@Company is null
					or	(@Company is not null and clp.co_name like ('%' + @Company + '%'))
					
				)
	and			(
						@ShowInactive = 1
					or  (@ShowInactive = 0 and (ctp.active_flag = 1))
				)
	--order by	cl.co_name;
end
GO


GRANT  EXECUTE  ON [dbo].[CIS_SearchResults]  TO [RDI_Admin]
GO

GRANT  EXECUTE  ON [dbo].[CIS_SearchResults]  TO [RDI_Employee]
GO

GRANT  EXECUTE  ON [dbo].[CIS_SearchResults]  TO [RDI_Project_Manager]
GO

GRANT  EXECUTE  ON [dbo].[CIS_SearchResults]  TO [RDI_Branch_Manager]
GO
