USE [3pnrg]
GO
/****** Object:  StoredProcedure [dbo].[usp_checkForAlert]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_checkForAlert]
	@pil_id int,
	@totalWatt int,
	@date datetime
AS
begin
	declare @alert int=0,@sms varchar(20),@email varchar(100),@value int,@cond tinyint,@message varchar(100)

	start:
	select top 1 @alert=pila_id,@sms=pila_sms_phone,@email=pila_email,@value=pila_value,@cond=PILA_CONDITION
	from pilar_alerts
	where pil_id=@pil_id
	and cast(@date as date) between pila_date_from and pila_date_to
	and cast(@date as time) between pila_time_from and pila_time_to
	and pila_enabled=1 and pila_is_active=0
	and pila_id>@alert
	and (	(pila_condition=0 and @totalWatt>pila_value)
		or (pila_condition=1 and @totalWatt<pila_value)
		or (pila_condition=2 and @totalWatt>=pila_value)
		or (pila_condition=3 and @totalWatt<=pila_value)
		)

	if @@rowcount>0
	begin
		insert into pillar_events (pil_id,pile_date,pile_type,pila_id)
		values
		(@pil_id,@date,3,@alert)

		update pilar_alerts
		set pila_is_active=1 where pila_id=@alert

		select @message=case when (@cond=0 and @totalWatt>@value) then 'Alert. Total Watt ('+cast(@totalwatt as varchar(10))+' greater than '+cast(@value as varchar(10))
							when (@cond=1 and @totalWatt<@value) then 'Alert. Total Watt ('+cast(@totalwatt as varchar(10))+' less than '+cast(@value as varchar(10))
							end

		/*if @sms is not null
		begin
			insert into [EXANDAS].[ESAVL].[esavl].[SMS] (sms_date,sms_phone,sms_message,sms_send)
			values
			(@date,@sms,@message,0)
		end */

		goto start
	end
	else
	begin
		if not exists
		( select *
			from pilar_alerts
			where pil_id=@pil_id
			and cast(@date as date) between pila_date_from and pila_date_to
			and cast(@date as time) between pila_time_from and pila_time_to
			and pila_enabled=1 
			and (	(pila_condition=0 and @totalWatt>pila_value)
				or (pila_condition=1 and @totalWatt<pila_value)
				or (pila_condition=2 and @totalWatt>=pila_value)
				or (pila_condition=3 and @totalWatt<=pila_value)
				)
		)
		update  pilar_alerts  set pila_is_active=0
		where pil_id=@pil_id
	end
	

end

