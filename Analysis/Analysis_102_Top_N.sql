/*
Generate analysis data for reports
*/

DECLARE 
@ACTION				INT = 0
						|128			--> Extract Techniques and Mitigations data, with @LAST_2YRS

						--|1			--> SHOW: Killchain distributions (Techniques)
						--|2			--> SHOW: Killchain distributions (Mitigations)
						--|4			--> SHOW: Mitigations  
						--|8			--> SHOW: How to DETECT Techniques; use with [@Top_DataSources]. Which Data Sources to target.
						--|16			--> EXPERIMENT: Find the most effective CoA combination
						|64			--> SHOW: All techniques
,
@Top_Techniques		INT = 10,			--> Select the top [N] most used Techniques
@Top_DataSources	INT = 1,			--> Filter where TechCount >= @Top_DataSources
@LAST_2YRS			BIT = 0


EXEC dbo.[usp_Mitre_Analysis_102_Top_N] 
	@ACTION				= @ACTION,
	@Top_Techniques		= @Top_Techniques,
	@Top_DataSources	= @Top_DataSources,
	@LAST_2YRS			= @LAST_2YRS