GO
/****** Object:  StoredProcedure [dbo].[usp_dailyPowerUsage]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_dailyPowerUsage]
	@pil_id int,
	@dateFrom date,
	@dateTo date
	
AS
	begin

		select cast(e_date as date) as 'date', avg(entries.E_L1)+avg(entries.E_L2)+avg(entries.E_L3) as 'average'
		from entries
		where cast(ENTRIES.E_DATE as time) between cast('00:00' as time) and cast('04:00' as time)
		and e_date between @dateFrom and @dateTo
		group by cast(e_date as date)
		order by cast(e_date as date)

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_deleteAlert]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_deleteAlert]
	@pila_id int
AS
	begin
		delete from dbo.pilar_alerts
		where pila_id = @pila_id

		select @pila_id as 'deleted'
	end

GO
/****** Object:  StoredProcedure [dbo].[usp_ektimisiVlavis]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ektimisiVlavis](
	@pillarID int
	--@today date = current_timestamp
)
	
AS
	begin

		declare @maxWatt int
		declare @averageWatt int
		declare @today date = current_timestamp

		select @maxWatt = sum(pole_light.poll_watt)
		from pole,pole_light
		where pole_light.pol_id = pole.pol_id
		and pole.pil_id = @pillarID

		select @averageWatt = (avg(entries.E_L1)+avg(entries.E_L2)+avg(entries.E_L3))
		from entries
		where ENTRIES.E_DATE between dateadd(hh,-2,cast(@today as datetime)) and dateadd(hh,2,cast(@today as datetime))
		--select @maxWatt
		--select @averageWatt
		select @maxWatt-@averageWatt
		

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_getAlertsForPillar]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_getAlertsForPillar]
	@pil_id int
AS
	begin
		
		select * from dbo.pilar_alerts
		where pil_id = @pil_id
		
	end

GO
/****** Object:  StoredProcedure [dbo].[usp_getDailyTotalUsage]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_getDailyTotalUsage]
	@pil_id int,
	@dateIn date
AS
	begin	
		declare @lastdate bigint

		select top 1 @lastdate = E_T_NRG
		from dbo.ENTRIES
		where CONVERT(date,E_DATE) = @dateIn
		order by E_DATE asc

		select top 1 E_T_NRG - @lastdate as 'total'
		from dbo.ENTRIES
		where CONVERT(date,E_DATE) = @dateIn
		order by E_DATE desc

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_getLatestPoleImage]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_getLatestPoleImage]
		@pol_id int
AS
	begin

		SELECT TOP 1
			POLE_IMAGES.POLI_IMAGE
			,CONVERT(varchar,POLE_IMAGES.POLI_DATE,120) as 'POLI_DATE'
			,POLE_IMAGES.POLI_DESCR
		FROM POLE_IMAGES
		WHERE POLE_IMAGES.POL_ID = @pol_id

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_getLightTypes]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_getLightTypes]
	
AS
	begin
		
		select * from dbo.light_type
		
	end

GO
/****** Object:  StoredProcedure [dbo].[usp_getPillarEvents]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_getPillarEvents]
	@pil_id int,
	@dateFrom datetime,
	@dateTo datetime
	
AS
	begin

		select pile_id
			,CONVERT(varchar,pile_date,120) as 'pile_date'
			,pile_type
			,pile_status
			,CONVERT(varchar,pile_inserted,120) as 'pile_inserted'
			,CONVERT(varchar,pile_committed,120) as 'pile_committed'
		from dbo.pillar_events
		where pil_id = @pil_id
		and pile_date between @dateFrom and @dateTo

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_getPoleTypes]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[usp_getPoleTypes]
	
AS
	begin
		
		select * from dbo.pole_type
		
	end

GO
/****** Object:  StoredProcedure [dbo].[usp_getTotalUsage]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_getTotalUsage]
	@pil_id int,
	@dateFrom date,
	@dateTo date
AS
	begin	
		declare @lastdate bigint

		select top 1 @lastdate = E_T_NRG
		from dbo.ENTRIES
		where E_DATE between @dateFrom and @dateTo
		order by E_DATE asc

		select top 1 E_T_NRG - @lastdate as 'total'
		from dbo.ENTRIES
		where E_DATE between @dateFrom and @dateTo
		order by E_DATE desc

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_insertAlert]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_insertAlert](
	@pil_id int,
	@enabled smallint,
	@datefrom date,
	@dateto date,
	@timefrom time,
	@timeto time,
	@condition smallint, --0: Greater Than ; 1:Less than  ; 2:Greater or equal to ; 3:Less or equal to
	@pvalue int,
	@sms varchar(255),
	@email varchar(255)
)

	
AS
	begin

		insert into dbo.pilar_alerts (
			PIL_ID
			,PILA_ENABLED
			,PILA_DATE_FROM
			,PILA_DATE_TO
			,PILA_TIME_FROM
			,PILA_TIME_TO
			,PILA_CONDITION
			,PILA_VALUE
			,PILA_SMS_PHONE
			,PILA_EMAIL
		)
		values (
			@pil_id
			,@enabled
			,@datefrom
			,@dateto
			,@timefrom
			,@timeto
			,@condition
			,@pvalue
			,@sms
			,@email
		)

		select @@identity as 'insertedID'

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_reportByDay]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_reportByDay]
	@pil_id int,
	@dateFrom date,
	@dateTo date
	
AS
	begin

		select
			CONVERT(varchar, convert(date,dateadd(DAY,0, datediff(day,0, E_DATE)) ),120) as 'TimeSep'
			--,E_CN
			,avg(E_L1) as 'Fasi1_watt'
			,avg(E_L2) as 'Fasi2_watt'
			,avg(E_L3) as 'Fasi3_watt'
			,max(E_T_NRG)-min(E_T_NRG) as 'Kwh'
			--,(case when datepart(hour,E_DATE) <13 then 0 else 1 end) as 'pm'
			--,E_T_NRG as'watt_hours'
		from dbo.ENTRIES,dbo.DEVICES
		where ENTRIES.DEV_ID = DEVICES.DEV_ID
		and DEVICES.PIL_ID = @pil_id
		and CONVERT(date,ENTRIES.E_DATE) between @dateFrom and @dateTo
		group by dateadd(DAY,0, datediff(day,0, E_DATE))
		--case when datepart(hour,E_DATE) <13 then 0 else 1 end
		order by dateadd(DAY,0, datediff(day,0, E_DATE)) asc

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_reportByHour]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_reportByHour]
	@pil_id int,
	@dateIn date
	
AS
	begin

		
		select
			CONVERT(varchar,datepart(hour,E_DATE))+':00' as 'TimeSep'
			,datepart(dd,ENTRIES.E_DATE) as 'day'
			,datepart(mm,ENTRIES.E_DATE) as 'month'
			--,E_CN
			,avg(E_L1) as 'Fasi1_watt'
			,avg(E_L2) as 'Fasi2_watt'
			,avg(E_L3) as 'Fasi3_watt'
			,max(E_T_NRG)-min(E_T_NRG) as 'Kwh'
			
			--,E_T_NRG as'watt_hours'
		from dbo.ENTRIES,dbo.DEVICES
		where ENTRIES.DEV_ID = DEVICES.DEV_ID
		and DEVICES.PIL_ID = @pil_id
		and ENTRIES.E_DATE between dateadd(hh,-12,cast(@dateIn as datetime)) and dateadd(hh,12,cast(@dateIn as datetime))
		--and cast(ENTRIES.E_DATE as date) = @dateIn
		group by datepart(hour,E_DATE), datepart(day,E_DATE), datepart(month,E_DATE)
		order by datepart(month,E_DATE), datepart(day,E_DATE),datepart(hour,E_DATE) asc

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_reportByMonth]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_reportByMonth]
	@pil_id int,
	@dateFrom date,
	@dateTo date
	
AS
	begin

		select
			convert(varchar,dateadd(MONTH, datediff(MONTH,0, E_DATE),0),120) as 'TimeSep'
			,avg(cast(E_L1 as bigint)) as 'Fasi1_watt'
			,avg(cast(E_L2 as bigint)) as 'Fasi2_watt'
			,avg(cast(E_L3 as bigint)) as 'Fasi3_watt'
			,max(cast(E_T_NRG as bigint))-min(cast(E_T_NRG as bigint)) as 'Kwh'
			
		from dbo.ENTRIES,dbo.DEVICES
		where ENTRIES.DEV_ID = DEVICES.DEV_ID
		and DEVICES.PIL_ID = @pil_id
		--and CONVERT(date,ENTRIES.E_DATE) between @dateFrom and @dateTo
		and cast(ENTRIES.E_DATE as date) between @dateFrom and @dateTo
		group by dateadd(MONTH, datediff(MONTH,0, E_DATE),0)
		order by dateadd(MONTH,datediff(MONTH,0, E_DATE),0) asc

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_updateAlert]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_updateAlert](
	@pila_id int,
	@enabled smallint,
	@datefrom date,
	@dateto date,
	@timefrom time,
	@timeto time,
	@condition smallint, --0: Greater Than ; 1:Less than  ; 2:Greater or equal to ; 3:Less or equal to
	@pvalue int,
	@sms varchar(255),
	@email varchar(255)
)
	
AS
	begin
		update dbo.pilar_alerts 
		set
			PILA_ENABLED = @enabled
			,PILA_DATE_FROM = @datefrom
			,PILA_DATE_TO = @dateto
			,PILA_TIME_FROM = @timefrom
			,PILA_TIME_TO = @timeto
			,PILA_CONDITION = @condition
			,PILA_VALUE = @pvalue
			,PILA_SMS_PHONE = @sms
			,PILA_EMAIL = @email
		where PILA_ID = @pila_id
		
		select @pila_id as 'updated'
			
	end

GO
/****** Object:  StoredProcedure [dbo].[usp_updateLight]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_updateLight](
	@light_id int,
	@light_watt int,
	@light_type int
)
	
AS
	begin

		update dbo.pole_light
		set
			LIGT_ID = @light_type,
			POLL_WATT = @light_watt
		where
			POLL_ID = @light_id

	end

GO
/****** Object:  StoredProcedure [dbo].[usp_updatePole]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_updatePole](
	@pole_id int,
	@pole_type int,
	@pole_height int,
	@lat varchar(255),
	@lng varchar(255)
)
	
AS
	begin

		update dbo.POLE
		set
			POL_LAT = @lat,
			POL_LNG = @lng,
			POL_HEIGHT = @pole_height,
			POLT_ID = @pole_type
		where POL_ID = @pole_id

	end

GO
/****** Object:  StoredProcedure [dbo].[web_checkUser]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_checkUser]
	@username varchar(255),
	@password varchar(255)
	
AS
	begin
		select id, name, type
		from users
		where username = @username
		and password = @password
	end

GO
/****** Object:  StoredProcedure [dbo].[web_deleteUser]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_deleteUser]
	@id int
AS
	begin
		delete from dbo.users
		where id = @id

		select @id as 'deleted'
	end

GO
/****** Object:  StoredProcedure [dbo].[web_getCurrentState]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_getCurrentState]
	
AS
	begin
		declare @lastdate bigint
		
		--get watts consumed one hour ago
		--select top 1 @lastdate = E_T_NRG
		--from dbo.ENTRIES
		--where E_DATE between dateadd(hh,-1,getdate()) and getdate()
		--order by E_DATE asc
		
		/*select top 1 
			DEVICES.PIL_ID
			,CONVERT(varchar,ENTRIES.E_DATE,120) as 'E_DATE'
			,ENTRIES.E_CN
			,ENTRIES.E_L1 as 'Fasi1_watt'
			,ENTRIES.E_L2 as 'Fasi2_watt'
			,ENTRIES.E_L3 as 'Fasi3_watt'
			,ENTRIES.E_T_NRG - @lastdate as'watt_hours'
		from dbo.ENTRIES,dbo.DEVICES
		where ENTRIES.DEV_ID = DEVICES.DEV_ID
		order by E_DATE desc; */

		;with cte as (
		select --top 1 
			DEVICES.PIL_ID
			,E_DATE
			--,CONVERT(varchar,ENTRIES.E_DATE,120) as 'E_DATE'
			--,CAST(E_DATE AS VARCHAR)
			,ENTRIES.E_CN
			,ENTRIES.E_L1 as 'Fasi1_watt'
			,ENTRIES.E_L2 as 'Fasi2_watt'
			,ENTRIES.E_L3 as 'Fasi3_watt'
			,ENTRIES.E_T_NRG - (select top 1 E_T_NRG from dbo.ENTRIES e where e.dev_id=entries.dev_id and e.E_DATE between dateadd(hh,-1,getdate()) and getdate() order by e.E_DATE asc) as 'watt_hours'
			--,ENTRIES.E_T_NRG - lag(ENTRIES.E_T_NRG,360,0) over (partition by entries.dev_id order by E_DATE asc) as'watt_hours'
			--@lastdate as'watt_hours'
			,row_number() over (partition by devices.dev_id order by e_date desc) as rn
		from dbo.ENTRIES ,dbo.DEVICES
		where ENTRIES.DEV_ID = DEVICES.DEV_ID
		and e_date>dateadd(day,-1,getdate())
		)
		SELECT pil_id
		,CONVERT(varchar,E_DATE,120) as 'E_DATE'
		,E_CN
		,Fasi1_watt
		,Fasi2_watt
		,Fasi3_watt
		,watt_hours
		FROM cte where rn=1

	--	SELECT pil_id
	--	,CONVERT(varchar,E_DATE,120) as 'E_DATE'
	--	,E_CN
	--	,Fasi1_watt
	--	,Fasi2_watt
	--	,Fasi3_watt
	--	,watt_hours
	--	FROM (
	--	select --top 1 
	--		DEVICES.PIL_ID
	--		,E_DATE
	--		--,CONVERT(varchar,ENTRIES.E_DATE,120) as 'E_DATE'
	--		--,CAST(E_DATE AS VARCHAR)
	--		,ENTRIES.E_CN
	--		,ENTRIES.E_L1 as 'Fasi1_watt'
	--		,ENTRIES.E_L2 as 'Fasi2_watt'
	--		,ENTRIES.E_L3 as 'Fasi3_watt'
	--		,ENTRIES.E_T_NRG - (select top 1 E_T_NRG from dbo.ENTRIES e where e.dev_id=entries.dev_id and e.E_DATE between dateadd(hh,-1,getdate()) and getdate() order by e.E_DATE asc) as 'watt_hours'
	--		--,ENTRIES.E_T_NRG - lag(ENTRIES.E_T_NRG,360,0) over (partition by entries.dev_id order by E_DATE asc) as'watt_hours'
	--		--@lastdate as'watt_hours'
	--	from dbo.ENTRIES ,dbo.DEVICES
	--	where ENTRIES.DEV_ID = DEVICES.DEV_ID
	----	AND ENTRIES.DEV_ID=7248
	--	order by E_DATE desc ) T
	
	end

GO
/****** Object:  StoredProcedure [dbo].[web_getPillarHistory]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_getPillarHistory]
	@pil_id int,
	@dateFrom datetime,
	@dateTo datetime
	
AS
	begin

		SELECT 
		CONVERT(varchar,E_DATE,120) as 'E_DATE'
		,E_CN
		,Fasi1_watt
		,Fasi2_watt
		,Fasi3_watt
		,watt_hours
		FROM
		(select
			E_DATE
			--CONVERT(varchar,E_DATE,120) as 'E_DATE'
			,E_CN
			,E_L1 as 'Fasi1_watt'
			,E_L2 as 'Fasi2_watt'
			,E_L3 as 'Fasi3_watt'
			,E_T_NRG as'watt_hours'
		from dbo.ENTRIES,dbo.DEVICES
		where ENTRIES.DEV_ID = DEVICES.DEV_ID
		and DEVICES.PIL_ID = @pil_id
		and ENTRIES.E_DATE between @dateFrom and @dateTo
		) T
		order by E_DATE asc

	end

GO
/****** Object:  StoredProcedure [dbo].[web_getPillarsList]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_getPillarsList]
	
AS

BEGIN
	SELECT	pil.PIL_ID,
			pil.PIL_LAT,
			pil.PIL_LNG,
			pil.PIL_DESCR,
			(SELECT COUNT(pol.POL_ID) FROM dbo.POLE pol WHERE pol.PIL_ID = pil.PIL_ID) as DEV_LAMP_COUNT,
			dv.DEV_IP,
			dv.DEV_LAMP_WATT,
			(SELECT COALESCE(SUM(plg.POLL_WATT),0) FROM dbo.POLE_LIGHT plg JOIN dbo.POLE pol ON pol.POL_ID = plg.POL_ID WHERE pol.PIL_ID = pil.PIL_ID) as TOTAL_WATT
	FROM dbo.PILLAR pil
	JOIN dbo.DEVICES dv ON dv.PIL_ID = pil.PIL_ID
END
GO
/****** Object:  StoredProcedure [dbo].[web_getPoleLights]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_getPoleLights](
	@pol_id int
)
	
AS
	begin

		select POLE_LIGHT.POLL_ID
			,POLE_LIGHT.POLL_WATT
			,LIGHT_TYPE.LIGT_ID
		from dbo.POLE_LIGHT,dbo.LIGHT_TYPE
		where POLE_LIGHT.LIGT_ID = LIGHT_TYPE.LIGT_ID
		and POLE_LIGHT.POL_ID = @pol_id

	end
GO
/****** Object:  StoredProcedure [dbo].[web_getPolesForPilar]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_getPolesForPilar](
	@pil_id int
)
	
AS
begin
	select 	POLE.POL_ID,
			POLE.POLT_ID,
			POLE.POL_LAT,
			POLE.POL_LNG,
			POLE.POL_CODE,
			POLE.POL_HEIGHT,
			POLE.POL_DESCR,
			POLE_TYPE.POLT_ID
	from dbo.POLE,dbo.POLE_TYPE
	where POLE.PIL_ID = @pil_id
	and POLE.POLT_ID = POLE_TYPE.POLT_ID
end

GO
/****** Object:  StoredProcedure [dbo].[web_getUsers]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_getUsers]
	
AS
	begin

		select *
		from users

	end

GO
/****** Object:  StoredProcedure [dbo].[web_insertUser]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_insertUser](
	@username varchar(255),
	@password varchar(255),
	@type int,
	@email varchar(255),
	@phone varchar(255),
	@name varchar(255)
)
	
AS
	begin

		insert into dbo.users (
			username,
			password,
			type,
			email,
			phone,
			name,
			createdAt
		)
		values (
			@username,
			@password,
			@type,
			@email,
			@phone,
			@name,
			getdate()
		)

		select @@identity as 'inserted'

	end
GO
/****** Object:  StoredProcedure [dbo].[web_triggerPIllarEvent]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_triggerPIllarEvent](
	@pillarID int,
	@dateActive datetime,
	@stateType int,
	@status int
)
	
AS
	begin


		insert into dbo.PILLAR_EVENTS
			(PIL_ID,PILE_DATE,PILE_TYPE,PILE_STATUS)
		values
			(@pillarID,@dateActive,@stateType,@status)
		
		select @@identity as 'insertedID'

	end

GO
/****** Object:  StoredProcedure [dbo].[web_updatePolePosition]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_updatePolePosition]
	@id int,
	@lat varchar(255),
	@lng varchar(255)
AS
	begin

		update dbo.POLE
		set
			POL_LAT = @lat,
			POL_LNG = @lng
		where POL_ID = @id

	end

GO
/****** Object:  StoredProcedure [dbo].[web_updateUser]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[web_updateUser](
	@id int,
	@username varchar(255),
	@password varchar(255),
	@type int,
	@email varchar(255),
	@phone varchar(255),
	@name varchar(255)
)
	
AS
	begin

		update dbo.users
		set
			username = @username,
			password = @password,
			type = @type,
			email = @email,
			phone = @phone,
			name = @name,
			updatedAt = getdate()
		where id = @id

		select @id as 'updated'

	end
GO
/****** Object:  Table [dbo].[DEVICES]    Script Date: 14/10/2020 4:25:13 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DEVICES](
	[DEV_ID] [int] NOT NULL,
	[DEV_DESCR] [varchar](500) NULL,
	[DEV_LAT] [float] NULL,
	[DEV_LNG] [float] NULL,
	[DEV_LAMP_COUNT] [smallint] NULL,
	[DEV_LAMP_WATT] [smallint] NULL,
	[DEV_TOTAL_WATT] [smallint] NULL,
	[DEV_IP] [varchar](50) NULL,
	[PIL_ID] [int] NULL,
 CONSTRAINT [PK_DEVICES] PRIMARY KEY CLUSTERED 
(
	[DEV_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ENTRIES]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ENTRIES](
	[E_ID] [int] IDENTITY(50000,1) NOT NULL,
	[E_DATE] [datetime] NULL,
	[DEV_ID] [int] NULL,
	[E_CN] [int] NULL,
	[E_L1] [int] NULL,
	[E_L2] [int] NULL,
	[E_L3] [int] NULL,
	[E_NRG1] [int] NULL,
	[E_NRG2] [int] NULL,
	[E_T_NRG]  AS ([E_NRG2]*(4294967296.)+[E_NRG1]),
 CONSTRAINT [PK_ENTRIES] PRIMARY KEY CLUSTERED 
(
	[E_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LIGHT_TYPE]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LIGHT_TYPE](
	[LIGT_ID] [int] IDENTITY(1,1) NOT NULL,
	[LIGT_DESCR] [varchar](200) NULL,
 CONSTRAINT [PK_LIGHT_TYPE] PRIMARY KEY CLUSTERED 
(
	[LIGT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[logs]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[logs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[userid] [int] NOT NULL,
	[description] [varchar](max) NOT NULL,
	[createdAt] [datetime2](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pbcatcol]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pbcatcol](
	[pbc_tnam] [varchar](128) NOT NULL,
	[pbc_tid] [int] NULL,
	[pbc_ownr] [varchar](128) NOT NULL,
	[pbc_cnam] [varchar](128) NOT NULL,
	[pbc_cid] [smallint] NULL,
	[pbc_labl] [varchar](254) NULL,
	[pbc_lpos] [smallint] NULL,
	[pbc_hdr] [varchar](254) NULL,
	[pbc_hpos] [smallint] NULL,
	[pbc_jtfy] [smallint] NULL,
	[pbc_mask] [varchar](31) NULL,
	[pbc_case] [smallint] NULL,
	[pbc_hght] [smallint] NULL,
	[pbc_wdth] [smallint] NULL,
	[pbc_ptrn] [varchar](31) NULL,
	[pbc_bmap] [varchar](1) NULL,
	[pbc_init] [varchar](254) NULL,
	[pbc_cmnt] [varchar](254) NULL,
	[pbc_edit] [varchar](31) NULL,
	[pbc_tag] [varchar](254) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pbcatedt]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pbcatedt](
	[pbe_name] [varchar](30) NOT NULL,
	[pbe_edit] [varchar](254) NULL,
	[pbe_type] [smallint] NULL,
	[pbe_cntr] [int] NULL,
	[pbe_seqn] [smallint] NOT NULL,
	[pbe_flag] [int] NULL,
	[pbe_work] [varchar](32) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pbcatfmt]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pbcatfmt](
	[pbf_name] [varchar](30) NOT NULL,
	[pbf_frmt] [varchar](254) NULL,
	[pbf_type] [smallint] NULL,
	[pbf_cntr] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pbcattbl]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pbcattbl](
	[pbt_tnam] [varchar](128) NOT NULL,
	[pbt_tid] [int] NULL,
	[pbt_ownr] [varchar](128) NOT NULL,
	[pbd_fhgt] [smallint] NULL,
	[pbd_fwgt] [smallint] NULL,
	[pbd_fitl] [varchar](1) NULL,
	[pbd_funl] [varchar](1) NULL,
	[pbd_fchr] [smallint] NULL,
	[pbd_fptc] [smallint] NULL,
	[pbd_ffce] [varchar](18) NULL,
	[pbh_fhgt] [smallint] NULL,
	[pbh_fwgt] [smallint] NULL,
	[pbh_fitl] [varchar](1) NULL,
	[pbh_funl] [varchar](1) NULL,
	[pbh_fchr] [smallint] NULL,
	[pbh_fptc] [smallint] NULL,
	[pbh_ffce] [varchar](18) NULL,
	[pbl_fhgt] [smallint] NULL,
	[pbl_fwgt] [smallint] NULL,
	[pbl_fitl] [varchar](1) NULL,
	[pbl_funl] [varchar](1) NULL,
	[pbl_fchr] [smallint] NULL,
	[pbl_fptc] [smallint] NULL,
	[pbl_ffce] [varchar](18) NULL,
	[pbt_cmnt] [varchar](254) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[pbcatvld]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[pbcatvld](
	[pbv_name] [varchar](30) NOT NULL,
	[pbv_vald] [varchar](254) NULL,
	[pbv_type] [smallint] NULL,
	[pbv_cntr] [int] NULL,
	[pbv_msg] [varchar](254) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PILAR_ALERTS]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PILAR_ALERTS](
	[PILA_ID] [int] IDENTITY(1,1) NOT NULL,
	[PIL_ID] [int] NULL,
	[PILA_ENABLED] [tinyint] NULL,
	[PILA_DATE_FROM] [date] NULL,
	[PILA_DATE_TO] [date] NULL,
	[PILA_TIME_FROM] [time](7) NULL,
	[PILA_TIME_TO] [time](7) NULL,
	[PILA_CONDITION] [tinyint] NULL,
	[PILA_VALUE] [int] NULL,
	[PILA_SMS_PHONE] [varchar](20) NULL,
	[PILA_EMAIL] [varchar](100) NULL,
	[PILA_IS_ACTIVE] [tinyint] NULL,
 CONSTRAINT [PK_PILAR_ALERTS] PRIMARY KEY CLUSTERED 
(
	[PILA_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PILLAR]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PILLAR](
	[PIL_ID] [int] IDENTITY(1,1) NOT NULL,
	[PIL_LAT] [float] NULL,
	[PIL_LNG] [float] NULL,
	[PIL_DESCR] [varchar](500) NULL,
 CONSTRAINT [PK_PILAR] PRIMARY KEY CLUSTERED 
(
	[PIL_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PILLAR_EVENTS]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PILLAR_EVENTS](
	[PILE_ID] [int] IDENTITY(1,1) NOT NULL,
	[PIL_ID] [int] NULL,
	[PILE_DATE] [datetime] NULL,
	[PILE_TYPE] [tinyint] NULL,
	[PILE_STATUS] [tinyint] NULL,
	[PILE_INSERTED] [datetime] NULL,
	[PILE_COMMITTED] [datetime] NULL,
	[PILA_ID] [int] NULL,
 CONSTRAINT [PK_PILAR_EVENTS] PRIMARY KEY CLUSTERED 
(
	[PILE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[POLE]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[POLE](
	[POL_ID] [int] IDENTITY(1,1) NOT NULL,
	[PIL_ID] [int] NULL,
	[POLT_ID] [int] NULL,
	[POL_LAT] [float] NULL,
	[POL_LNG] [float] NULL,
	[POL_CODE] [varchar](20) NULL,
	[POL_HEIGHT] [smallint] NULL,
	[POL_DESCR] [varchar](500) NULL,
 CONSTRAINT [PK_POLE] PRIMARY KEY CLUSTERED 
(
	[POL_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[POLE_DETAILS_STATUS]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[POLE_DETAILS_STATUS](
	[POLDS_ID] [int] NOT NULL,
	[POLDS_DESCR] [varchar](100) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[POLE_IMAGES]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[POLE_IMAGES](
	[POLI_ID] [int] IDENTITY(1,1) NOT NULL,
	[POL_ID] [int] NULL,
	[POLI_DATE] [datetime] NULL,
	[POLI_IMAGE] [varbinary](max) NULL,
	[POLI_DESCR] [varchar](500) NULL,
 CONSTRAINT [PK_POLE_IMAGES] PRIMARY KEY CLUSTERED 
(
	[POLI_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[POLE_ISSUES]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[POLE_ISSUES](
	[POLI_ID] [int] IDENTITY(1,1) NOT NULL,
	[POL_ID] [int] NOT NULL,
	[POLI_COMMENTS] [varchar](500) NOT NULL,
	[POLI_STATUS] [int] NOT NULL,
	[userid] [int] NOT NULL,
	[POLI_DATE] [datetime2](7) NOT NULL,
	[createdAt] [datetime2](7) NOT NULL,
	[updatedAt] [datetime2](7) NULL,
 CONSTRAINT [POLE_ISSUES_PK] PRIMARY KEY CLUSTERED 
(
	[POLI_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[POLE_LIGHT]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[POLE_LIGHT](
	[POLL_ID] [int] IDENTITY(1,1) NOT NULL,
	[POL_ID] [int] NULL,
	[LIGT_ID] [int] NULL,
	[POLL_WATT] [smallint] NULL,
 CONSTRAINT [PK_POLE_LIGHT] PRIMARY KEY CLUSTERED 
(
	[POLL_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[POLE_LIGHT_DETAILS_STATUS]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[POLE_LIGHT_DETAILS_STATUS](
	[POLLDS_ID] [int] NULL,
	[POLLDS_DESCR] [nchar](100) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[POLE_STATUS]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[POLE_STATUS](
	[POLS_ID] [int] IDENTITY(1,1) NOT NULL,
	[POL_ID] [int] NULL,
	[POLS_DATE] [datetime] NULL,
	[POLS_DESCR] [varchar](500) NULL,
 CONSTRAINT [PK_POLE_STATUS] PRIMARY KEY CLUSTERED 
(
	[POLS_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[POLE_TYPE]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[POLE_TYPE](
	[POLT_ID] [int] IDENTITY(1,1) NOT NULL,
	[POLT_DESCR] [varchar](200) NULL,
 CONSTRAINT [PK_POLE_TYPE] PRIMARY KEY CLUSTERED 
(
	[POLT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[users]    Script Date: 14/10/2020 4:25:17 μμ ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[users](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[username] [varchar](255) NOT NULL,
	[password] [varchar](255) NOT NULL,
	[type] [int] NOT NULL,
	[email] [varchar](255) NULL,
	[phone] [varchar](255) NULL,
	[name] [varchar](255) NOT NULL,
	[createdAt] [datetime2](0) NULL,
	[updatedAt] [datetime2](0) NULL,
 CONSTRAINT [users_PK] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[logs] ADD  CONSTRAINT [DF_logs_createdAt]  DEFAULT (getdate()) FOR [createdAt]
GO
ALTER TABLE [dbo].[PILAR_ALERTS] ADD  CONSTRAINT [DF_PILAR_ALERTS_PILA_ENABLED]  DEFAULT ((0)) FOR [PILA_ENABLED]
GO
ALTER TABLE [dbo].[PILAR_ALERTS] ADD  CONSTRAINT [DF_PILAR_ALERTS_PILA_CONDITION]  DEFAULT ((0)) FOR [PILA_CONDITION]
GO
ALTER TABLE [dbo].[PILAR_ALERTS] ADD  CONSTRAINT [DF_PILAR_ALERTS_PILA_IS_ACTIVE]  DEFAULT ((0)) FOR [PILA_IS_ACTIVE]
GO
ALTER TABLE [dbo].[PILLAR_EVENTS] ADD  CONSTRAINT [DF_PILAR_EVENTS_PILE_TYPE]  DEFAULT ((1)) FOR [PILE_TYPE]
GO
ALTER TABLE [dbo].[PILLAR_EVENTS] ADD  CONSTRAINT [DF_PILAR_EVENTS_PILE_STATUS]  DEFAULT ((0)) FOR [PILE_STATUS]
GO
ALTER TABLE [dbo].[PILLAR_EVENTS] ADD  CONSTRAINT [DF_PILAR_EVENTS_PILE_INSERTED]  DEFAULT (getdate()) FOR [PILE_INSERTED]
GO
ALTER TABLE [dbo].[POLE_ISSUES] ADD  CONSTRAINT [DF__POLE_ISSU__creat__160F4887]  DEFAULT (getdate()) FOR [createdAt]
GO
ALTER TABLE [dbo].[DEVICES]  WITH CHECK ADD  CONSTRAINT [FK_DEVICES_PILAR] FOREIGN KEY([PIL_ID])
REFERENCES [dbo].[PILLAR] ([PIL_ID])
GO
ALTER TABLE [dbo].[DEVICES] CHECK CONSTRAINT [FK_DEVICES_PILAR]
GO
ALTER TABLE [dbo].[logs]  WITH CHECK ADD  CONSTRAINT [logs_users_FK] FOREIGN KEY([userid])
REFERENCES [dbo].[users] ([id])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[logs] CHECK CONSTRAINT [logs_users_FK]
GO
ALTER TABLE [dbo].[PILAR_ALERTS]  WITH CHECK ADD  CONSTRAINT [FK_PILAR_ALERTS_PILLAR] FOREIGN KEY([PIL_ID])
REFERENCES [dbo].[PILLAR] ([PIL_ID])
GO
ALTER TABLE [dbo].[PILAR_ALERTS] CHECK CONSTRAINT [FK_PILAR_ALERTS_PILLAR]
GO
ALTER TABLE [dbo].[PILLAR_EVENTS]  WITH CHECK ADD  CONSTRAINT [FK_PILLAR_EVENTS_PILAR_ALERTS] FOREIGN KEY([PILA_ID])
REFERENCES [dbo].[PILAR_ALERTS] ([PILA_ID])
ON DELETE SET NULL
GO
ALTER TABLE [dbo].[PILLAR_EVENTS] CHECK CONSTRAINT [FK_PILLAR_EVENTS_PILAR_ALERTS]
GO
ALTER TABLE [dbo].[PILLAR_EVENTS]  WITH CHECK ADD  CONSTRAINT [FK_PILLAR_EVENTS_PILLAR] FOREIGN KEY([PIL_ID])
REFERENCES [dbo].[PILLAR] ([PIL_ID])
GO
ALTER TABLE [dbo].[PILLAR_EVENTS] CHECK CONSTRAINT [FK_PILLAR_EVENTS_PILLAR]
GO
ALTER TABLE [dbo].[POLE]  WITH CHECK ADD  CONSTRAINT [FK_POLE_PILLAR] FOREIGN KEY([PIL_ID])
REFERENCES [dbo].[PILLAR] ([PIL_ID])
GO
ALTER TABLE [dbo].[POLE] CHECK CONSTRAINT [FK_POLE_PILLAR]
GO
ALTER TABLE [dbo].[POLE]  WITH CHECK ADD  CONSTRAINT [FK_POLE_POLE_TYPE] FOREIGN KEY([POLT_ID])
REFERENCES [dbo].[POLE_TYPE] ([POLT_ID])
GO
ALTER TABLE [dbo].[POLE] CHECK CONSTRAINT [FK_POLE_POLE_TYPE]
GO
ALTER TABLE [dbo].[POLE_IMAGES]  WITH CHECK ADD  CONSTRAINT [FK_POLE_IMAGES_POLE] FOREIGN KEY([POL_ID])
REFERENCES [dbo].[POLE] ([POL_ID])
GO
ALTER TABLE [dbo].[POLE_IMAGES] CHECK CONSTRAINT [FK_POLE_IMAGES_POLE]
GO
ALTER TABLE [dbo].[POLE_ISSUES]  WITH CHECK ADD  CONSTRAINT [POLE_ISSUES_POLE_FK] FOREIGN KEY([POL_ID])
REFERENCES [dbo].[POLE] ([POL_ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[POLE_ISSUES] CHECK CONSTRAINT [POLE_ISSUES_POLE_FK]
GO
ALTER TABLE [dbo].[POLE_LIGHT]  WITH CHECK ADD  CONSTRAINT [FK_POLE_LIGHT_LIGHT_TYPE] FOREIGN KEY([LIGT_ID])
REFERENCES [dbo].[LIGHT_TYPE] ([LIGT_ID])
GO
ALTER TABLE [dbo].[POLE_LIGHT] CHECK CONSTRAINT [FK_POLE_LIGHT_LIGHT_TYPE]
GO
ALTER TABLE [dbo].[POLE_LIGHT]  WITH CHECK ADD  CONSTRAINT [FK_POLE_LIGHT_POLE] FOREIGN KEY([POL_ID])
REFERENCES [dbo].[POLE] ([POL_ID])
GO
ALTER TABLE [dbo].[POLE_LIGHT] CHECK CONSTRAINT [FK_POLE_LIGHT_POLE]
GO
ALTER TABLE [dbo].[POLE_STATUS]  WITH CHECK ADD  CONSTRAINT [FK_POLE_STATUS_POLE] FOREIGN KEY([POL_ID])
REFERENCES [dbo].[POLE] ([POL_ID])
GO
ALTER TABLE [dbo].[POLE_STATUS] CHECK CONSTRAINT [FK_POLE_STATUS_POLE]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0: Greater Than ; 1:Less than  ; 2:Greater or equal to ; 3:Less or equal to' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'PILAR_ALERTS', @level2type=N'COLUMN',@level2name=N'PILA_CONDITION'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'1: Switch ON/OFF 2: Detected Power ON/OFF 3: Pilar Alert' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'PILLAR_EVENTS', @level2type=N'COLUMN',@level2name=N'PILE_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'1: Switch On ; 2: Switch Off ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'PILLAR_EVENTS', @level2type=N'COLUMN',@level2name=N'PILE_STATUS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0-admin, 1-powerUser, 2-user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users', @level2type=N'COLUMN',@level2name=N'type'
GO
