/*
Create database and database objects.
*/

USE [master]
GO

--:setvar dbName Mitre_t1


IF NOT EXISTS ( SELECT 1 FROM sys.databases WHERE name = '$(dbName)' )
BEGIN
	CREATE DATABASE [$(dbName)] COLLATE Latin1_General_CI_AS

	ALTER DATABASE [$(dbName)] SET COMPATIBILITY_LEVEL = 140

	IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
	BEGIN
		EXEC [$(dbName)].[dbo].sp_fulltext_database @action = 'enable'
	END

	ALTER DATABASE [$(dbName)] SET ANSI_NULL_DEFAULT OFF 

	ALTER DATABASE [$(dbName)] SET ANSI_NULLS OFF 

	ALTER DATABASE [$(dbName)] SET ANSI_PADDING OFF 

	ALTER DATABASE [$(dbName)] SET ANSI_WARNINGS OFF 

	ALTER DATABASE [$(dbName)] SET ARITHABORT OFF 

	ALTER DATABASE [$(dbName)] SET AUTO_CLOSE OFF 

	ALTER DATABASE [$(dbName)] SET AUTO_SHRINK OFF 

	ALTER DATABASE [$(dbName)] SET AUTO_UPDATE_STATISTICS ON 

	ALTER DATABASE [$(dbName)] SET CURSOR_CLOSE_ON_COMMIT OFF 

	ALTER DATABASE [$(dbName)] SET CURSOR_DEFAULT  GLOBAL 

	ALTER DATABASE [$(dbName)] SET CONCAT_NULL_YIELDS_NULL OFF 

	ALTER DATABASE [$(dbName)] SET NUMERIC_ROUNDABORT OFF 

	ALTER DATABASE [$(dbName)] SET QUOTED_IDENTIFIER OFF 

	ALTER DATABASE [$(dbName)] SET RECURSIVE_TRIGGERS OFF 

	ALTER DATABASE [$(dbName)] SET  DISABLE_BROKER 

	ALTER DATABASE [$(dbName)] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 

	ALTER DATABASE [$(dbName)] SET DATE_CORRELATION_OPTIMIZATION OFF 

	ALTER DATABASE [$(dbName)] SET TRUSTWORTHY OFF 

	ALTER DATABASE [$(dbName)] SET ALLOW_SNAPSHOT_ISOLATION OFF 

	ALTER DATABASE [$(dbName)] SET PARAMETERIZATION SIMPLE 

	ALTER DATABASE [$(dbName)] SET READ_COMMITTED_SNAPSHOT OFF 

	ALTER DATABASE [$(dbName)] SET HONOR_BROKER_PRIORITY OFF 

	ALTER DATABASE [$(dbName)] SET RECOVERY SIMPLE 

	ALTER DATABASE [$(dbName)] SET  MULTI_USER 

	ALTER DATABASE [$(dbName)] SET PAGE_VERIFY CHECKSUM  

	ALTER DATABASE [$(dbName)] SET DB_CHAINING OFF 

	ALTER DATABASE [$(dbName)] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 

	ALTER DATABASE [$(dbName)] SET TARGET_RECOVERY_TIME = 60 SECONDS 

	ALTER DATABASE [$(dbName)] SET DELAYED_DURABILITY = DISABLED 

	ALTER DATABASE [$(dbName)] SET QUERY_STORE = OFF

END
GO
USE [$(dbName)]

IF 1=1
BEGIN
	
	ALTER DATABASE SCOPED CONFIGURATION SET IDENTITY_CACHE = ON;

	ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;

	ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = PRIMARY;

	ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;

	ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;

	ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;

	ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = PRIMARY;

	ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;

	ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = PRIMARY;


END
--> ####################################################################################
--> ####################################################################################
GO
USE [$(dbName)]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--> ####################################################################################
--> ####################################################################################


IF TYPE_ID(N'CoreObject') IS NULL
BEGIN
	CREATE TYPE [dbo].CoreObject AS TABLE(
		[PK] [int] NULL,
		[ObjPk] [int] NULL,
		[ObjPkMax] [int] NULL,
		[RootPk] [varchar](100) NULL,
		[TypeId] [int] NULL,
		[Yr] [int] NULL,
		[Name] [varchar](100) NULL,
		[Description] [varchar](max) NULL,
		[IsRevoked] [bit] NULL,
		[IsDeprecated] [bit] NULL
	)
END
GO


IF TYPE_ID(N'ObjectCountPerYear') IS NULL
BEGIN
	CREATE TYPE [dbo].ObjectCountPerYear AS TABLE(
		[Pk] [int] NULL,
		[ObjPkMax] [int] NULL,
		[RootPk] [varchar](100) NULL,
		[ObjTypeId] [int] NULL,
		[2018] [int] NULL,
		[2019] [int] NULL,
		[2020] [int] NULL,
		[2021] [int] NULL
	)
END
GO


IF TYPE_ID(N'ObjectUsePerYear') IS NULL
BEGIN
	CREATE TYPE [dbo].ObjectUsePerYear AS TABLE(
		[Pk] [int] NULL,
		[ObjPkMax] [int] NULL,
		[RootPk] [varchar](100) NULL,
		[ObjTypeId] [int] NULL,
		[2018] [char](1) NULL,
		[2019] [char](1) NULL,
		[2020] [char](1) NULL,
		[2021] [char](1) NULL
	)
END
--> ####################################################################################
--> ####################################################################################

IF OBJECT_ID('dbo.fnGetObjectList') IS NOT NULL
BEGIN
	DROP FUNCTION [dbo].fnGetObjectList 
END
GO
	-- =============================================
	-- Author:		Marko Kennedy
	-- Create date: July 2021
	-- Description:	Return the list of object types, containing core details
	-- =============================================
	CREATE FUNCTION [dbo].fnGetObjectList 
	(
		@TypeId	INT 
	)
	RETURNS 
	@vals TABLE 
	(
		PK				INT IDENTITY(1,1),
		ObjPk			INT,
		ObjPkMax		INT,
		RootPk			VARCHAR(100),
		TypeId			INT,
		Yr				INT,
		[Name]			VARCHAR(100),
		[Description]	VARCHAR(MAX),
		IsRevoked		BIT,
		IsDeprecated	BIT
	)
	AS
	BEGIN

		INSERT @vals (ObjPk, ObjPkMax, RootPk, TypeId, Yr, [Name], [Description], IsRevoked, IsDeprecated)
		SELECT         
			mo.objId AS ObjPk, S.ObjPkMax, mo.objRootObjPk AS RootPk, @TypeId, mo.objYear AS Yr, mo.objName AS Name, 
			mo.objDescription AS Description, mo.objRevoked AS IsRevoked, mo.objDeprecated AS IsDepricated
		FROM dbo.mkRootObject AS ro
		INNER JOIN (
				SELECT        
					mo.objRootObjPk AS RootPk, MAX(mo.objId) ObjPkMax
				FROM dbo.mkObject AS mo 
				INNER JOIN dbo.mkRootObject AS ro ON ro.roPk = mo.objRootObjPk AND ro.roTypeId = @TypeId
				GROUP BY mo.objRootObjPk
		) S ON S.RootPk = ro.roPk
		INNER JOIN dbo.mkObject AS mo ON mo.objRootObjPk = S.RootPk
		WHERE (@TypeId <> 10 OR (@TypeId = 10 AND mo.objYear = 2021));

		RETURN 
	END
GO



IF OBJECT_ID('dbo.fnGetObjectUsePerYear') IS NOT NULL
BEGIN
	DROP FUNCTION [dbo].fnGetObjectUsePerYear 
END
GO
	-- =============================================
	-- Author:		Marko Kennedy
	-- Create date: July 2021
	-- Description:	Return a list of object use per year, with (Y|N) for each year [2018 -2021]
	-- =============================================
	CREATE FUNCTION [dbo].fnGetObjectUsePerYear 
	(
		@TypeId	INT 
	)
	RETURNS 
	@vals TABLE 
	(
		PK			INT IDENTITY(1,1),
		ObjPkMax	INT,
		RootPk		VARCHAR(100),
		ObjTypeId	INT,
		[2018]		CHAR(1), 
		[2019]		CHAR(1), 
		[2020]		CHAR(1), 
		[2021]		CHAR(1)
	)
	AS
	BEGIN

		DECLARE @xx TABLE (pk INT)

		INSERT @vals (ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
		SELECT 
			PT.ObjPkMax, PT.RootPk, @TypeId, 
			CASE WHEN [2018] IS NULL THEN '' ELSE 'Y' END [2018],
			CASE WHEN [2019] IS NULL THEN '' ELSE 'Y' END [2019],
			CASE WHEN [2020] IS NULL THEN '' ELSE 'Y' END [2020],
			CASE WHEN [2021] IS NULL THEN '' ELSE 'Y' END [2021]
		FROM (
			SELECT ObjPkMax, RootPk, Yr
			FROM dbo.fnGetObjectList (@TypeId)
		) Src
		PIVOT (
			MAX(Yr) FOR Yr IN ([2018],[2019],[2020],[2021])
		) PT;

		RETURN 
	END
GO
--> ####################################################################################
--> ####################################################################################


IF OBJECT_ID(N'dbo.mkKillchainPhases') IS NULL
BEGIN
	CREATE TABLE [dbo].mkKillchainPhases(
		[kcPk] [tinyint] IDENTITY(1,1) NOT NULL,
		[kcVal] [varchar](50) NOT NULL,
		[kcName] [varchar](50) NOT NULL,
		[kcOrder] [tinyint] NOT NULL,
		[kcMask] [int] NOT NULL,
	 CONSTRAINT [PK_mkKillchainPhases_1] PRIMARY KEY NONCLUSTERED 
	(
		[kcPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]		
	
	ALTER TABLE [dbo].mkKillchainPhases ADD  CONSTRAINT [DF_mkKillchainPhases_kcMask]  DEFAULT ((0)) FOR [kcMask]
	
	INSERT INTO [dbo].mkKillchainPhases ([kcVal],[kcName] ,[kcOrder], [kcMask])
		VALUES
		('reconnaissance',	'Reconnaissance',	1, 1),
		('resource-development',	'Resource Development',	2, 2),
		('initial-access',	'Initial Access',	3, 4),
		('execution',	'Execution',	4, 8),
		('persistence',	'Persistence',	5, 16),
		('privilege-escalation',	'Privilege Escalation',	6, 32),
		('defense-evasion',	'Defense Evasion',	7, 64),
		('credential-access',	'Credential Access',	8, 128),
		('discovery',	'Discovery',	9, 256),
		('lateral-movement',	'Lateral Movement',	10, 512),
		('collection',	'Collection',	11, 1024),
		('command-and-control',	'Command and Control',	12, 2048),
		('exfiltration',	'Exfiltration',	13, 4096),
		('impact',	'Impact',	14, 8192);
END
GO


IF OBJECT_ID(N'dbo.mkObject') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObject(
		[objId] [int] IDENTITY(1,1) NOT NULL,
		[objRootObjPk] [varchar](100) NOT NULL,
		[objYear] [int] NOT NULL,
		[objJson] [nvarchar](max) NOT NULL,
		[objOwnersObjId] [varchar](100) NULL,
		[objSpec] [varchar](10) NULL,
		[objName] [varchar](100) NULL,
		[objDescription] [nvarchar](max) NULL,
		[objCreatedDate] [date] NULL,
		[objCreatedById] [varchar](100) NULL,
		[objModifiedDate] [date] NULL,
		[objRevoked] [bit] NOT NULL,
		[objDeprecated] [bit] NOT NULL,
		[objNameSort] [varchar](200) NULL,
	 CONSTRAINT [PK_mkObject] PRIMARY KEY CLUSTERED 
	(
		[objId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

	ALTER TABLE [dbo].mkObject ADD  CONSTRAINT [DF_mkObject_objRevoked]  DEFAULT ((0)) FOR [objRevoked]
	ALTER TABLE [dbo].mkObject ADD  CONSTRAINT [DF_mkObject_objDeprecated]  DEFAULT ((0)) FOR [objDeprecated]
END
GO


IF OBJECT_ID(N'dbo.mkRootObject') IS NULL
BEGIN
	CREATE TABLE [dbo].mkRootObject(
		[roPk] [varchar](100) NOT NULL,
		[roSectionId] [int] NOT NULL,
		[roTypeId] [int] NOT NULL,
		[roInserted] [datetime] NOT NULL,
		[roMaxObjPk] [int] NULL,
	 CONSTRAINT [PK_RootObject] PRIMARY KEY CLUSTERED 
	(
		[roPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].mkRootObject ADD  CONSTRAINT [DF_mkRootObject_roInserted]  DEFAULT (getdate()) FOR [roInserted]
END
GO


IF OBJECT_ID(N'dbo.mkType') IS NULL
BEGIN
	CREATE TABLE [dbo].mkType(
		[tId] [int] IDENTITY(1,1) NOT NULL,
		[tName] [varchar](50) NOT NULL,
		[LocalName] [varchar](50) NULL,
	 CONSTRAINT [PK_mkType] PRIMARY KEY CLUSTERED 
	(
		[tId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	SET IDENTITY_INSERT [dbo].mkType ON
	INSERT INTO [dbo].mkType 
	(tId,	tName,					LocalName)
	VALUES
	(1,		'attack-pattern',		'Technique'),
	(2,		'course-of-action',		'Mitigation'),
	(3,		'identity',				NULL),
	(4,		'intrusion-set',		'Group'),
	(5,		'malware',				'Malware'),
	(6,		'marking-definition',	NULL),
	(7,		'relationship',			'Relationship'),
	(8,		'tool',					'Tool'),
	(9,		'x-mitre-matrix',		NULL),
	(10,	'x-mitre-tactic',		'Tactic (KC)'),
	(11,	'Sub-Technique',		'Subtechnique');		
	SET IDENTITY_INSERT [dbo].mkType OFF
END
GO


IF OBJECT_ID(N'dbo.vwKillChainPhases') IS NOT NULL
BEGIN
	DROP VIEW [dbo].vwKillChainPhases
END
GO
	CREATE VIEW [dbo].vwKillChainPhases
	AS
	SELECT        TOP (100) PERCENT kp.kcPk, kp.kcName, kp.kcOrder, S.Details, S.ObjPk
	FROM            dbo.mkKillchainPhases AS kp LEFT OUTER JOIN
								 (SELECT        mo.objId AS ObjPk, mo.objName, mo.objDescription AS Details
								   FROM            dbo.mkObject AS mo INNER JOIN
															 dbo.mkRootObject AS ro ON ro.roPk = mo.objRootObjPk AND ro.roTypeId = 10 INNER JOIN
															 dbo.mkType AS mt ON mt.tId = ro.roTypeId
								   WHERE        (mo.objYear = 2021)) AS S ON S.objName = kp.kcName

GO


IF OBJECT_ID(N'dbo.aAdmin') IS NULL
BEGIN
	CREATE TABLE [dbo].aAdmin(
		[ProcsLastRunDate] [smalldatetime] NOT NULL
	) ON [PRIMARY]

	ALTER TABLE [dbo].aAdmin ADD  CONSTRAINT [DF_Table_1_LastRun]  DEFAULT ('1 Jan 1970') FOR [ProcsLastRunDate]
END
GO


IF OBJECT_ID(N'dbo.aAudit') IS NULL
BEGIN
	CREATE TABLE [dbo].aAudit(
		[auProcId] [int] NOT NULL,
		[auTimeStamp] [datetime] NOT NULL,
	 CONSTRAINT [PK_aAudit] PRIMARY KEY CLUSTERED 
	(
		[auProcId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.aError') IS NULL
BEGIN
	CREATE TABLE [dbo].aError(
		[errId] [int] IDENTITY(1,1) NOT NULL,
		[errMsg] [nvarchar](max) NOT NULL,
		[errProcId] [int] NOT NULL,
		[errText] [nvarchar](max) NULL,
		[errSection] [varchar](50) NULL,
		[errYear] [int] NULL,
		[errDate] [datetime] NOT NULL,
	 CONSTRAINT [PK_aError] PRIMARY KEY CLUSTERED 
	(
		[errId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
	
	ALTER TABLE [dbo].aError ADD  CONSTRAINT [DF_aError_errDate]  DEFAULT (getdate()) FOR [errDate]
END
GO


IF OBJECT_ID(N'dbo.aMaT_AnnualAnalysis') IS NULL
BEGIN
	CREATE TABLE [dbo].aMaT_AnnualAnalysis(
		[Pk] [int] IDENTITY(1,1) NOT NULL,
		[MostUsedObjFk] [int] NOT NULL,
		[TypeLocalName] [varchar](50) NOT NULL,
		[2018] [int] NOT NULL,
		[2019] [int] NOT NULL,
		[2020] [int] NOT NULL,
		[2021] [int] NOT NULL,
	 CONSTRAINT [PK_aMalwareAndTools_AnnualAnalysis] PRIMARY KEY CLUSTERED 
	(
		[Pk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.aMaT_AnnualRelations') IS NULL
BEGIN
	CREATE TABLE [dbo].aMaT_AnnualRelations(
		[Pk] [int] IDENTITY(1,1) NOT NULL,
		[MostUsedObjFk] [int] NOT NULL,
		[FromTypePk] [int] NOT NULL,
		[FromType] [varchar](50) NOT NULL,
		[FromName] [varchar](100) NOT NULL,
		[Technique] [varchar](50) NOT NULL,
		[TechRootPk] [varchar](100) NOT NULL,
		[TechMaxObjPk] [int] NULL,
		[TechType] [varchar](50) NOT NULL,
		[TechTypePk] [nchar](10) NOT NULL,
		[RelationTypeId] [int] NOT NULL,
		[RelationType] [varchar](50) NOT NULL,
		[Relation] [varchar](100) NOT NULL,
		[RelationPk] [int] NULL,
		[MitigationRootPk] [varchar](100) NULL,
		[MitigationMaxObjPk] [int] NULL,
		[2018] [int] NOT NULL,
		[2019] [int] NOT NULL,
		[2020] [int] NOT NULL,
		[2021] [int] NOT NULL,
	 CONSTRAINT [PK_aMaT_AnnualDefBypassed] PRIMARY KEY CLUSTERED 
	(
		[Pk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.aMaT_MuTechniquesAndMitigations') IS NULL
BEGIN
	CREATE TABLE [dbo].aMaT_MuTechniquesAndMitigations(
		[Pk] [int] IDENTITY(1,1) NOT NULL,
		[FromTypePk] [int] NOT NULL,
		[FromType] [varchar](50) NOT NULL,
		[ToTypePk] [int] NOT NULL,
		[ToType] [varchar](50) NOT NULL,
		[ToTypeRootPk] [varchar](100) NOT NULL,
		[ToTypeObjMaxPk] [int] NOT NULL,
		[ToTypeName] [varchar](50) NOT NULL,
		[2018] [int] NOT NULL,
		[2019] [int] NOT NULL,
		[2020] [int] NOT NULL,
		[2021] [int] NOT NULL,
	 CONSTRAINT [PK_aMaT_MostUsedTechniques] PRIMARY KEY CLUSTERED 
	(
		[Pk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.aMaT_Relation') IS NULL
BEGIN
	CREATE TABLE [dbo].aMaT_Relation(
		[Pk] [int] IDENTITY(1,1) NOT NULL,
		[RelationType] [varchar](50) NOT NULL,
	 CONSTRAINT [PK_aMatRelation] PRIMARY KEY CLUSTERED 
	(
		[Pk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
	
		
	SET IDENTITY_INSERT [dbo].aMaT_Relation ON
	INSERT [dbo].aMaT_Relation (Pk, RelationType)
	VALUES 
	(1, 'Defences Bypassed'),
	(2, 'Permissions Required'),
	(3, 'Killchain'),
	(4, 'Data Source'),
	(5, 'Mitigation (CoA)')
	SET IDENTITY_INSERT [dbo].aMaT_Relation OFF
END
GO


IF OBJECT_ID(N'dbo.aMkDataComponentDetails') IS NULL
BEGIN
	CREATE TABLE [dbo].aMkDataComponentDetails(
		[Data_Source] [nvarchar](110) NOT NULL,
		[Data_Component] [nvarchar](110) NOT NULL,
		[Source] [nvarchar](50) NOT NULL,
		[Relationship] [nvarchar](50) NOT NULL,
		[Target] [nvarchar](50) NOT NULL,
		[Dc_Rank] [int] NULL
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.aMostUsedCombinations') IS NULL
BEGIN
	CREATE TABLE [dbo].aMostUsedCombinations(
		[Pk] [int] IDENTITY(1,1) NOT NULL,
		[TargetTypeId] [int] NOT NULL,
		[SourceTypeId] [int] NOT NULL,
		[Top] [int] NOT NULL,
		[Detail] [varchar](200) NOT NULL,
		[IsTested] [bit] NOT NULL,
		[AppliedDt] [datetime] NULL,
		[AppliedTop] [int] NULL,
		[AppliedRowCount] [int] NULL,
	 CONSTRAINT [PK_aMostUsedCombinations] PRIMARY KEY CLUSTERED 
	(
		[Pk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].aMostUsedCombinations ADD  CONSTRAINT [DF_aMostUsedCombinations_IsTested]  DEFAULT ((1)) FOR [IsTested]

	SET IDENTITY_INSERT [dbo].aMostUsedCombinations ON
	INSERT INTO [dbo].aMostUsedCombinations 
	(Pk,	TargetTypeId,	SourceTypeId,	[Top],	Detail,							IsTested)
	VALUES
	(1,		8,				4,				30,		'Tool by Group',				1	),
	(2,		5,				4,				30,		'Malware by Group',				1	),
	(3,		1,				4,				50,		'Technique by Group',			1	),
	(5,		1,				5,				50,		'Technique by Malware',			1	),
	(6,		1,				8,				50,		'Technique by Tool',			1	),
	(7,		5,				2,				50,		'CoA by (against) Malware',		1	),
	(8,		8,				2,				45,		'CoA by (against) Tools',		1	),
	(11,	1,				2,				100,	'CoA by (against) Technique',	1	),
	(12,	11,				1,				60,		'Sub-Technique by Technique',	0	);		
	SET IDENTITY_INSERT [dbo].aMostUsedCombinations OFF
END
GO


IF OBJECT_ID(N'dbo.aMostUsedObjects') IS NULL
BEGIN
	CREATE TABLE [dbo].aMostUsedObjects(
		[Pk] [int] IDENTITY(1,1) NOT NULL,
		[ObjPkMax] [int] NOT NULL,
		[ObjRootPk] [varchar](100) NOT NULL,
		[ObjTypeId] [int] NOT NULL,
		[ByTypeId] [int] NOT NULL,
		[OrderId] [int] NOT NULL,
		[2018] [int] NOT NULL,
		[2019] [int] NOT NULL,
		[2020] [int] NOT NULL,
		[2021] [int] NOT NULL,
	 CONSTRAINT [PK_aMostUsedObject] PRIMARY KEY CLUSTERED 
	(
		[Pk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkAlias') IS NULL
BEGIN
	CREATE TABLE [dbo].mkAlias(
		[alPk] [int] IDENTITY(1,1) NOT NULL,
		[alMkObjPk] [int] NOT NULL,
		[alAlias] [nvarchar](50) NOT NULL,
		[alAliasSort] [nvarchar](100) NULL,
	 CONSTRAINT [PK_mkAlias] PRIMARY KEY CLUSTERED 
	(
		[alPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkDataSource') IS NULL
BEGIN
	CREATE TABLE [dbo].mkDataSource(
		[dsPk] [smallint] IDENTITY(1,1) NOT NULL,
		[dsName] [nvarchar](200) NOT NULL,
		[dsSource] [nvarchar](110) NULL,
		[dsComponent] [nvarchar](110) NULL,
	 CONSTRAINT [PK_mkDataSource] PRIMARY KEY CLUSTERED 
	(
		[dsPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkDefencesBypassed') IS NULL
BEGIN
	CREATE TABLE [dbo].mkDefencesBypassed(
		[defbyPk] [smallint] IDENTITY(1,1) NOT NULL,
		[defbyName] [nvarchar](50) NOT NULL,
	 CONSTRAINT [PK_mkDefencesBypassed] PRIMARY KEY CLUSTERED 
	(
		[defbyPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkEffectivePermissionGained') IS NULL
BEGIN
	CREATE TABLE [dbo].mkEffectivePermissionGained(
		[effpermPk] [smallint] IDENTITY(1,1) NOT NULL,
		[effpermName] [nvarchar](50) NOT NULL,
	 CONSTRAINT [PK_mkEffectivePermissionGained] PRIMARY KEY CLUSTERED 
	(
		[effpermPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkExternalReference') IS NULL
BEGIN
	CREATE TABLE [dbo].mkExternalReference(
		[exrId] [int] IDENTITY(1,1) NOT NULL,
		[exrMkObjId] [int] NOT NULL,
		[exrSourceName] [nvarchar](100) NULL,
		[exrExternalId] [nvarchar](50) NULL,
		[exrUrl] [varchar](250) NULL,
		[exrDescription] [nvarchar](max) NULL,
		[exrInserted] [date] NOT NULL,
	 CONSTRAINT [PK_mkExternalReference] PRIMARY KEY CLUSTERED 
	(
		[exrId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

	ALTER TABLE [dbo].mkExternalReference ADD  CONSTRAINT [DF_mkExternalReference_exrInserted]  DEFAULT (getdate()) FOR [exrInserted]
END
GO


IF OBJECT_ID(N'dbo.mkImpactType') IS NULL
BEGIN
	CREATE TABLE [dbo].mkImpactType(
		[itPk] [smallint] IDENTITY(1,1) NOT NULL,
		[itName] [varchar](50) NOT NULL,
	 CONSTRAINT [PK_mkImpactType] PRIMARY KEY CLUSTERED 
	(
		[itPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkObjectToDataSource') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObjectToDataSource(
		[odsObjectId] [int] NOT NULL,
		[odsDataSourceId] [int] NOT NULL,
	 CONSTRAINT [PK_mkObjectToDataSource] PRIMARY KEY CLUSTERED 
	(
		[odsObjectId] ASC,
		[odsDataSourceId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkObjectToDefenceBypassed') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObjectToDefenceBypassed(
		[dbpObjectId] [int] NOT NULL,
		[dpbDefenceBypassedId] [int] NOT NULL,
	 CONSTRAINT [PK_mkObjectToDefenceBypassed] PRIMARY KEY CLUSTERED 
	(
		[dbpObjectId] ASC,
		[dpbDefenceBypassedId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkObjectToEffectivePermGained') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObjectToEffectivePermGained(
		[epgObjectId] [int] NOT NULL,
		[epgEffectivePermGainedId] [int] NOT NULL,
	 CONSTRAINT [PK_mkObjectToEffectivePermGained] PRIMARY KEY CLUSTERED 
	(
		[epgObjectId] ASC,
		[epgEffectivePermGainedId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkObjectToImpactType') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObjectToImpactType(
		[oitObjectId] [int] NOT NULL,
		[oitImpactTypeId] [int] NOT NULL,
	 CONSTRAINT [PK_mkObjectToImpactType] PRIMARY KEY CLUSTERED 
	(
		[oitObjectId] ASC,
		[oitImpactTypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkObjectToKillchain') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObjectToKillchain(
		[okObjectId] [int] NOT NULL,
		[okKillchainId] [int] NOT NULL,
	 CONSTRAINT [PK_mkObjectToKillchain_1] PRIMARY KEY CLUSTERED 
	(
		[okObjectId] ASC,
		[okKillchainId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkObjectToPermissionRequired') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObjectToPermissionRequired(
		[oprObjectId] [int] NOT NULL,
		[oprPermRequired] [int] NOT NULL,
	 CONSTRAINT [PK_mkObjectToPermissionRequired] PRIMARY KEY CLUSTERED 
	(
		[oprObjectId] ASC,
		[oprPermRequired] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkObjectToPlatform') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObjectToPlatform(
		[opObjectId] [int] NOT NULL,
		[opPlatformId] [int] NOT NULL,
	 CONSTRAINT [PK_mkObjectToPlatform] PRIMARY KEY CLUSTERED 
	(
		[opObjectId] ASC,
		[opPlatformId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkObjectToSystemRequirement') IS NULL
BEGIN
	CREATE TABLE [dbo].mkObjectToSystemRequirement(
		[osrObjectId] [int] NOT NULL,
		[osrSysReqId] [int] NOT NULL
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkPermissionRequired') IS NULL
BEGIN
	CREATE TABLE [dbo].mkPermissionRequired(
		[permPk] [smallint] IDENTITY(1,1) NOT NULL,
		[permName] [varchar](50) NOT NULL,
	 CONSTRAINT [PK_mkPermissionRequired] PRIMARY KEY CLUSTERED 
	(
		[permPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkPlatform') IS NULL
BEGIN
	CREATE TABLE [dbo].mkPlatform(
		[platId] [smallint] IDENTITY(1,1) NOT NULL,
		[platName] [nvarchar](50) NOT NULL,
	 CONSTRAINT [PK_mkPlatform] PRIMARY KEY CLUSTERED 
	(
		[platId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkRelationship') IS NULL
BEGIN
	CREATE TABLE [dbo].mkRelationship(
		[relId] [int] IDENTITY(1,1) NOT NULL,
		[relMkObjPk] [int] NOT NULL,
		[relType] [varchar](30) NOT NULL,
		[relSourceRef] [varchar](100) NOT NULL,
		[relTargetRef] [varchar](100) NOT NULL,
		[relYear] [int] NOT NULL,
	 CONSTRAINT [PK_mkRelationship] PRIMARY KEY CLUSTERED 
	(
		[relId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkSection') IS NULL
BEGIN
	CREATE TABLE [dbo].mkSection(
		[sId] [int] IDENTITY(1,1) NOT NULL,
		[sName] [varchar](50) NOT NULL,
	 CONSTRAINT [PK_mkSection] PRIMARY KEY CLUSTERED 
	(
		[sId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO


IF OBJECT_ID(N'dbo.mkSystemRequirements') IS NULL
BEGIN
	CREATE TABLE [dbo].mkSystemRequirements(
		[srPk] [smallint] IDENTITY(1,1) NOT NULL,
		[srName] [varchar](500) NOT NULL,
	 CONSTRAINT [PK_mkSystemRequirements] PRIMARY KEY CLUSTERED 
	(
		[srPk] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO
--> ####################################################################################
--> ####################################################################################

IF OBJECT_ID(N'dbo.usp_Mitre_AddJason') IS NOT NULL
BEGIN
	DROP PROC [dbo].usp_Mitre_AddJason
END
GO
	CREATE   PROC [dbo].usp_Mitre_AddJason (
		@Yr			INT,
		@Section	VARCHAR(30),		--> 4x: enterprise-attack
		@JSON		NVARCHAR(MAX),		--> Full JSON
		@Type		VARCHAR(50)			--> 4x: Malware (ie. the directory name)
	)
	AS
	BEGIN
	
		--> MK: We create a new type for sub-techniques and add it to mkType.
		DECLARE 
		@test			INT = 0 --| 1 | 128		--> 1:comments; 128:return B4 main updates
		, 
		@mkObjPk		INT,
		@pk				VARCHAR(100),
		@createdBy		VARCHAR(100),
		@createdDate	DATE,
		@modifiedDate	DATE,
		@name			VARCHAR(50),
		@description	VARCHAR(max),
		@detection		VARCHAR(max),
		@isSubTechnique	BIT,
		@type2			VARCHAR(50),	--> The Type that is stored.
		@typeId			INT,
		@sectionId		INT,
		@revoked		BIT,
		@deprecated		BIT,
		@spec			VARCHAR(10),
		@ownersObjPk	VARCHAR(100),
		@rv				INT = 1,
		@minDate		DATE = '01 Jan 1900',

		--> Object types
		@attackPattern	VARCHAR(100) = 'attack-pattern',		--> aka Techniques
		@relationship	VARCHAR(100) = 'relationship',
		@intrusionSet	VARCHAR(100) = 'intrusion-set',			--> aka Group
		@malware		VARCHAR(100) = 'malware',
		@tool			VARCHAR(100) = 'tool'

		DECLARE @killchain TABLE (pk INT IDENTITY(1,1), kcName VARCHAR(50), fk INT)
		DECLARE @platform TABLE (pk INT IDENTITY(1,1), platformName NVARCHAR(50), fk INT)
		DECLARE @permissionsReq TABLE (pk INT IDENTITY(1,1), permName NVARCHAR(50), fk INT)
		DECLARE @dataSource TABLE (pk INT IDENTITY(1,1), dsName NVARCHAR(200), fk INT)
		DECLARE @sysReqs TABLE (pk INT IDENTITY(1,1), reqsName NVARCHAR(500), fk INT)
		DECLARE @effectivePerms TABLE (pk INT IDENTITY(1,1), effPermName NVARCHAR(50), fk INT)
		DECLARE @defencesBypassed TABLE (pk INT IDENTITY(1,1), defpassName NVARCHAR(50), fk INT)
		DECLARE @impactType TABLE (pk INT IDENTITY(1,1), impactTypeName NVARCHAR(50), fk INT)
		DECLARE @alias TABLE (pk INT IDENTITY(1,1), aliasName NVARCHAR(1000), fk INT)

		BEGIN TRY

			--EXEC dbo.usp_Mitre_AddBaseTables @ShowComments = 0;
		
			SELECT 
				@pk				= S.pk, 
				@createdBy		= S.CreatedBy, 
				@createdDate	= [Created], 
				@modifiedDate	= [Modified], 
				@description	= S.[description], 
				@name			= S.[Name],
				@revoked		= S.[isRevoked], 
				@deprecated		= S.[isDeprecated],
				@detection		= S.[Detection],
				@isSubTechnique	= S.[IsSubTechnique]
				--*
			FROM OPENJSON (@JSON, '$.objects')
			WITH (	
				[pk] VARCHAR(100) '$.id',
				[CreatedBy] VARCHAR(100) '$.created_by_ref',
				[Created] DATETIME2 '$.created',
				[Modified] DATETIME2 '$.modified',
				[Name] NVARCHAR(max) '$.name',
				[description] NVARCHAR(max) '$.description',
				[isDeprecated] BIT '$.x_mitre_deprecated',
				[Detection] NVARCHAR(MAX) '$.x_mitre_detection',
				[isRevoked] BIT '$.revoked',
				[IsSubTechnique] bIT '$.x_mitre_is_subtechnique'
				) as S;
		
			SELECT 
				@spec = spec_version, 
				@ownersObjPk = id
			FROM OPENJSON(@JSON)
			WITH (
				spec_version VARCHAR(10),
				id VARCHAR(100)
			);

			--> Get the Type to store. Note that we create our own 'Sub-Technique' type, which is a sub-type of attack-pattern.
			SELECT @type2 = @Type;
			SELECT @type2 = CASE WHEN @isSubTechnique = 1 THEN 'Sub-Technique' ELSE @Type END;

			IF 1=0 SELECT '==>' [Add JSON], @pk [@pk], @name [@name], @ownersObjPk [@ownersObjPk], @modifiedDate [@modifiedDate], @type2 [@type2];
		
			IF @Type = @attackPattern
			BEGIN
				BEGIN --> Extract killchain details
					INSERT @killchain (kcName, fk)
					SELECT DISTINCT
						L3.phase_name KC, kc.kcPk Fk
					FROM OPENJSON (@JSON)
					WITH  (	
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						kill_chain_phases NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[kill_chain_phases])
					WITH (
						phase_name VARCHAR(50)
					) L3
					LEFT JOIN mkKillchainPhases kc ON kc.kcVal = L3.phase_name;

					MERGE @killchain k
					USING (
						SELECT k.pk, x.kcPk fk
						FROM @killchain k
						INNER JOIN dbo.mkKillchainPhases x ON x.kcName = k.kcName
					) S ON S.pk = k.pk
					WHEN MATCHED THEN UPDATE SET k.fk = S.fk;

				END

				BEGIN	--> Extract permissions
					INSERT @permissionsReq (permName)
					SELECT DISTINCT L3.[value]
					FROM OPENJSON (@JSON)
					WITH (	
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						id VARCHAR(50),
						[x_mitre_permissions_required] NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[x_mitre_permissions_required]) L3;

					MERGE dbo.mkPermissionRequired pr
					USING (
						SELECT permName FROM @permissionsReq
					) S ON S.permName = pr.permName
					WHEN NOT MATCHED THEN INSERT (permName) VALUES(S.permName);

					MERGE @permissionsReq px
					USING (
						SELECT px.pk, pr.permPk fk
						FROM dbo.mkPermissionRequired pr
						INNER JOIN @permissionsReq px ON px.permName = pr.permName
					) S ON S.pk = px.pk
					WHEN MATCHED THEN UPDATE SET px.fk = S.fk;
				END		--> Extract permissions

				BEGIN	--> Data sources
					INSERT @dataSource (dsName)
					SELECT DISTINCT L3.[value]
					FROM OPENJSON (@JSON)
					WITH (	
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						id VARCHAR(50),
						[x_mitre_data_sources] NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[x_mitre_data_sources]) L3;

					MERGE dbo.mkDataSource ds
					USING (
						SELECT dsName ds,
						CASE WHEN CHARINDEX(':', dsName) > 0 THEN SUBSTRING(dsName, 1, CHARINDEX(':', dsName)-1) ELSE dsName END DS_Source,
						CASE WHEN CHARINDEX(':', dsName) > 0 THEN LTRIM(SUBSTRING(dsName, CHARINDEX(':', dsName) + 1, LEN(dsName))) ELSE '' END DS_Cpont
						FROM @dataSource
					) S ON S.ds = ds.dsName
					WHEN NOT MATCHED THEN INSERT (dsName, dsSource, dsComponent) 
					VALUES(S.ds, S.DS_Source, S.DS_Cpont);

					MERGE @dataSource dx
					USING (
						SELECT dx.pk, ds.dsPk fk
						FROM @dataSource dx
						INNER JOIN dbo.mkDataSource ds ON ds.dsName = dx.dsName
					) S ON S.pk = dx.pk
					WHEN MATCHED THEN UPDATE SET dx.fk = S.fk;
				END		--> Data sources

				BEGIN	--> System requirements
					INSERT @sysReqs (reqsName)
					SELECT DISTINCT L3.[value]
					FROM OPENJSON (@JSON)
					WITH (	--
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						id VARCHAR(50),
						[x_mitre_system_requirements] NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[x_mitre_system_requirements]) L3;

					MERGE dbo.mkSystemRequirements sr
					USING (
						SELECT reqsName rn FROM @sysReqs
					) S ON S.rn = sr.srName
					WHEN NOT MATCHED THEN INSERT (srName) VALUES (S.rn);

					MERGE @sysReqs rx
					USING (
						SELECT rx.pk, sr.srPk fk
						FROM @sysReqs rx 
						INNER JOIN dbo.mkSystemRequirements sr ON sr.srName = rx.reqsName
					) S ON S.pk = rx.pk
					WHEN MATCHED THEN UPDATE SET rx.fk = S.fk;
				END		--> System requirements
			
				BEGIN	--> Effective permissions (for Priviledge Escalation, the level of permissions gained by the attacker)
					INSERT @effectivePerms (effPermName)
					SELECT DISTINCT L3.[value]
					FROM OPENJSON (@JSON)
					WITH (	
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						id VARCHAR(50),
						[x_mitre_effective_permissions] NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[x_mitre_effective_permissions]) L3;

					MERGE dbo.mkEffectivePermissionGained epg
					USING (
						SELECT effPermName n
						FROM @effectivePerms
					) S ON S.n = epg.effpermName
					WHEN NOT MATCHED THEN INSERT (effpermName) VALUES (S.n);

					MERGE @effectivePerms ex
					USING (
						SELECT ex.pk pk, epg.effpermPk fk
						FROM @effectivePerms ex 
						INNER JOIN dbo.mkEffectivePermissionGained epg ON epg.effpermName = ex.effPermName
					) S ON S.pk = ex.pk
					WHEN MATCHED THEN UPDATE SET ex.fk = S.fk;
				END

				BEGIN	--> Defences bypassed (for Defense Evasion, list of defensive tools/methodologies/processes the technique can bypass)			
					INSERT @defencesBypassed (defpassName)
					SELECT DISTINCT L3.[value]
					FROM OPENJSON (@JSON)
					WITH (	
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						id VARCHAR(50),
						[x_mitre_defense_bypassed] NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[x_mitre_defense_bypassed]) L3;

					MERGE dbo.mkDefencesBypassed db
					USING (
						SELECT defpassName db
						FROM @defencesBypassed
					) S ON S.db = db.defbyName
					WHEN NOT MATCHED THEN INSERT (defbyName) VALUES (S.db);

					MERGE @defencesBypassed dx
					USING (
						SELECT dx.pk, db.defbyPk fk
						FROM @defencesBypassed dx
						INNER JOIN dbo.mkDefencesBypassed db ON db.defbyName = dx.defpassName
					) S ON S.pk = dx.pk
					WHEN MATCHED THEN UPDATE SET dx.fk = S.fk;
				END		--> Defences bypassed

				BEGIN	--> Impact Type (for Impact tactics, can the technique be used for integrity or availability checks)		
					INSERT @impactType (impactTypeName)
					SELECT DISTINCT L3.[value]
					FROM OPENJSON (@JSON)
					WITH (	
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						id VARCHAR(50),
						[x_mitre_impact_type] NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[x_mitre_impact_type]) L3;

					MERGE dbo.mkImpactType it
					USING (
						SELECT impactTypeName val
						FROM @impactType
					) S ON S.val = it.itName
					WHEN NOT MATCHED THEN INSERT (itName) VALUES (S.val);

					MERGE @impactType ix
					USING (
						SELECT ix.pk, it.itPk fk
						FROM @impactType ix 
						INNER JOIN dbo.mkImpactType it ON it.itName = ix.impactTypeName
					) S ON ix.pk = S.pk
					WHEN MATCHED THEN UPDATE SET ix.fk = S.fk;
				END		--> Impact Type
			END		--> 'attack-pattern'

			IF @Type IN (@attackPattern, @malware, @tool)
			BEGIN
				BEGIN	--> Extract platforms
					INSERT @platform (platformName)
					SELECT DISTINCT L3.[value]
					FROM OPENJSON (@JSON)
					WITH (	
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						id VARCHAR(50),
						[x_mitre_platforms] NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[x_mitre_platforms]) L3;

					--> Seed the platform lookups
					MERGE dbo.mkPlatform p
					USING (
						SELECT platformName pn FROM @platform
					) S ON S.pn = p.platName
					WHEN NOT MATCHED THEN INSERT (platName) VALUES (S.pn);

					--> Extract platform FKs
					MERGE @platform px 
					USING (
						SELECT px.pk, p.platId Fk
						FROM dbo.mkPlatform p
						INNER JOIN @platform px ON px.platformName = p.platName
					) S ON S.pk = px.pk
					WHEN MATCHED THEN UPDATE SET px.fk = S.Fk;
				END		--> Extract platforms
		
				INSERT @alias (aliasName)
				SELECT DISTINCT 
					S.[value] alias
				FROM (
					SELECT 
						L3.*
					FROM OPENJSON (@JSON)
					WITH (	
						[objects] NVARCHAR(max) AS JSON
					) as L1
					CROSS APPLY OPENJSON (L1.[objects])
					WITH (
						id VARCHAR(50),
						[aliases] NVARCHAR(max) AS JSON
					) L2
					CROSS APPLY OPENJSON (L2.[aliases]) L3
				) S;
			END		--> malware, tool

			MERGE dbo.mkSection t
			USING (
				SELECT @Section sect
			) S ON S.sect = t.sName
			WHEN NOT MATCHED THEN INSERT (sName) VALUES (S.sect);

			--> Although [Types] are predefined, we run the MERGE to capture any new ones.
			MERGE dbo.mkType t
			USING (
				SELECT @type2 typ
			) S ON S.typ = t.tName
			WHEN NOT MATCHED THEN INSERT (tName) VALUES (S.typ);

			SELECT @sectionId = [sId] FROM mkSection WHERE sName = @Section;
			SELECT @typeId = tId FROM mkType WHERE tName = @type2;

			IF EXISTS (SELECT 1 FROM dbo.mkObject t WHERE t.objRootObjPk = @pk AND t.objYear = @Yr)
			BEGIN
				--> Prevent duplicates
				INSERT dbo.aError (errMsg, errProcId, errText, errSection, errYear, errDate)
				VALUES ('Object already in DB.', @@PROCID, @pk, @Section, @Yr, GETDATE());
				RETURN -3;
			END

			BEGIN TRAN

			--> Store root object details
			MERGE dbo.mkRootObject t
			USING (
				SELECT @pk pk, @sectionId sect, @typeId typeId
			) S ON S.pk = t.roPk
			WHEN NOT MATCHED THEN INSERT (roPk, roSectionId, roTypeId)
			VALUES (S.pk, S.sect, S.typeId);

			--> Store JSON for the current year
			MERGE dbo.mkObject t
			USING (
				SELECT 
					@pk pk, @Yr yearId, @JSON content, 
					@ownersObjPk ownersObjPk, @spec spec,
					@description objDesc, @name objName,
					@createdBy createdBy, ISNULL(@createdDate, @minDate) created, ISNULL(@modifiedDate, @minDate) modified,
					ISNULL(@revoked, 0) isRevoked, ISNULL(@deprecated, 0) isDeprecated,
					@isSubTechnique isSubTechnique
			) S ON S.pk = t.objRootObjPk AND S.yearId = t.objYear
			WHEN NOT MATCHED THEN INSERT (objRootObjPk, objYear, objJson, objOwnersObjId, objSpec, objName, objDescription, 
				objCreatedDate, objCreatedById, objModifiedDate, objRevoked, objDeprecated)
			VALUES (S.pk, S.yearId, S.content, S.ownersObjPk, S.spec, S.objName, S.objDesc, 
				S.created, S.createdBy, S.modified, S.isRevoked, S.isDeprecated);

			SELECT @mkObjPk = mo.[objId] FROM mkObject mo WHERE mo.objRootObjPk = @pk AND mo.objYear = @Yr;
		
			IF 1=1 AND @Type = @attackPattern
			BEGIN
							
				IF EXISTS (SELECT 1 FROM @killchain) 
				BEGIN
					MERGE dbo.mkObjectToKillchain x
					USING (
						SELECT @mkObjPk ObjPk, fk
						FROM @killchain
					) S ON S.ObjPk = x.okObjectId AND S.fk = x.okKillchainId
					WHEN NOT MATCHED THEN INSERT (okObjectId, okKillchainId) VALUES (S.ObjPk, S.fk);
				END	

				IF EXISTS (SELECT 1 FROM @platform) 
				BEGIN
					MERGE dbo.mkObjectToPlatform x
					USING (
						SELECT @mkObjPk ObjPk, fk
						FROM @platform
					) S ON S.ObjPk = x.opObjectId AND S.fk = x.opPlatformId
					WHEN NOT MATCHED THEN INSERT (opObjectId, opPlatformId) VALUES (S.ObjPk, S.fk);
				END	

				IF EXISTS (SELECT 1 FROM @permissionsReq) 
				BEGIN
					MERGE dbo.mkObjectToPermissionRequired x
					USING (
						SELECT @mkObjPk ObjPk, fk
						FROM @permissionsReq
					) S ON S.ObjPk = x.oprObjectId AND S.fk = x.oprPermRequired
					WHEN NOT MATCHED THEN INSERT (oprObjectId, oprPermRequired) VALUES (S.ObjPk, S.fk);
				END	

				IF EXISTS (SELECT 1 FROM @dataSource) 
				BEGIN
					MERGE dbo.mkObjectToDataSource x
					USING (
						SELECT @mkObjPk ObjPk, fk
						FROM @dataSource
					) S ON S.ObjPk = x.odsObjectId AND S.fk = x.odsDataSourceId
					WHEN NOT MATCHED THEN INSERT (odsObjectId, odsDataSourceId) VALUES (S.ObjPk, S.fk);
				END	

				IF EXISTS (SELECT 1 FROM @sysReqs) 
				BEGIN
					MERGE dbo.mkObjectToSystemRequirement x
					USING (
						SELECT @mkObjPk ObjPk, fk
						FROM @sysReqs
					) S ON S.ObjPk = x.osrObjectId AND S.fk = x.osrSysReqId
					WHEN NOT MATCHED THEN INSERT (osrObjectId, osrSysReqId) VALUES (S.ObjPk, S.fk);
				END	

				IF EXISTS (SELECT 1 FROM @effectivePerms) 
				BEGIN
					MERGE dbo.mkObjectToEffectivePermGained x
					USING (
						SELECT @mkObjPk ObjPk, fk
						FROM @effectivePerms
					) S ON S.ObjPk = x.epgObjectId AND S.fk = x.epgEffectivePermGainedId
					WHEN NOT MATCHED THEN INSERT (epgObjectId, epgEffectivePermGainedId) VALUES (S.ObjPk, S.fk);
				END	

				IF EXISTS (SELECT 1 FROM @defencesBypassed) 
				BEGIN
					MERGE dbo.mkObjectToDefenceBypassed x
					USING (
						SELECT @mkObjPk ObjPk, fk
						FROM @defencesBypassed
					) S ON S.ObjPk = x.dbpObjectId AND S.fk = x.dpbDefenceBypassedId
					WHEN NOT MATCHED THEN INSERT (dbpObjectId, dpbDefenceBypassedId) VALUES (S.ObjPk, S.fk);
				END	

				IF EXISTS (SELECT 1 FROM @impactType) 
				BEGIN
					MERGE dbo.mkObjectToImpactType x
					USING (
						SELECT @mkObjPk ObjPk, fk
						FROM @impactType
					) S ON S.ObjPk = x.oitObjectId AND S.fk = x.oitImpactTypeId
					WHEN NOT MATCHED THEN INSERT (oitObjectId, oitImpactTypeId) VALUES (S.ObjPk, S.fk);
				END	

			END

			--> Store mkRelationship details
			IF @Type = @relationship
			BEGIN			
				MERGE mkRelationship r
				USING (
					SELECT @mkObjPk moPk, R.relType relType, R.sourceRef sourceRef, R.targetRef targetRef
					FROM OPENJSON (@JSON, '$.objects')
					WITH (	
						[relType] NVARCHAR(30) '$.relationship_type',
						[sourceRef] VARCHAR(100) '$.source_ref',
						[targetRef] VARCHAR(100) '$.target_ref'
					) as R 
				) S ON S.moPk = r.relMkObjPk
				WHEN NOT MATCHED THEN INSERT (relMkObjPk, relType, relSourceRef, relTargetRef, relYear)
				VALUES (S.moPk, S.relType, S.sourceRef, S.targetRef, @Yr);
			END
		
			--> Store Exernal References
			MERGE mkExternalReference x
			USING (
				SELECT 
					@mkObjPk mkObjPk,
					L2.id , 
					L3.source_name exSource, L3.external_id exId, L3.[url] exUrl, L3.[description] exDesc
				FROM OPENJSON (@JSON)
				WITH (	
					[objects] NVARCHAR(max) AS JSON
				) as L1
				CROSS APPLY OPENJSON (L1.[objects])
				WITH (
					id VARCHAR(100),
					external_references NVARCHAR(max) AS JSON
				) L2
				CROSS APPLY OPENJSON (L2.external_references)
				WITH (
					source_name VARCHAR(100),
					external_id VARCHAR(50),
					[url] VARCHAR(250),
					[description] VARCHAR(MAX)
				) as L3
			) S
			ON S.mkObjPk = x.exrMkObjId AND S.exSource = x.exrSourceName AND S.exId = x.exrExternalId AND S.exUrl = x.exrUrl
			WHEN NOT MATCHED THEN INSERT (exrMkObjId, exrSourceName, exrExternalId, exrUrl, exrDescription)
			VALUES (S.mkObjPk, S.exSource, S.exId, S.exUrl, S.exDesc);

			--> Store Aliases.
			IF @Type IN (@intrusionSet, @malware, @tool)
			BEGIN
				MERGE mkAlias a
				USING (			
					SELECT
						@mkObjPk moObjId, a.aliasName alias
					FROM @alias a
				) X ON X.moObjId = a.alMkObjPk AND X.alias = a.alAlias
				WHEN NOT MATCHED THEN INSERT (alMkObjPk, alAlias)
				VALUES (X.moObjId, X.alias);
			END
		
			BEGIN --> Testing

				IF (@test & 1 > 0) 
				BEGIN
					SELECT '=>' [Add JSON (552)], @sectionId [@sectionId], @typeId [@typeId], @isSubTechnique [@isSubTechnique], @spec [@spec], @ownersObjPk [@ownersObjPk],
						@pk [@pk], @createdBy [@createdBy], @description [@description], @detection [@detection], @name [@name],
						@revoked [@revoked], @deprecated [@deprecated];

					BEGIN	
						--> TODO: Store all the @attackPattern relationships
							
						IF EXISTS (SELECT 1 FROM @killchain)		BEGIN SELECT '=>' [Obj KC vals], x.*, '##' [##], y.* FROM @killchain x						LEFT JOIN dbo.mkObjectToKillchain y				ON y.okKillchainId = x.fk				AND y.okObjectId = @mkObjPk END
						IF EXISTS (SELECT 1 FROM @platform)			BEGIN SELECT '=>' [Obj Platform vals], x.*, '##' [##], y.* FROM @platform x					LEFT JOIN dbo.mkObjectToPlatform y				ON y.opPlatformId = x.fk				AND y.opObjectId = @mkObjPk END
						IF EXISTS (SELECT 1 FROM @permissionsReq)	BEGIN SELECT '=>' [Obj Perms], x.*, '##' [##], y.* FROM @permissionsReq x					LEFT JOIN dbo.mkObjectToPermissionRequired y	ON y.oprPermRequired = x.fk				AND y.oprObjectId = @mkObjPk END
						IF EXISTS (SELECT 1 FROM @dataSource)		BEGIN SELECT '=>' [Obj DataSource], x.*, '##' [##], y.* FROM @dataSource x					LEFT JOIN dbo.mkObjectToDataSource y			ON y.odsDataSourceId = x.fk				AND y.odsObjectId = @mkObjPk END
						IF EXISTS (SELECT 1 FROM @sysReqs)			BEGIN SELECT '=>' [Obj SysReqs], x.*, '##' [##], y.* FROM @sysReqs x						LEFT JOIN dbo.mkObjectToSystemRequirement y		ON y.osrSysReqId = x.fk					AND y.osrObjectId = @mkObjPk END
						IF EXISTS (SELECT 1 FROM @effectivePerms)	BEGIN SELECT '=>' [Obj EffectivePermsGained], x.*, '##' [##], y.* FROM @effectivePerms x	LEFT JOIN dbo.mkObjectToEffectivePermGained y	ON y.epgEffectivePermGainedId = x.fk	AND y.epgObjectId = @mkObjPk END
						IF EXISTS (SELECT 1 FROM @defencesBypassed)	BEGIN SELECT '=>' [Obj DefencesBypassed], x.*, '##' [##], y.* FROM @defencesBypassed x		LEFT JOIN dbo.mkObjectToDefenceBypassed y		ON y.dpbDefenceBypassedId = x.fk		AND y.dbpObjectId = @mkObjPk END
						IF EXISTS (SELECT 1 FROM @impactType)		BEGIN SELECT '=>' [Obj ImpactType], x.*, '##' [##], y.* FROM @impactType x					LEFT JOIN dbo.mkObjectToImpactType y			ON y.oitImpactTypeId = x.fk				AND y.oitObjectId = @mkObjPk END
					END
				END

				IF (@test & 128 > 0)
				BEGIN
					SELECT '=>' [Add JSON (572)], 'RETURN -1914' [Comment]

					ROLLBACK TRAN;
					RETURN -1914
				END

			END		--> Testing

			COMMIT TRAN

		END TRY
		BEGIN CATCH
			DECLARE @errmsg NVARCHAR(MAX) 
			SELECT @errmsg = ERROR_MESSAGE()

			IF @@TRANCOUNT > 0
			BEGIN
				ROLLBACK TRAN
			END

			INSERT dbo.aError (errMsg, errProcId, errText, errSection, errYear)
			VALUES (@errmsg, @@PROCID, @JSON, @Section, @Yr);

			IF @test > 0 SELECT '=>>>' [Error], @errmsg [ErrorMsg], @@TRANCOUNT [@@TRANCOUNT]
		
			SELECT @rv = -1;

			THROW 50005, @errmsg, 5;
		END CATCH

		RETURN @rv;
	END
GO

IF OBJECT_ID(N'dbo.usp_Mitre_GetObjectList') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].usp_Mitre_GetObjectList 
END
GO
	-- =============================================
	-- Author:		Marko Kennedy
	-- Create date: July 2021
	-- Description:	Return the list of object types, containing core details
	-- =============================================
	CREATE   PROCEDURE [dbo].usp_Mitre_GetObjectList 
	(
		@TypeId	INT 
	)
	AS
	BEGIN

		SELECT         
			mo.objId AS ObjPk, S.ObjPkMax, mo.objRootObjPk AS RootPk, @TypeId TypeId, mo.objYear AS Yr, mo.objName AS Name, 
			mo.objDescription AS Description, mo.objRevoked AS IsRevoked, mo.objDeprecated AS IsDepricated
		FROM dbo.mkRootObject AS ro
		INNER JOIN (
				SELECT        
					mo.objRootObjPk AS RootPk, MAX(mo.objId) ObjPkMax
				FROM dbo.mkObject AS mo 
				INNER JOIN dbo.mkRootObject AS ro ON ro.roPk = mo.objRootObjPk AND ro.roTypeId = @TypeId
				GROUP BY mo.objRootObjPk
		) S ON S.RootPk = ro.roPk
		INNER JOIN dbo.mkObject AS mo ON mo.objRootObjPk = S.RootPk
		WHERE (@TypeId <> 10 OR (@TypeId = 10 AND mo.objYear = 2021));

	END
GO

IF OBJECT_ID(N'dbo.usp_Mitre_GetObjectUsePerYear') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].usp_Mitre_GetObjectUsePerYear
END
GO
	-- =============================================
	-- Author:		Marko Kennedy
	-- Create date: July 2021
	-- Description:	Return a list of object use per year, with (Y|N) for each year [2018 -2021]
	-- =============================================
	CREATE   PROCEDURE [dbo].usp_Mitre_GetObjectUsePerYear 
	(
		@TypeId	INT 
	)
	AS
	BEGIN

		DECLARE @objs TABLE
		(
			ObjPk			INT,
			ObjPkMax		INT,
			RootPk			VARCHAR(100),
			TypeId			INT,
			Yr				INT,
			[Name]			VARCHAR(100),
			[Description]	VARCHAR(MAX),
			IsRevoked		BIT,
			IsDeprecated	BIT
		)

		INSERT @objs (ObjPk, ObjPkMax, RootPk, TypeId, Yr, [Name], [Description], IsRevoked, IsDeprecated)
		SELECT         
			mo.objId AS ObjPk, S.ObjPkMax, mo.objRootObjPk AS RootPk, @TypeId TypeId, mo.objYear AS Yr, mo.objName AS Name, 
			mo.objDescription AS Description, mo.objRevoked AS IsRevoked, mo.objDeprecated AS IsDepricated
		FROM dbo.mkRootObject AS ro
		INNER JOIN (
				SELECT        
					mo.objRootObjPk AS RootPk, MAX(mo.objId) ObjPkMax
				FROM dbo.mkObject AS mo 
				INNER JOIN dbo.mkRootObject AS ro ON ro.roPk = mo.objRootObjPk AND ro.roTypeId = @TypeId
				GROUP BY mo.objRootObjPk
		) S ON S.RootPk = ro.roPk
		INNER JOIN dbo.mkObject AS mo ON mo.objRootObjPk = S.RootPk
		WHERE (@TypeId <> 10 OR (@TypeId = 10 AND mo.objYear = 2021));

		/**/
		DECLARE @vals TABLE 
		(
			PK			INT IDENTITY(1,1),
			ObjPkMax	INT,
			RootPk		VARCHAR(100),
			ObjTypeId	INT,
			[2018]		CHAR(1), 
			[2019]		CHAR(1), 
			[2020]		CHAR(1), 
			[2021]		CHAR(1)
		)

		INSERT @vals (ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
		SELECT 
			PT.ObjPkMax, PT.RootPk, @TypeId TypeId, 
			CASE WHEN [2018] IS NULL THEN '' ELSE 'Y' END [2018],
			CASE WHEN [2019] IS NULL THEN '' ELSE 'Y' END [2019],
			CASE WHEN [2020] IS NULL THEN '' ELSE 'Y' END [2020],
			CASE WHEN [2021] IS NULL THEN '' ELSE 'Y' END [2021]
		FROM (
			SELECT o.ObjPkMax, o.RootPk, o.Yr
			FROM @objs o
		) Src
		PIVOT (
			MAX(Yr) FOR Yr IN ([2018],[2019],[2020],[2021])
		) PT;

		--> Return results
		SELECT * FROM  @vals
	END
GO

IF OBJECT_ID(N'dbo.usp_Mitre_MostUsedObjects') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].usp_Mitre_MostUsedObjects
END
GO
	/* =============================================
		 Author:			Marko Kennedy
		 Create date:		June 2021
		 Description:		Store the most used used object.
		
			4x, the top [@Top] Malware most used by Groups [@targetTypeId = 5, @sourceTypeId = 4]
	   ============================================= */
	CREATE   PROCEDURE [dbo].usp_Mitre_MostUsedObjects
		@MuComboPk			INT,			--> Pk for [aMostUsedCombinations] that defines the search
		@Top				INT	= NULL		--> The override value for the top most items to store
	AS
	BEGIN

		-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
		SET NOCOUNT ON;

		SELECT @Top = CASE WHEN @Top = 0 THEN NULL ELSE @Top END;

		DECLARE
		@test				INT = 0,				--> 1:Comments
		@relType			VARCHAR(30),
		@targetsByYear		dbo.ObjectUsePerYear,
		@sourcesByYear		dbo.ObjectUsePerYear,
		@targetTypeId		INT,					--> 
		@sourceTypeId		INT,					--> 
		@targetType			VARCHAR(50),
		@sourceType			VARCHAR(50),
		@topMu				INT,
		@dt					DATETIME = GETDATE(),
		@rowsAdded			INT 

		SELECT 
			@topMu			= ISNULL (@Top, c.[Top]),	--> Use override value, if specified
			@targetTypeId	= c.TargetTypeId,
			@sourceTypeId	= c.SourceTypeId,
			@targetType		= tt.LocalName,
			@sourceType		= st.LocalName
		FROM dbo.aMostUsedCombinations c
		INNER JOIN dbo.mkType tt ON tt.tId = c.TargetTypeId
		INNER JOIN dbo.mkType st ON st.tId = c.SourceTypeId
		WHERE c.Pk = @MuComboPk;

		IF @test & 1 > 0 
			SELECT '=>' [usp_Mitre_MostUsedObjects (inits)], @topMu [@topMu], 
					@targetType [@targetType], @sourceType [@sourceType], 
					@targetTypeId [@targetTypeId], @sourceTypeId [@sourceTypeId]

		IF (@topMu IS NULL OR @targetTypeId IS NULL OR @sourceTypeId IS NULL)
		BEGIN
			--THROW 50002, 'The input parameters were invalid. Select a PK from the [aMostUsedCombinations] table.', 1;
			RAISERROR ('The input parameter [@MuComboPk] is invalid. It must be a PK from the [aMostUsedCombinations] table.', 11, -1);
			RETURN -1;
		END


		IF 1=0 SELECT * FROM mkType
		SELECT @relType = 
			CASE WHEN @targetTypeId = 2 THEN 'mitigates'
			ELSE 'uses'
			END

		IF @sourceTypeId = 2
		BEGIN	--> Mitigations

			/*	CoA: we need alternative processing since CoA only relates to Sub-/Techniques,
				which we want to filter by Malware or Tools.
			*/

			DECLARE @objsByYear		dbo.ObjectUsePerYear;

			INSERT @sourcesByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
			EXEC dbo.usp_Mitre_GetObjectUsePerYear @sourceTypeId

			--> Get list of Malware or Tools against which to filter the target objects
			INSERT @objsByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
			EXEC dbo.usp_Mitre_GetObjectUsePerYear @targetTypeId
		
			--> Technique/Sub-Technique, related to @objsByYear
			INSERT @targetsByYear (Pk, ObjPkMax, RootPk, ObjTypeId)
			SELECT 
				ROW_NUMBER() OVER (ORDER BY r.relTargetRef) Pk,
				MAX(mo.[objId]) ObjPkMax, r.relTargetRef RootPk, ro.roTypeId
			FROM @objsByYear ou
			INNER JOIN dbo.mkRelationship r ON r.relSourceRef = ou.RootPk
			INNER JOIN dbo.mkObject mo ON mo.objRootObjPk = r.relTargetRef
			INNER JOIN dbo.mkRootObject ro ON ro.roPk = mo.objRootObjPk
				AND ro.roTypeId IN (1, 11)		--> Technique/Sub-Technique
			GROUP BY r.relTargetRef, ro.roTypeId;

			IF @test & 1 > 0 SELECT 'CoA section ->' [@targetsByYear], * FROM @targetsByYear;

			--> Clear the existing data
			DELETE dbo.aMostUsedObjects WHERE ObjTypeId = @targetTypeId AND ByTypeId = @sourceTypeId;

			--> Store the most used
			INSERT dbo.aMostUsedObjects (ObjPkMax, ObjRootPk, ObjTypeId, ByTypeId, OrderId, [2018], [2019], [2020], [2021])
			SELECT TOP(@topMu)
				m.ObjPkMax, m.RootPk, @targetTypeId ObjTypeId, @sourceTypeId ByTypeId, 

				ROW_NUMBER() OVER (ORDER BY 
					PT.[2021] DESC, PT.[2020] DESC, PT.[2019] DESC, PT.[2018] DESC,
					mo.objName) OrderId,
			 
				CASE WHEN PT.[2018] IS NULL THEN 0 ELSE PT.[2018] END [2018],
				CASE WHEN PT.[2019] IS NULL THEN 0 ELSE PT.[2019] END [2019],
				CASE WHEN PT.[2020] IS NULL THEN 0 ELSE PT.[2020] END [2020],
				CASE WHEN PT.[2021] IS NULL THEN 0 ELSE PT.[2021] END [2021]	
			FROM (
				SELECT m.Pk, r.relYear RelYr, COUNT(r.relId) RelCount
				FROM @sourcesByYear m
				INNER JOIN mkRelationship r ON r.relSourceRef = m.RootPk
					--AND r.relType = @relType
				INNER JOIN @targetsByYear g ON g.RootPk = r.relTargetRef
				GROUP BY m.Pk, r.relYear
			) Src
			PIVOT (
				MAX(RelCount) FOR RelYr IN ([2018],[2019],[2020],[2021])
			) PT
			INNER JOIN @sourcesByYear m ON m.Pk = PT.Pk
			INNER JOIN mkObject mo ON mo.[objId] = m.ObjPkMax;

			SELECT @rowsAdded = @@ROWCOUNT;

			--> Update the MostUsed Combinatations table
			UPDATE dbo.aMostUsedCombinations SET AppliedDt = @dt, AppliedTop = @topMu, AppliedRowCount = @rowsAdded WHERE Pk = @MuComboPk;

		END		--> Mitigations
		ELSE
		BEGIN
			--> Get list of target objects
			IF 1=1
			INSERT @targetsByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
			EXEC dbo.usp_Mitre_GetObjectUsePerYear @targetTypeId;

			INSERT @sourcesByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
			EXEC dbo.usp_Mitre_GetObjectUsePerYear @sourceTypeId;

			IF (1=0 OR @test & 1 > 0) 
			BEGIN 
				SELECT * FROM @targetsByYear;
				SELECT * FROM @sourcesByYear;
				IF 1=0 RETURN -99
			END

			--> Clear the existing data
			DELETE dbo.aMostUsedObjects WHERE ObjTypeId = @targetTypeId AND ByTypeId = @sourceTypeId;
	
			--> Store the most used
			INSERT dbo.aMostUsedObjects (ObjPkMax, ObjRootPk, ObjTypeId, ByTypeId, OrderId, [2018], [2019], [2020], [2021])
			SELECT TOP(@topMu)
				m.ObjPkMax, m.RootPk, @targetTypeId ObjTypeId, @sourceTypeId ByTypeId, 

				ROW_NUMBER() OVER (ORDER BY 
					PT.[2021] DESC, PT.[2020] DESC, PT.[2019] DESC, PT.[2018] DESC,
					mo.objName) OrderId,
			 
				CASE WHEN PT.[2018] IS NULL THEN 0 ELSE PT.[2018] END [2018],
				CASE WHEN PT.[2019] IS NULL THEN 0 ELSE PT.[2019] END [2019],
				CASE WHEN PT.[2020] IS NULL THEN 0 ELSE PT.[2020] END [2020],
				CASE WHEN PT.[2021] IS NULL THEN 0 ELSE PT.[2021] END [2021]	
			FROM (
				SELECT m.Pk, r.relYear RelYr, COUNT(r.relId) RelCount
				FROM @targetsByYear m
				INNER JOIN mkRelationship r ON r.relTargetRef = m.RootPk
					AND r.relType = @relType
				INNER JOIN @sourcesByYear g ON g.RootPk = r.relSourceRef
				GROUP BY m.Pk, r.relYear
			) Src
			PIVOT (
				MAX(RelCount) FOR RelYr IN ([2018],[2019],[2020],[2021])
			) PT
			INNER JOIN @targetsByYear m ON m.Pk = PT.Pk
			INNER JOIN mkObject mo ON mo.[objId] = m.ObjPkMax;

			SELECT @rowsAdded = @@ROWCOUNT;

			--> Update the MostUsed Combinatations table
			UPDATE dbo.aMostUsedCombinations SET AppliedDt = @dt, AppliedTop = @topMu, AppliedRowCount = @rowsAdded WHERE Pk = @MuComboPk;

			IF (1=0 OR @test & 1 > 0)
				SELECT '=>' [Results],
					Pk, ObjPkMax, ObjRootPk, ObjTypeId, ByTypeId, OrderId, [2018], [2019], [2020], [2021] 
				FROM dbo.aMostUsedObjects mu
				WHERE mu.ObjTypeId = @targetTypeId
				AND mu.ByTypeId = @sourceTypeId;

		END

		RETURN 1;

		--SELECT 'Updated ->' [usp_Mitre_MostUsedObjects], * FROM dbo.aMostUsedCombinations c WHERE c.Pk = @MuComboPk;
	END
GO

IF OBJECT_ID(N'dbo.usp_Mitre_MostUsedObjects_Associations') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].usp_Mitre_MostUsedObjects_Associations
END
GO
	/* =============================================
		 Author:			Marko Kennedy
		 Create date:		June 2021
		 Description:		
			Populate [aMaT_AnnualAnalysis] and [aMaT_AnnualRelations].
			Using Malware and Tools from [aMostUsedObjects], store the totals per for: 
			Techniques, SubTechniques, & Mitigations. 

			We also store indirect relationsip values {DefencesBypassed, Permissions Required, & Kllchain}.
			Indirect relations link to [aMostUsedObjects] via sub-/techniques.
		
			4x, the top [@Top] Malware most used by Groups [@targetTypeId = 5, @sourceTypeId = 4]
	   ============================================= */
	CREATE   PROCEDURE [dbo].usp_Mitre_MostUsedObjects_Associations
		@MostUsedPky			INT,				--> PK for [aMostUsedCombinations]: SELECT * FROM dbo.aMostUsedCombinations
		@DoReseed				BIT
	AS
	BEGIN

		IF (@MostUsedPky NOT IN (1,2))
		BEGIN		
			RAISERROR ('The input parameter [@MostUsedPky] is invalid. It must be a 1 or 2 PK value from the [aMostUsedCombinations] table.', 11, -1);
			RETURN -1;
		END

		SET NOCOUNT ON;

		IF 1=0 SELECT * FROM aMostUsedCombinations 
		DECLARE
		@muPky				INT = 0,
		@objTypeId			INT = 0,
		@SourceTypeId		INT = 0,
		@localTypeName		VARCHAR(50),
		@relationTypePk		INT,
		@relationType		VARCHAR(50);

		IF @DoReseed = 1
		BEGIN	--> Reseed tables 
			--> Optionally reseed the data.
			TRUNCATE TABLE dbo.aMaT_AnnualAnalysis;
			DBCC CHECKIDENT ('aMaT_AnnualAnalysis', RESEED, 1);

			TRUNCATE TABLE dbo.aMaT_AnnualRelations
			DBCC CHECKIDENT('dbo.aMaT_AnnualRelations', RESEED, 1);

			TRUNCATE TABLE dbo.aMaT_MuTechniquesAndMitigations;
			DBCC CHECKIDENT('dbo.aMaT_MuTechniquesAndMitigations', RESEED, 1);
		END

		BEGIN	--> Inits 

			--> Get parameters for the initial selection
			SELECT @objTypeId = c.TargetTypeId, @sourceTypeId = c.SourceTypeId 
			FROM dbo.aMostUsedCombinations c WHERE c.Pk = @MostUsedPky;
	
			--> Temp table to store most-used Malware or Tools
			IF OBJECT_ID('tempdb..#muMalwareOrTools') IS NOT NULL DROP TABLE #muMalwareOrTools
			CREATE TABLE #muMalwareOrTools(Fk	INT, RootPk VARCHAR(100), PkMax INT)
	
			--> Get MU malware
			INSERT #muMalwareOrTools (Fk, RootPk, PkMax)
			SELECT
				mu.Pk, mu.ObjRootPk, mu.ObjPkMax
			FROM dbo.aMostUsedObjects mu
			WHERE mu.ObjTypeId = @objTypeId AND mu.ByTypeId = @sourceTypeId;

		END		--> Inits
	
		--> ##########################################################################################
		--> I/III Annual Analysis - For each Mal/Tool: annual totals only per Technique or Mitigation
		--> ##########################################################################################

		BEGIN	--> Sub-/Techniques 

			MERGE dbo.aMaT_AnnualAnalysis x
			USING (
				SELECT PT.Pk, PT.TypeName, ISNULL(PT.[2018], 0) [2018], ISNULL(PT.[2019], 0) [2019], ISNULL(PT.[2020], 0) [2020], ISNULL(PT.[2021], 0) [2021]
				FROM (
					SELECT 			
						mu.Fk Pk, t.LocalName TypeName, r.relYear Yr, 
						COUNT(r.relTargetRef) [TgtCount]
					FROM #muMalwareOrTools mu
					INNER JOIN dbo.mkRelationship r ON r.relSourceRef = mu.RootPk
					INNER JOIN dbo.mkRootObject ro ON ro.roPk = r.relTargetRef
					INNER JOIN dbo.mkType t ON t.tId = ro.roTypeId
					GROUP BY mu.Fk, t.LocalName, r.relYear
				) Src
				PIVOT (
					SUM([TgtCount]) FOR Yr IN ([2018], [2019], [2020], [2021])
				) PT
				--ORDER BY PT.Pk, PT.TypeName;
			) S ON S.Pk = x.MostUsedObjFk AND S.TypeName = x.TypeLocalName
			WHEN NOT MATCHED THEN INSERT (MostUsedObjFk, TypeLocalName, [2018], [2019], [2020], [2021])
				VALUES (S.Pk, S.TypeName, S.[2018], S.[2019], S.[2020], S.[2021]);

		END --> Sub-/Techniques

		BEGIN	--> Mitigation/CoA 

			SELECT @localTypeName = t.LocalName FROM dbo.mkType t WHERE t.tId = 2
	
			MERGE dbo.aMaT_AnnualAnalysis x
			USING (
				SELECT PT.Fk Pk, @localTypeName TypeName, [2018], [2019], [2020], [2021]
				FROM (
					SELECT 
						T.Fk, r.relSourceRef [CoA], r.relYear Yr
					FROM (
						SELECT 
							--> Get techniques associated with each Malware
							'->' [MU simple list], 
							m1.Fk, m1.RootPk MalwareRoot, m1.PkMax MalWareObjMaxPk,
							r.relTargetRef TechniqueRoot, r.relYear Yr
						FROM #muMalwareOrTools m1
						INNER JOIN dbo.mkRelationship r ON r.relSourceRef = m1.RootPk
						--WHERE m1.Fk IN (82, 47)
						--ORDER BY m1.Fk
					) T
					INNER JOIN dbo.mkRelationship r ON r.relTargetRef = T.TechniqueRoot	--> Get associated CoA for each technique
						AND r.relYear = T.Yr AND r.relType = 'mitigates'
				) Src
				PIVOT (
					COUNT([CoA]) FOR Yr IN ([2018], [2019], [2020], [2021])
				) PT
			) S ON S.Pk = x.MostUsedObjFk AND S.TypeName = x.TypeLocalName
			WHEN NOT MATCHED THEN INSERT (MostUsedObjFk, TypeLocalName, [2018], [2019], [2020], [2021])
				VALUES (S.Pk, S.TypeName, S.[2018], S.[2019], S.[2020], S.[2021]);
		
		END		--> Mitigation/CoA
	
		--> ##########################################################################################
		--> II/III Annual Relations - For each Mal/Tool: all related objects with their annual totals
		--> ##########################################################################################

		BEGIN	--> Mitigation/CoA 
			SELECT @relationTypePk = r.Pk, @relationType = r.RelationType FROM dbo.aMaT_Relation r WHERE r.Pk = 5;

			--> Since Mitigations (CoA) are linked to Malware|Tools via Techniques, this is a two stage SELECT
			MERGE dbo.aMaT_AnnualRelations x
			USING (
				--> Stage II: Link Techniques to associated Mitigations (CoA)
				SELECT 
					PT.Fk,
					t.tId [FromTypePk], t.LocalName [FromType], mo.objName [FromName], 
					PT.Technique, PT.TechniqueRootPk, PT.TechType, PT.TechTypePk,

					PT.CoA, 
					ISNULL(PT.[2018], 0) [2018], 
					ISNULL(PT.[2019], 0) [2019], 
					ISNULL(PT.[2020], 0) [2020], 
					ISNULL(PT.[2021], 0) [2021]
				FROM (
					SELECT 
						S.Fk, S.Fk Fk2,
						S.[Technique], S.TechniqueRootPk, S.TechType, S.TechTypePk,
						r.relSourceRef CoA, S.Yr
					FROM dbo.mkRelationship r															--> Get the indirect Mitigation (CoA)
					INNER JOIN (
						--> Stage I: Get associated Techniques
						SELECT
							x.Fk,
							mot.objName [Technique], mot.objRootObjPk TechniqueRootPk, 
							tt.LocalName TechType, tt.tId TechTypePk,
							r.relYear Yr
						FROM #muMalwareOrTools x
						INNER JOIN dbo.mkObject mox ON mox.[objId] = x.PkMax							--> Malware or Tool's root object
						INNER JOIN dbo.mkRelationship r ON r.relSourceRef = x.RootPk					--> From Malware or Tool
							AND r.relType = 'uses'
						INNER JOIN dbo.mkRootObject rot ON rot.roPk = r.relTargetRef					--> Technique's root object
						INNER JOIN dbo.mkObject mot ON mot.[objId] = rot.roMaxObjPk						--> To technique
						INNER JOIN dbo.mkType tt ON tt.tId = rot.roTypeId								--> Technique's type
						--WHERE 1=1
						--AND x.Fk IN (35)
						--AND mot.objRootObjPk = 'attack-pattern--7bc57495-ea59-4380-be31-a64af124ef18'
						--AND r.relYear = 2018
						--ORDER BY mot.objRootObjPk, Yr DESC	--, [ItemCount] DESC
					) S ON S.TechniqueRootPk = r.relTargetRef AND S.Yr = r.relYear AND r.relType = 'mitigates'
				) Src
				PIVOT (
					COUNT([Fk2]) FOR Yr IN ([2018], [2019], [2020], [2021])
				) PT
				INNER JOIN dbo.aMostUsedObjects mu ON mu.Pk = PT.Fk
				INNER JOIN dbo.mkType t ON t.tId = mu.ObjTypeId
				INNER JOIN dbo.mkObject mo ON mo.[objId] = mu.ObjPkMax
			) S ON S.Fk = x.MostUsedObjFk AND S.TechniqueRootPk = x.TechRootPk AND S.[CoA] = x.MitigationRootPk
			WHEN NOT MATCHED THEN INSERT (MostUsedObjFk, 
				FromTypePk, FromType, FromName,
				Technique, TechRootPk, TechType, TechTypePk,
				RelationTypeId, RelationType,
				Relation, MitigationRootPk, [2018], [2019], [2020], [2021])
			VALUES(S.Fk, 
				S.FromTypePk, S.FromType, S.FromName,
				S.Technique, S.TechniqueRootPk, S.TechType, S.TechTypePk,
				@relationTypePk, @relationType,
				'-- CoA Placeholder --', S.[CoA], S.[2018], S.[2019], S.[2020], S.[2021]);

			--> Set Mitigation Name, MaxObjPk
			MERGE dbo.aMaT_AnnualRelations x
			USING ( 
				SELECT R.Pk, R.MaxObjId, mo.objName NameOfCoA
				FROM (
					SELECT ar.Pk, MAX(mo.[objId]) MaxObjId
					FROM dbo.aMaT_AnnualRelations ar
					INNER JOIN dbo.mkObject mo ON mo.objRootObjPk = ar.MitigationRootPk
					GROUP BY ar.Pk
				) R
				INNER JOIN dbo.mkObject mo ON mo.[objId] = R.MaxObjId
			) S ON S.Pk = x.Pk
			WHEN MATCHED THEN UPDATE SET 
				x.Relation				= S.NameOfCoA,
				x.MitigationMaxObjPk	= S.MaxObjId;

		END		--> Mitigation/CoA 

		BEGIN	--> Defences Bypassed 

			SELECT @relationTypePk = r.Pk, @relationType = r.RelationType FROM dbo.aMaT_Relation r WHERE r.Pk = 1;

			MERGE dbo.aMaT_AnnualRelations x
			USING (
				SELECT 
					PT.Fk,
					t.tId [FromTypePk], t.LocalName [FromType], mo.objName [FromName], 
					PT.Technique, PT.TechniqueRootPk, PT.TechType, PT.TechTypePk,
					PT.[Relation], PT.[RelPk],
					ISNULL(PT.[2018], 0) [2018], 
					ISNULL(PT.[2019], 0) [2019], 
					ISNULL(PT.[2020], 0) [2020], 
					ISNULL(PT.[2021], 0) [2021]
				FROM (
					SELECT --DISTINCT
						--'->' [MKX x], 
						x.Fk, x.Fk Fk2, --mox.objName [Mal/Tool],
						mot.objName [Technique], mot.objRootObjPk TechniqueRootPk, 
						tt.LocalName [TechType], tt.tId TechTypePk, 
						dp.defbyName [Relation], dp.defbyPk [RelPk], r.relYear Yr
					FROM #muMalwareOrTools x
					INNER JOIN dbo.mkObject mox ON mox.[objId] = x.PkMax							--> Malware or Tool's root object
					INNER JOIN dbo.mkRelationship r ON r.relSourceRef = x.RootPk					--> From Malware or Tool
						AND r.relType = 'uses'
					INNER JOIN dbo.mkRootObject rot ON rot.roPk = r.relTargetRef					--> Technique's root object
					INNER JOIN dbo.mkObject mot ON mot.[objId] = rot.roMaxObjPk						--> To technique
					INNER JOIN dbo.mkType tt ON tt.tId = rot.roTypeId								--> Technique's type
					INNER JOIN dbo.mkObjectToDefenceBypassed d ON d.dbpObjectId = mot.[objId]		
					INNER JOIN dbo.mkDefencesBypassed dp ON dp.defbyPk = d.dpbDefenceBypassedId
					WHERE 1=1
					--AND x.Fk IN (62, 34)
				) Src
				PIVOT (
					COUNT([Fk2]) FOR Yr IN ([2018], [2019], [2020], [2021])
				) PT
				INNER JOIN dbo.aMostUsedObjects mu ON mu.Pk = PT.Fk
				INNER JOIN dbo.mkType t ON t.tId = mu.ObjTypeId
				INNER JOIN dbo.mkObject mo ON mo.[objId] = mu.ObjPkMax
			) S ON S.Fk = x.MostUsedObjFk AND S.TechniqueRootPk = x.TechRootPk AND S.[RelPk] = x.RelationPk
			WHEN NOT MATCHED THEN INSERT (MostUsedObjFk, 
				FromTypePk, FromType, FromName,
				Technique, TechRootPk, TechType, TechTypePk,
				RelationTypeId, RelationType,
				Relation, RelationPk, [2018], [2019], [2020], [2021])
			VALUES(S.Fk, 
				S.FromTypePk, S.FromType, S.FromName,
				S.Technique, S.TechniqueRootPk, S.TechType, S.TechTypePk,
				@relationTypePk, @relationType,
				S.[Relation], S.[RelPk], S.[2018], S.[2019], S.[2020], S.[2021]);

		END		--> Defences Bypassed

		BEGIN	--> Permissions Required 

			SELECT @relationTypePk = r.Pk, @relationType = r.RelationType FROM dbo.aMaT_Relation r WHERE r.Pk = 2;

			MERGE dbo.aMaT_AnnualRelations x
			USING (
				SELECT 
					PT.Fk, 
					t.tId [FromTypePk], t.LocalName [FromType], mo.objName [FromName], 
					PT.Technique, PT.TechniqueRootPk, PT.TechType, PT.TechTypePk,
					PT.[Relation], PT.[RelPk],
					ISNULL(PT.[2018], 0) [2018], 
					ISNULL(PT.[2019], 0) [2019], 
					ISNULL(PT.[2020], 0) [2020], 
					ISNULL(PT.[2021], 0) [2021]
				FROM (
					SELECT --DISTINCT
						--'->' [MKX x], 
						x.Fk, x.Fk Fk2, --mox.objName [Mal/Tool],
						mot.objName [Technique], mot.objRootObjPk TechniqueRootPk, 
						tt.LocalName [TechType], tt.tId TechTypePk, 
						p.permName [Relation], p.permPk [RelPk], r.relYear Yr
					FROM #muMalwareOrTools x
					INNER JOIN dbo.mkObject mox ON mox.[objId] = x.PkMax							--> Malware or Tool's root object
					INNER JOIN dbo.mkRelationship r ON r.relSourceRef = x.RootPk					--> From Malware or Tool
						AND r.relType = 'uses'
					INNER JOIN dbo.mkRootObject rot ON rot.roPk = r.relTargetRef					--> Technique's root object
					INNER JOIN dbo.mkObject mot ON mot.[objId] = rot.roMaxObjPk						--> To technique
					INNER JOIN dbo.mkType tt ON tt.tId = rot.roTypeId								--> Technique's type
					INNER JOIN dbo.mkObjectToPermissionRequired y ON y.oprObjectId = mot.[objId]
					INNER JOIN dbo.mkPermissionRequired p ON p.permPk = y.oprPermRequired
					WHERE 1=1
					--AND x.Fk IN (62, 34)
				) Src
				PIVOT (
					COUNT([Fk2]) FOR Yr IN ([2018], [2019], [2020], [2021])
				) PT
				INNER JOIN dbo.aMostUsedObjects mu ON mu.Pk = PT.Fk
				INNER JOIN dbo.mkType t ON t.tId = mu.ObjTypeId
				INNER JOIN dbo.mkObject mo ON mo.[objId] = mu.ObjPkMax
			) S ON S.Fk = x.MostUsedObjFk AND S.TechniqueRootPk = x.TechRootPk AND S.[RelPk] = x.RelationPk
			WHEN NOT MATCHED THEN INSERT (MostUsedObjFk, 
				FromTypePk, FromType, FromName,
				Technique, TechRootPk, TechType, TechTypePk,
				RelationTypeId, RelationType,
				Relation, RelationPk, [2018], [2019], [2020], [2021])
			VALUES(S.Fk, 
				S.FromTypePk, S.FromType, S.FromName,
				S.Technique, S.TechniqueRootPk, S.TechType, S.TechTypePk,
				@relationTypePk, @relationType,
				S.[Relation], S.[RelPk], S.[2018], S.[2019], S.[2020], S.[2021]);

		END		--> Permissions Required	
	
		BEGIN	--> Killchain associations 

			SELECT @relationTypePk = r.Pk, @relationType = r.RelationType FROM dbo.aMaT_Relation r WHERE r.Pk = 3;

			MERGE dbo.aMaT_AnnualRelations x
			USING (
				SELECT 
					PT.Fk, 
					t.tId [FromTypePk], t.LocalName [FromType], mo.objName [FromName], 
					PT.Technique, PT.TechniqueRootPk, PT.TechType, PT.TechTypePk,
					PT.[Relation], PT.[RelPk],
					ISNULL(PT.[2018], 0) [2018], 
					ISNULL(PT.[2019], 0) [2019], 
					ISNULL(PT.[2020], 0) [2020], 
					ISNULL(PT.[2021], 0) [2021]
				FROM (
					SELECT --DISTINCT
						--'->' [MKX x], 
						x.Fk, x.Fk Fk2, --mox.objName [Mal/Tool],
						mot.objName [Technique], mot.objRootObjPk TechniqueRootPk, 
						tt.LocalName [TechType], tt.tId TechTypePk, 
						k.kcName [Relation], k.kcPk [RelPk], r.relYear Yr
					FROM #muMalwareOrTools x
					INNER JOIN dbo.mkObject mox ON mox.[objId] = x.PkMax							--> Malware or Tool's root object
					INNER JOIN dbo.mkRelationship r ON r.relSourceRef = x.RootPk					--> From Malware or Tool
						AND r.relType = 'uses'
					INNER JOIN dbo.mkRootObject rot ON rot.roPk = r.relTargetRef					--> Technique's root object
					INNER JOIN dbo.mkObject mot ON mot.[objId] = rot.roMaxObjPk						--> To technique
					INNER JOIN dbo.mkType tt ON tt.tId = rot.roTypeId								--> Technique's type
					INNER JOIN dbo.mkObjectToKillchain y ON y.okObjectId = mot.[objId]
					INNER JOIN dbo.mkKillchainPhases k ON k.kcPk = y.okKillchainId
					WHERE 1=1
					--AND x.Fk IN (62, 34)
				) Src
				PIVOT (
					COUNT([Fk2]) FOR Yr IN ([2018], [2019], [2020], [2021])
				) PT
				INNER JOIN dbo.aMostUsedObjects mu ON mu.Pk = PT.Fk
				INNER JOIN dbo.mkType t ON t.tId = mu.ObjTypeId
				INNER JOIN dbo.mkObject mo ON mo.[objId] = mu.ObjPkMax
			) S ON S.Fk = x.MostUsedObjFk AND S.TechniqueRootPk = x.TechRootPk AND S.[RelPk] = x.RelationPk
			WHEN NOT MATCHED THEN INSERT (MostUsedObjFk, 
				FromTypePk, FromType, FromName,
				Technique, TechRootPk, TechType, TechTypePk,
				RelationTypeId, RelationType,
				Relation, RelationPk, [2018], [2019], [2020], [2021])
			VALUES(S.Fk, 
				S.FromTypePk, S.FromType, S.FromName,
				S.Technique, S.TechniqueRootPk, S.TechType, S.TechTypePk,
				@relationTypePk, @relationType,
				S.[Relation], S.[RelPk], S.[2018], S.[2019], S.[2020], S.[2021]);

		END		--> Killchain assciations	
	
		BEGIN	--> Data Sources 

			SELECT @relationTypePk = r.Pk, @relationType = r.RelationType FROM dbo.aMaT_Relation r WHERE r.Pk = 4;

			MERGE dbo.aMaT_AnnualRelations x
			USING (
				SELECT 
					PT.Fk, 
					t.tId [FromTypePk], t.LocalName [FromType], mo.objName [FromName], 
					PT.Technique, PT.TechniqueRootPk, PT.TechType, PT.TechTypePk,
					PT.[Relation], PT.[RelPk],
					ISNULL(PT.[2018], 0) [2018], 
					ISNULL(PT.[2019], 0) [2019], 
					ISNULL(PT.[2020], 0) [2020], 
					ISNULL(PT.[2021], 0) [2021]
				FROM (
					SELECT --DISTINCT
						--'->' [MKX x], 
						x.Fk, x.Fk Fk2, --mox.objName [Mal/Tool],
						mot.objName [Technique], mot.objRootObjPk TechniqueRootPk, 
						tt.LocalName [TechType], tt.tId TechTypePk, 
						k.dsName [Relation], k.dsPk [RelPk], r.relYear Yr
					FROM #muMalwareOrTools x
					INNER JOIN dbo.mkObject mox ON mox.[objId] = x.PkMax							--> Malware or Tool's root object
					INNER JOIN dbo.mkRelationship r ON r.relSourceRef = x.RootPk					--> From Malware or Tool
						AND r.relType = 'uses'
					INNER JOIN dbo.mkRootObject rot ON rot.roPk = r.relTargetRef					--> Technique's root object
					INNER JOIN dbo.mkObject mot ON mot.[objId] = rot.roMaxObjPk						--> To technique
					INNER JOIN dbo.mkType tt ON tt.tId = rot.roTypeId								--> Technique's type
					INNER JOIN dbo.mkObjectToDataSource y ON y.odsObjectId = mot.[objId]
					INNER JOIN dbo.mkDataSource k ON k.dsPk = y.odsDataSourceId
					WHERE 1=1
					--AND x.Fk IN (62, 34)
				) Src
				PIVOT (
					COUNT([Fk2]) FOR Yr IN ([2018], [2019], [2020], [2021])
				) PT
				INNER JOIN dbo.aMostUsedObjects mu ON mu.Pk = PT.Fk
				INNER JOIN dbo.mkType t ON t.tId = mu.ObjTypeId
				INNER JOIN dbo.mkObject mo ON mo.[objId] = mu.ObjPkMax
			) S ON S.Fk = x.MostUsedObjFk AND S.TechniqueRootPk = x.TechRootPk AND S.[RelPk] = x.RelationPk
			WHEN NOT MATCHED THEN INSERT (MostUsedObjFk, 
				FromTypePk, FromType, FromName,
				Technique, TechRootPk, TechType, TechTypePk,
				RelationTypeId, RelationType,
				Relation, RelationPk, [2018], [2019], [2020], [2021])
			VALUES(S.Fk, 
				S.FromTypePk, S.FromType, S.FromName,
				S.Technique, S.TechniqueRootPk, S.TechType, S.TechTypePk,
				@relationTypePk, @relationType,
				S.[Relation], S.[RelPk], S.[2018], S.[2019], S.[2020], S.[2021]);

		END		--> Data Sources

		BEGIN	--> Update [TechMaxObjPk] in [aMaT_AnnualRelations]

			MERGE dbo.aMaT_AnnualRelations ar
			USING (
				SELECT DISTINCT
					ar.TechRootPk, ro.roMaxObjPk TechMaxObjPk
				FROM dbo.aMaT_AnnualRelations ar
				INNER JOIN dbo.mkRootObject ro ON ro.roPk = ar.TechRootPk
				WHERE ar.TechMaxObjPk IS NULL
			) S ON S.TechRootPk = ar.TechRootPk
			WHEN MATCHED THEN UPDATE SET ar.TechMaxObjPk = S.TechMaxObjPk;
		
		END		--> Update [TechMaxObjPk] in [aMaT_AnnualRelations]
	
		--> ##########################################################################################
		--> II/III Most used Techniques/Mitigations - For each Mal/Tool: ...?
		--> 
		--> The following data may now be implicit in [aMaT_AnnualRelations] - 17 Jul 21: not sure
		--> ##########################################################################################
		BEGIN	--> Most-used Techniques across all Malware/Tools in [aMostUsedObjects]
		
			--> The Techniques used by the most-used objects in [aMostUsedObjects]
			MERGE dbo.aMaT_MuTechniquesAndMitigations x
			USING (
				SELECT PT.TypePk FromTypePk, t.LocalName [FromType], tt.tId ToTypePk, tt.LocalName ToType, PT.Technique ToTechniqueRooPk, PT.TechObjPk, mo.objName TechniqueName,
					ISNULL(PT.[2018], 0) [2018],
					ISNULL(PT.[2019], 0) [2019],
					ISNULL(PT.[2020], 0) [2020],
					ISNULL(PT.[2021], 0) [2021]
				FROM (
					SELECT --TOP 5 
						ro.roTypeId TypePk, r.relTargetRef [Technique], r.relYear Yr, COUNT(r.relId) Tcount, Max(mo.[objId]) TechObjPk
					FROM dbo.mkRelationship r
					INNER JOIN dbo.aMostUsedObjects mu ON mu.ObjRootPk = r.relSourceRef
					INNER JOIN dbo.mkRootObject ro ON ro.roPk = r.relSourceRef
						AND ro.roTypeId = @objTypeId
					INNER JOIN dbo.mkObject mo ON mo.objRootObjPk = r.relTargetRef
					GROUP BY ro.roTypeId, r.relTargetRef, r.relYear
				) Src
				PIVOT (
					MAX(Tcount) FOR Yr IN ([2018],[2019],[2020],[2021])
				) PT
				INNER JOIN dbo.mkType t ON t.tId = PT.TypePk
				INNER JOIN dbo.mkObject mo ON mo.[objId] = PT.TechObjPk
				INNER JOIN dbo.mkRootObject ro ON ro.roPk = mo.objRootObjPk
				INNER JOIN dbo.mkType tt ON tt.tId = ro.roTypeId
				--ORDER BY PT.[2021] DESC, PT.[2020] DESC, PT.[2019] DESC, PT.[2018] DESC
			) S ON S.FromTypePk = x.FromTypePk AND S.ToTechniqueRooPk = x.ToTypeRootPk
			WHEN NOT MATCHED THEN INSERT ([FromTypePk], [FromType],
			   [ToTypePk], [ToType], [ToTypeRootPk], [ToTypeObjMaxPk], [ToTypeName],
			   [2018], [2019], [2020], [2021])
			VALUES (S.FromTypePk, S.FromType,
				S.ToTypePk, S.ToType, S.ToTechniqueRooPk, S.TechObjPk, S.TechniqueName,
				S.[2018], S.[2019], S.[2020], S.[2021]);

		END		--> Most-used Techniques across all Malware/Tools
	END	
GO


IF OBJECT_ID(N'dbo.usp_Mitre_RunAnalysis') IS NOT NULL
BEGIN
	DROP PROC [dbo].usp_Mitre_RunAnalysis
END
GO

	CREATE   PROC [dbo].usp_Mitre_RunAnalysis (
		@TopMu			INT = 0				--> Non-zero value overrides the [Top] value of the specified search
	)
	AS
	BEGIN

		DECLARE 
		@pk			INT,
		@maxPk		INT,
		@rv			INT,
		@start		DATETIME,
		@end		DATETIME;

		DECLARE @resultz TABLE (Pk INT, Dets VARCHAR(255), muTop INT, Rv INT, ElapsedSecs INT);

		--> Ensure [roMaxObjPk] in [mkRootObject] is popluated
		MERGE dbo.mkRootObject ro
		USING (
			SELECT ro.roPk Pk, MAX(mo.[objId]) MaxObjPk
			FROM dbo.mkRootObject ro
			INNER JOIN dbo.mkObject mo ON mo.objRootObjPk = ro.roPk
			WHERE ro.roMaxObjPk IS NULL
			GROUP BY  ro.roPk
		) S ON S.Pk = ro.roPk
		WHEN MATCHED THEN UPDATE SET ro.roMaxObjPk = S.MaxObjPk;

		SELECT @pk = MIN(Pk), @maxPk = MAX(Pk) FROM dbo.aMostUsedCombinations c WHERE c.IsTested = 1;
		--SELECT @maxPk = 1;

		--> Reseed the MostUsedObjects
		TRUNCATE TABLE dbo.aMostUsedObjects
		UPDATE dbo.aMostUsedCombinations SET AppliedDt = NULL, AppliedTop = NULL, AppliedRowCount = NULL;

		WHILE (@pk <= @maxPk)
		BEGIN
			SELECT @rv = 0, @start = GETDATE();

			EXEC @rv = dbo.usp_Mitre_MostUsedObjects @MuComboPk = @pk, @Top = @TopMu;

			SELECT @end = GETDATE();

			INSERT @resultz (Pk, Dets, muTop, Rv, ElapsedSecs)
			VALUES (@pk, 'Processed MU', @TopMu, @rv, DATEDIFF(second, @start, @end));

			--SELECT @pk [PK 4 all];

			SELECT @pk = MIN(Pk) FROM dbo.aMostUsedCombinations c WHERE c.Pk > @pk AND c.IsTested = 1;;
		END
		
		IF 1=0 SELECT * FROM dbo.aMostUsedCombinations c 
		IF 1=1 EXEC [dbo].usp_Mitre_MostUsedObjects_Associations @MostUsedPky = 1, @DoReseed = 1;	--> Populate this table (Tools for Sub-/Techniques/CoA)
		IF 1=1 EXEC [dbo].usp_Mitre_MostUsedObjects_Associations @MostUsedPky = 2, @DoReseed = 0;	--> Populate this table (Malware for Sub-/Techniques/CoA)

		SELECT '->' [Results], r.*, '###' [###], c.* FROM @resultz r LEFT JOIN dbo.aMostUsedCombinations c ON c.Pk = r.Pk;

		SELECT 'aMalwareAndTools_AnnualAnalysis' [AnnualAnalysis], 'N/a' [FromType], 'N/a' [ToType], COUNT(*) [Count AnnualAnalysis] FROM dbo.aMaT_AnnualAnalysis
		UNION
		SELECT 'aMaT_AnnualRelations' [AnnualAnalysis], r.FromType [FromType], r.RelationType [ToType], COUNT(*) [Count Annual Analysis] FROM dbo.aMaT_AnnualRelations r GROUP BY r.FromType, r.RelationType
		UNION
		SELECT 'dbo.aMaT_MuTechniquesAndMitigations', x.FromType, x.ToType ,COUNT(*) [Count Annalysis] FROM dbo.aMaT_MuTechniquesAndMitigations x GROUP BY x.FromType, x.ToType --ORDER BY x.FromType, x.ToType

	END
GO


IF OBJECT_ID(N'dbo.usp_Mitre_TruncateBaseTables') IS NOT NULL
BEGIN
	DROP PROC [dbo].usp_Mitre_TruncateBaseTables
END
GO

	CREATE   PROC [dbo].usp_Mitre_TruncateBaseTables (
		@ShowComments	TINYINT = 0
	)
	AS
	BEGIN
		--> ################################################################
		--> Analysis tables - Marko's tables
		--> ################################################################

		TRUNCATE TABLE dbo.aAdmin
		--DBCC CHECKIDENT('aAdmin', RESEED, 1);

		TRUNCATE TABLE dbo.aAudit
		--DBCC CHECKIDENT('aAudit', RESEED, 1);

		TRUNCATE TABLE dbo.aError
		DBCC CHECKIDENT('aError', RESEED, 1);

		TRUNCATE TABLE dbo.aMalware2Killchain_OLD
		--DBCC CHECKIDENT('aMalware2Killchain_OLD', RESEED, 1);
	
		TRUNCATE TABLE dbo.aMaT_AnnualAnalysis
		DBCC CHECKIDENT('aMaT_AnnualAnalysis', RESEED, 1);

		TRUNCATE TABLE dbo.aMaT_AnnualRelations
		DBCC CHECKIDENT('aMaT_AnnualRelations', RESEED, 1);

		TRUNCATE TABLE dbo.aMaT_MuTechniquesAndMitigations
		DBCC CHECKIDENT('aMaT_MuTechniquesAndMitigations', RESEED, 1);

		--TRUNCATE TABLE dbo.aMaT_Relation
		--DBCC CHECKIDENT('aMaT_Relation', RESEED, 1);

		--TRUNCATE TABLE dbo.aMostUsedCombinations
		--DBCC CHECKIDENT('aMostUsedCombinations', RESEED, 1);

		TRUNCATE TABLE dbo.aMostUsedObjects
		DBCC CHECKIDENT('aMostUsedObjects', RESEED, 1);
	
		--> ################################################################
		--> Import tables - raw Mitre ATT&CK data
		--> ################################################################

		TRUNCATE TABLE dbo.mkAlias
		DBCC CHECKIDENT('mkAlias', RESEED, 1);

		TRUNCATE TABLE dbo.mkDataSource
		DBCC CHECKIDENT('mkDataSource', RESEED, 1);

		TRUNCATE TABLE dbo.mkDefencesBypassed
		DBCC CHECKIDENT('mkDefencesBypassed', RESEED, 1);

		TRUNCATE TABLE dbo.mkEffectivePermissionGained
		DBCC CHECKIDENT('mkEffectivePermissionGained', RESEED, 1);

		TRUNCATE TABLE dbo.mkExternalReference;
		DBCC CHECKIDENT('mkExternalReference', RESEED, 1);

		TRUNCATE TABLE dbo.mkImpactType
		DBCC CHECKIDENT('mkImpactType', RESEED, 1);

		--TRUNCATE TABLE dbo.mkKillchainPhases
		--DBCC CHECKIDENT('mkKillchainPhases', RESEED, 1);

		TRUNCATE TABLE dbo.mkObject
		DBCC CHECKIDENT('mkObject', RESEED, 1);

		TRUNCATE TABLE dbo.mkObjectToDataSource
		--DBCC CHECKIDENT('mkObjectToDataSource', RESEED, 1);

		TRUNCATE TABLE dbo.mkObjectToDefenceBypassed
		--DBCC CHECKIDENT('mkObjectToDefenceBypassed', RESEED, 1);

		TRUNCATE TABLE dbo.mkObjectToEffectivePermGained
		--DBCC CHECKIDENT('mkObjectToEffectivePermGained	', RESEED, 1);

		TRUNCATE TABLE dbo.mkObjectToImpactType
		--DBCC CHECKIDENT('mkObjectToImpactType', RESEED, 1);

		TRUNCATE TABLE dbo.mkObjectToKillchain
		--DBCC CHECKIDENT('mkObjectToKillchain', RESEED, 1);

		TRUNCATE TABLE dbo.mkObjectToPermissionRequired
		--DBCC CHECKIDENT('mkObjectToPermissionRequired', RESEED, 1);

		TRUNCATE TABLE dbo.mkObjectToPlatform
		--DBCC CHECKIDENT('mkObjectToPermissionRequired', RESEED, 1);

		TRUNCATE TABLE dbo.mkObjectToSystemRequirement
		--DBCC CHECKIDENT('mkObjectToSystemRequirement', RESEED, 1);

		TRUNCATE TABLE dbo.mkPermissionRequired
		DBCC CHECKIDENT('mkPermissionRequired', RESEED, 1);

		TRUNCATE TABLE dbo.mkPlatform
		DBCC CHECKIDENT('mkPlatform', RESEED, 1);

		TRUNCATE TABLE dbo.mkRelationship
		DBCC CHECKIDENT('mkRelationship', RESEED, 1);

		TRUNCATE TABLE dbo.mkRootObject
		--DBCC CHECKIDENT('mkRootObject', RESEED, 1);

		TRUNCATE TABLE dbo.mkSection
		DBCC CHECKIDENT('mkSection', RESEED, 1);

		TRUNCATE TABLE dbo.mkSystemRequirements
		DBCC CHECKIDENT('mkSystemRequirements', RESEED, 1);

		TRUNCATE TABLE dbo.mkType
		DBCC CHECKIDENT('mkType', RESEED, 1);


		--> Show results
		IF @ShowComments = 1
			SELECT '-->' [Delete/Truncate - Complete];

	END
GO
--> ###############################################################################
--> ###############################################################################
--> Analysis procs
--> ###############################################################################
GO
------------------------------------------------------------------------------
------------------------------------------------------------------------------
GO
/* =============================================
	Author:		Marko Kennedy
	Create date: Nov 2021
	Description:	Analyse Malware

|256		--> Objects per year with [@objTypeId] - Was the object used during the year [Y|N]
|512		--> Malware useage [Counts] by year, with [@top]
|1024		--> Malware, use of techniques, with [@top]
|2048		--> Store/View most used {Malware|Tools}, with [three [mu*] variables below]
					
|128		--> EXEC [usp_Mitre_RunAnalysis] to repopulate ALL of {[aMostUsedObjects], [aMalwareAndTools_AnnualAnalysis], [AnnualRelations]}

--> Below are largely experimentation
|4096		--> Seems 2BA pre-cursor to my script [2021 08 - extract for reports]?					
|64		--> Seems 2B experiments to develop [usp_Mitre_MostUsedObjects_Associations]
|32		--> Experiment to find Mitigations v. (all) Effective Permissions Gained	
|16		--> Experiments to examine [aMaT_AnnualRelations]. Creates various CSV files, a precursor to my script [2021 08 - extract for reports]

============================================= */
CREATE OR ALTER PROCEDURE [dbo].[usp_Mitre_Analysis_101_Malware] 
(
	@ACTION			INT,
	@objTypeId		INT = 2,			--> With [@ACTION = 256]  [SELECT * FROM mkType]; 1:Technique, 2:CoA, 4:Group, 5:Malware, 8:Tool, 11:Sub-Technique
	@top			INT = 30,			--> Display the TOP(@top) rows

	@muComboPk		INT = 1,			--> Pk from [aMostUsedCombinations] to seed most-used SAVE/SELECT [SELECT * FROM dbo.aMostUsedCombinations c]
	@muDoUpdate		BIT = 0,			--> Update [aMostUsedObjects] 
	@muTop			INT = 0				--> Non-zero value overrides the [Top] value of the specified search
	)
AS
BEGIN

	BEGIN	--> Inits
	
		DECLARE
		@TargetTypeId		INT = 0, 
		@SourceTypeId		INT = 0,
		@legend				VARCHAR (200),

		@typeName			VARCHAR(50),

		--> SELECT * FROM mkType
		@techniqueTypeId	INT = 1,
		@mitigationTypeId	INT = 2,
		@groupTypeId		INT = 4,
		@malwareTypeId		INT = 5,
		@relationshipTypeId	INT = 7,
		@toolTypeId			INT = 8,
		@tacticTypeId		INT = 10,
		@subTechniqueTypeId	INT = 11,

		@relUses			VARCHAR(30)					= 'uses',
		@relMitigates		VARCHAR(30)					= 'mitigates',
		@relSubTechnique	VARCHAR(30)					= 'subtechnique-of',

		@malwareByYear		dbo.ObjectUsePerYear,
		@objectUseByYear	dbo.ObjectUsePerYear,
		@groupsByYear		dbo.ObjectUsePerYear

		SELECT @typeName = ISNULL(t.LocalName, t.tName) FROM dbo.mkType t WHERE t.tId = @objTypeId;
	END		--> Inits

	--> #################################################################
	IF @ACTION & 256 > 0
	BEGIN	--> Objects per year

		DELETE @objectUseByYear; 

		SELECT @ACTION [Action], t.LocalName  [Object Type], 'Show object use [Y|N] by year' [Comment] 
		FROM dbo.mkType t WHERE t.tId = @objTypeId 

		--> Store results in local variable, calling our function to extract this data.
		INSERT @objectUseByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
		SELECT Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021]
		FROM dbo.fnGetObjectUsePerYear (@objTypeId);

		--> Display results
		SELECT 
			--@typeName + ' ->' [Object],	
			mo.objName [Object Name], 
			ou.ObjPkMax, ou.RootPk, 
			[2018], [2019], [2020], [2021], 
			mo.objDescription [Description]
		FROM @objectUseByYear ou
		INNER JOIN mkObject mo ON mo.[objId] = ou.ObjPkMax
		ORDER BY 
			--[2018] DESC, [2019] DESC, [2020] DESC, [2021] DESC, 
			[2018] ASC, [2019] ASC, [2020] ASC, [2021] ASC, 
			mo.objName;

	END		--> Objects per year

	--> #################################################################
	IF @ACTION & 512 > 0
	BEGIN	--> Malware useage by year

		DELETE @malwareByYear
		DECLARE @malCount INT;

		INSERT @malwareByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
		SELECT Pk, ObjPkMax ObjPk, RootPk, ObjTypeId, [2018], [2019], [2020], [2021]
		FROM dbo.fnGetObjectUsePerYear (@malwareTypeId);

		SELECT @malCount = COUNT(*) FROM @malwareByYear

		SELECT @ACTION [Action], @top [Top N], 'Malware usage [Count] by year' [Comment], @malCount [Malware Count]

		--SELECT * FROM dbo.mkType t WHERE t.tId = @objTypeId 
		SELECT TOP(@top)
			mo.objName [Name],
			ISNULL([2018], 0) [2018],
			ISNULL([2019], 0) [2019], 
			ISNULL([2020], 0) [2020], 
			ISNULL([2021], 0) [2021]
			,
			PT.ObjPkMax,
			PT.RootPk
		FROM (
			SELECT mb.ObjPkMax, mb.RootPk, mo.objYear Yr, COUNT(r.relId) YrCount 
			FROM @malwareByYear mb
			LEFT JOIN dbo.mkRelationship r ON r.relTargetRef = mb.RootPk
			LEFT JOIN dbo.mkObject mo ON mo.[objId] = r.relMkObjPk
			GROUP BY mb.ObjPkMax, mb.RootPk, mo.objYear
		) Src
		PIVOT (
			MAX(YrCount) FOR Yr IN ([2018],[2019],[2020],[2021])
		) PT
		INNER JOIN mkObject mo ON mo.[objId] = PT.ObjPkMax
		ORDER BY 
			--[2018] DESC, [2019] DESC, [2020] DESC, [2021] DESC 
			--[2018] ASC, [2019] ASC, [2020] ASC, [2021] ASC 
			[2021] DESC, [2020] DESC, [2019] DESC,[2018] DESC 
			, [Name];

	END

	--> #################################################################
	IF @ACTION & 1024 > 0
	BEGIN	--> Malware, use of techniques

		IF 1=0 SELECT * FROM dbo.mkType t --WHERE t.tId = @typeId
		IF 1=0 SELECT * FROM vwKillChainPhases

		DELETE @malwareByYear;
		DELETE @groupsByYear;

		DECLARE
		@mostUsedMwByYear		dbo.ObjectCountPerYear
	
		INSERT @malwareByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
		SELECT Pk, ObjPkMax ObjPk, RootPk, ObjTypeId, [2018], [2019], [2020], [2021]
		FROM dbo.fnGetObjectUsePerYear (@malwareTypeId);

		INSERT @groupsByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
		SELECT Pk, ObjPkMax ObjPk, RootPk, ObjTypeId, [2018], [2019], [2020], [2021]
		FROM dbo.fnGetObjectUsePerYear (@groupTypeId);

		DECLARE 
		@malwareCount	INT	 = (SELECT COUNT(*) FROM @malwareByYear),
		@groupCount		INT	 = (SELECT COUNT(*) FROM @groupsByYear)

		SELECT @ACTION [Action], @top [Top N], 'Three recordsets' [Comment], 	
			'# of Techniques/Malware' [RS1], 
			'# of Groups / Malware' [RS2] , 
			'# of Malware / Group' [RS3],
			@malwareCount MalwareCount, @groupCount GroupCount
	
		--> #################################################################
		--> RS1: Number of techniques used by each Malware, across years.
		--> #################################################################
		IF 1=1
			SELECT TOP(@top)
				'RS1' [RS1],
				PT.Pk, mo.objName [Name], 	 
				CASE WHEN PT.[2018] IS NULL THEN 0 ELSE PT.[2018] END [2018],
				CASE WHEN PT.[2019] IS NULL THEN 0 ELSE PT.[2019] END [2019],
				CASE WHEN PT.[2020] IS NULL THEN 0 ELSE PT.[2020] END [2020],
				CASE WHEN PT.[2021] IS NULL THEN 0 ELSE PT.[2021] END [2021]
				--,mo.objDescription [Description]
				,m.ObjPkMax, m.RootPk
			FROM (
				SELECT m.Pk, r.relYear RelYr, COUNT(r.relId) TechniqueCount
				FROM @malwareByYear m
				INNER JOIN mkRelationship r ON r.relSourceRef = m.RootPk
					AND r.relType = @relUses
				GROUP BY m.Pk, r.relYear
			) Src
			PIVOT (
				MAX(TechniqueCount) FOR RelYr IN ([2018],[2019],[2020],[2021])
			) PT
			INNER JOIN @malwareByYear m ON m.Pk = PT.Pk
			INNER JOIN mkObject mo ON mo.[objId] = m.ObjPkMax
			ORDER BY 
				PT.[2021] DESC, PT.[2020] DESC, PT.[2019] DESC, PT.[2018] DESC,
				mo.objName;
		ELSE
			SELECT 'RS1 Suppressed' [RS1]
	
		--> #################################################################
		--> RS2: Number of APTs using a malware, across years
		--> #################################################################
		IF 1=1
		BEGIN
			INSERT @mostUsedMwByYear (Pk, ObjPkMax, RootPk, ObjTypeId, [2018], [2019], [2020], [2021])
			SELECT TOP(@top)
				PT.Pk, m.ObjPkMax, m.RootPk, @malwareTypeId TypeId, 	 
				CASE WHEN PT.[2018] IS NULL THEN 0 ELSE PT.[2018] END [2018],
				CASE WHEN PT.[2019] IS NULL THEN 0 ELSE PT.[2019] END [2019],
				CASE WHEN PT.[2020] IS NULL THEN 0 ELSE PT.[2020] END [2020],
				CASE WHEN PT.[2021] IS NULL THEN 0 ELSE PT.[2021] END [2021]	
			FROM (
				SELECT m.Pk, r.relYear RelYr, COUNT(r.relId) RelCount
				FROM @malwareByYear m
				INNER JOIN mkRelationship r ON r.relTargetRef = m.RootPk
					AND r.relType = @relUses
				INNER JOIN @groupsByYear g ON g.RootPk = r.relSourceRef
				GROUP BY m.Pk, r.relYear
			) Src
			PIVOT (
				MAX(RelCount) FOR RelYr IN ([2018],[2019],[2020],[2021])
			) PT
			INNER JOIN @malwareByYear m ON m.Pk = PT.Pk
			INNER JOIN mkObject mo ON mo.[objId] = m.ObjPkMax
			ORDER BY 
				PT.[2021] DESC, PT.[2020] DESC, PT.[2019] DESC, PT.[2018] DESC,
				mo.objName;

			SELECT 
				'RS2' [RS2],
				mx.Pk, mo.objName [Name], 	 
				mx.[2018], mx.[2019], mx.[2020], mx.[2021]
				--,mo.objDescription [Description]
				,m.ObjPkMax, m.RootPk
			FROM @mostUsedMwByYear mx
			INNER JOIN @malwareByYear m ON m.Pk = mx.Pk
			INNER JOIN mkObject mo ON mo.[objId] = m.ObjPkMax
			ORDER BY 
				mx.[2021] DESC, mx.[2020] DESC, mx.[2019] DESC, mx.[2018] DESC,
				mo.objName;
		END
		ELSE
			SELECT 'RS2 Suppressed' [RS2]

		--> #################################################################
		--> RS3: Number of malwares used by each APT, across years
		--> #################################################################
		IF 1=1
			SELECT TOP(@top)
				'RS3' [RS3],
				PT.Pk, mo.objName [Name], 	 
				CASE WHEN PT.[2018] IS NULL THEN 0 ELSE PT.[2018] END [2018],
				CASE WHEN PT.[2019] IS NULL THEN 0 ELSE PT.[2019] END [2019],
				CASE WHEN PT.[2020] IS NULL THEN 0 ELSE PT.[2020] END [2020],
				CASE WHEN PT.[2021] IS NULL THEN 0 ELSE PT.[2021] END [2021]
				,mo.objDescription [Description]
				,g.ObjPkMax, g.RootPk
			FROM (
				SELECT g.Pk, r.relYear RelYr, COUNT(r.relId) RelCount
				FROM @groupsByYear g
				INNER JOIN mkRelationship r ON r.relSourceRef = g.RootPk
					AND r.relType = @relUses
				INNER JOIN @malwareByYear m ON m.RootPk = r.relTargetRef
				GROUP BY g.Pk, r.relYear
			) Src
			PIVOT (
				MAX(RelCount) FOR RelYr IN ([2018],[2019],[2020],[2021])
			) PT
			INNER JOIN @groupsByYear g ON g.Pk = PT.Pk
			INNER JOIN mkObject mo ON mo.[objId] = g.ObjPkMax
			ORDER BY 
				PT.[2021] DESC, PT.[2020] DESC, PT.[2019] DESC, PT.[2018] DESC,
				mo.objName;
		ELSE
			SELECT 'RS3 Suppressed' [RS3]

	END		--> --> Malware, use of techniques

	--> #################################################################
	IF @ACTION & 2048 > 0 
	BEGIN	--> Store/View most used {Malware|Tools}

		SELECT 
			@legend			= c.Detail, 
			@TargetTypeId	= c.TargetTypeId,
			@SourceTypeId	= c.SourceTypeId
		FROM dbo.aMostUsedCombinations c WHERE c.Pk = @muComboPk;
	
		--> Store underlying data
		IF @muDoUpdate = 1 
		BEGIN
			EXEC dbo.usp_Mitre_MostUsedObjects @MuComboPk = @muComboPk, @Top = @muTop;
		END
		ELSE
		BEGIN
			SELECT '=>' [MU Data Search], * FROM dbo.aMostUsedCombinations c WHERE c.Pk = @muComboPk;
		END

		IF @legend IS NOT NULL
		SELECT @legend [MU], @top [Top N],
			mu.OrderId, mo.objName [Name],
			[2018], [2019], [2020], [2021],
			mo.objDescription [Description]
			, mu.ObjPkMax, mu.ObjRootPk, mu.ObjTypeId, mu.ByTypeId
		FROM dbo.aMostUsedObjects mu
		INNER JOIN dbo.mkObject mo ON mo.[objId] = mu.ObjPkMax
		WHERE mu.ObjTypeId = @TargetTypeId
		AND mu.ByTypeId = @SourceTypeId;

	END		--> Store/View most used {Malware|Tools}

	--> #################################################################
	IF @ACTION & 128 > 0 
	BEGIN	--> Repopulate all the most-used values

		EXEC [dbo].[usp_Mitre_RunAnalysis] @TopMu = @muTop;

	END		--> Repopulate all the most-used values

END

GO
------------------------------------------------------------------------------
------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE [dbo].[usp_Mitre_Analysis_102_Top_N] 
(
	@ACTION				INT = 0,			--> 
	@Top_Techniques		INT = 10,			--> Select the top [N] most used Techniques
	@Top_DataSources	INT = 1,			--> Filter where TechCount >= @Top_DataSources
	@LAST_2YRS			INT = 2				--> 0:2018, 1:2021, 2:Just 2020/21, 4:ALL
)
AS
BEGIN

	BEGIN	--> Get seed data

		BEGIN
		DECLARE
		@filter	VARCHAR(100) = CASE WHEN @LAST_2YRS = 0 THEN 'TT 2018'
									WHEN @LAST_2YRS = 1 THEN 'TT 2021'
									WHEN @LAST_2YRS = 2 THEN 'TT 20/21'
									WHEN @LAST_2YRS = 4 THEN 'TT all'
									END;

		DECLARE @tgtYrs TABLE (yr INT)

		IF 1=0	SELECT '==>' [Showing], @Top_Techniques [@Top_Techniques], @filter [Filter]

		DECLARE
		@yr2021 INT = 2021

		DECLARE @temp1 TABLE (
			Pk				INT IDENTITY(1,1),
			RootId			VARCHAR(100),
			TechRoot		VARCHAR(100),
			Technique		NVARCHAR(500),
			TechType		VARCHAR(30),
			TechTypeId		INT,
			Rank18			INT,
			Rank19			INT,
			Rank20			INT,
			Rank21			INT,
			[2018]			INT,
			[2019]			INT,
			[2020]			INT,
			[2021]			INT
		);

		IF OBJECT_ID('tempdb..#topTechniques') IS NOT NULL DROP TABLE #topTechniques
		CREATE TABLE #topTechniques (
			Pk				INT IDENTITY(1,1),
			BitMask			INT,
			Fk				INT,
			RootId			VARCHAR(100),
			MaxObjPk		INT,
			Technique		NVARCHAR(500),
			TechType		VARCHAR(30),
			TechTypeId		INT,
			Rank18			INT,
			Rank19			INT,
			Rank20			INT,
			Rank21			INT,
			[2018]			INT,
			[2019]			INT,
			[2020]			INT,
			[2021]			INT
		)

		DECLARE @mitigationsYr TABLE (
			CoA_Pk				INT,
			CoA_RootPk			VARCHAR(100),
			[Rank]				INT,

			CoA					VARCHAR(100),	--> Name of the CoA
		
			[2018]				INT,			--> 
			[2019]				INT,			--> 
			[2020]				INT,			--> 
			[2021]				INT,			-->

			KC_Count			INT,			--> Count of killchains
			KC_Masks			INT,			--> The collection of KC Masks for this CoA
			KC_Pks				VARCHAR(MAX),	--> String of KC Pks 
			TtlTechs			INT				--> The total number of Techniques that this CoA affects in 2021
		);

		END 

		--> Get all techniques
		INSERT @temp1 (TechRoot, Technique, TechType, TechTypeId, [2018], [2019], [2020], [2021])
		SELECT 
			P.TechRoot, mo.objName Technique, t.LocalName [Type], t.tId TypeId, 
			ISNULL(p.[2018], 0) [2018], ISNULL(p.[2019], 0) [2019], ISNULL(p.[2020], 0) [2020], ISNULL(p.[2021], 0) [2021]
		FROM (
			SELECT r.relYear Yr, r.relTargetRef TechRoot, COUNT(*) ItemCount
				--TOP 100 r.*
			FROM dbo.mkRelationship r
			INNER JOIN dbo.mkObject mos ON mos.objRootObjPk = r.relSourceRef
				AND mos.objYear = r.relYear
				AND r.relType = 'uses'
				AND r.relTargetRef LIKE 'attack-pattern%'
				AND (mos.objDeprecated = 0 AND mos.objRevoked = 0)
			INNER JOIN dbo.mkObject mot ON mot.objRootObjPk = r.relTargetRef
				AND mot.objYear = r.relYear
				AND r.relType = 'uses'
				AND r.relTargetRef LIKE 'attack-pattern%'
				AND (mot.objDeprecated = 0 AND mot.objRevoked = 0)
			--WHERE r.relTargetRef IN (
			--	'attack-pattern--7385dfaf-6886-4229-9ecd-6fd678040830',
			--	'attack-pattern--d1fcf083-a721-4223-aedf-bf8960798d62'
			--	--,'attack-pattern--92d7da27-2d91-488e-a00c-059dc162766d'
			--)
			GROUP BY  r.relYear, r.relTargetRef
		--ORDER BY  r.relYear, mos.objRootObjPk
		) S
		PIVOT (
			SUM(S.ItemCount) FOR Yr IN ([2018], [2019], [2020], [2021])
		) P
		INNER JOIN dbo.mkRootObject ro ON ro.roPk = P.TechRoot
		INNER JOIN dbo.mkType t ON t.tId = ro.roTypeId
		INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
			AND (mo.objDeprecated = 0 OR mo.objRevoked = 0)
		--WHERE [2018] = 0 AND [2019] = 0
		ORDER BY [2021] DESC, [2020] DESC, [2019] DESC, [2018] DESC

		--> If type of the Technique is "Technique" and not "Subtechnique", it is its own parent
		UPDATE @temp1 SET RootId = TechRoot WHERE TechTypeId = 1

		--> Find parent of sub-techniques
		MERGE @temp1 x
		USING (
			SELECT x.Pk, r.relTargetRef RootId
			FROM @temp1 x
			INNER JOIN dbo.mkRelationship r ON r.relSourceRef = x.TechRoot
				AND r.relType = 'subtechnique-of'
				AND r.relYear = 2021
		) S ON S.Pk = x.Pk
		WHEN MATCHED THEN UPDATE SET x.RootId = S.RootId;

		--> Remove any that are marked as deprecated or revoked
		MERGE @temp1 x
		USING (
			SELECT x.Pk
			FROM @temp1 x
			INNER JOIN dbo.mkRootObject ro ON ro.roPk = x.RootId
			INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
				AND (mo.objDeprecated = 1 OR mo.objRevoked = 1)
		) S ON S.Pk = x.PK
		WHEN MATCHED THEN DELETE;

		--> Get the new annual values for '20 & '21 for all sub-techniques
		MERGE @temp1 x
		USING (
			SELECT RootId, SUM([2020]) [2020], SUM([2021]) [2021]
			FROM @temp1 x
			WHERE TechType = 'Subtechnique'
			GROUP BY RootId
		) S ON S.RootId = x.RootId AND x.TechTypeId = 1
		WHEN MATCHED THEN UPDATE SET x.[2020] = S.[2020], x.[2021] = S.[2021];

		--> Remove all sub-techniques
		IF 1=1 DELETE FROM @temp1 WHERE TechTypeId = 11;

		--SELECT * FROM @temp1

		--> Set Rank18 - Rank21
		BEGIN
			MERGE @temp1 x
				USING (
				SELECT 
					x.Pk, ROW_NUMBER() OVER (ORDER BY x.[2018] DESC) R18
					--x.Pk, ROW_NUMBER() OVER (ORDER BY x.[2018] DESC, x.[2019] DESC, x.[2020] DESC, x.[2021] DESC) R18
				FROM @temp1 x
			) S ON S.Pk = x.PK
			WHEN MATCHED THEN UPDATE SET x.Rank18 = S.R18;

			MERGE @temp1 x
				USING (
				SELECT 
					x.Pk, ROW_NUMBER() OVER (ORDER BY x.[2019] DESC) R19
				FROM @temp1 x
			) S ON S.Pk = x.PK
			WHEN MATCHED THEN UPDATE SET x.Rank19 = S.R19;

			MERGE @temp1 x
				USING (
				SELECT 
					x.Pk, ROW_NUMBER() OVER (ORDER BY x.[2020] DESC) R20
				FROM @temp1 x
			) S ON S.Pk = x.PK
			WHEN MATCHED THEN UPDATE SET x.Rank20 = S.R20;

			MERGE @temp1 x
				USING (
				SELECT 
					x.Pk, ROW_NUMBER() OVER (ORDER BY x.[2021] DESC) R21
					--x.Pk, ROW_NUMBER() OVER (ORDER BY x.[2021] DESC, x.[2020] DESC, x.[2019] DESC, x.[2018] DESC) R21
				FROM @temp1 x
			) S ON S.Pk = x.PK
			WHEN MATCHED THEN UPDATE SET x.Rank21 = S.R21;

		END

		--> For items not used in 2018 and 2019, set their Ranks to the lowest Rank value in that category
		DECLARE @maxRank18 INT		--> min Rank18 where 2018 value = 0
		SELECT @maxRank18 = MIN(x.Rank18) FROM @temp1 x WHERE x.[2018] = 0
		UPDATE @temp1 SET Rank18 = @maxRank18 WHERE [2018] = 0

		--> @LAST_2YRS {0:2018, 1:2021, 2:Just 2020/21, 4:ALL}
		IF @LAST_2YRS = 0
		BEGIN
			INSERT #topTechniques (Fk, RootId, Technique, TechType, TechTypeId, 
					Rank18, Rank19, Rank20, Rank21, 
					[2018], [2019], [2020], [2021])
			SELECT TOP (@Top_Techniques) x.Pk, x.RootId, x.Technique, x.TechType, x.TechTypeId,
					x.Rank18, x.Rank19, x.Rank20, x.Rank21, 
					x.[2018], x.[2019], x.[2020], x.[2021]
			FROM @temp1 x
			ORDER BY x.Rank18	
		
			INSERT @tgtYrs (Yr)
			VALUES(2018)
		END
		ELSE IF @LAST_2YRS = 1
		BEGIN
			INSERT #topTechniques (Fk, RootId, Technique, TechType, TechTypeId, 
					Rank18, Rank19, Rank20, Rank21, 
					[2018], [2019], [2020], [2021])
			SELECT TOP (@Top_Techniques) x.Pk, x.RootId, x.Technique, x.TechType, x.TechTypeId,
					x.Rank18, x.Rank19, x.Rank20, x.Rank21, 
					x.[2018], x.[2019], x.[2020], x.[2021]
			FROM @temp1 x
			ORDER BY x.Rank21	
		
			INSERT @tgtYrs (Yr)
			VALUES(2021)
		END
		ELSE IF @LAST_2YRS = 2
		BEGIN
			INSERT #topTechniques (Fk, RootId, Technique, TechType, TechTypeId, 
					Rank18, Rank19, Rank20, Rank21, 
					[2018], [2019], [2020], [2021])
			SELECT TOP (@Top_Techniques) x.Pk, x.RootId, x.Technique, x.TechType, x.TechTypeId,
					x.Rank18, x.Rank19, x.Rank20, x.Rank21, 
					x.[2018], x.[2019], x.[2020], x.[2021]
			FROM @temp1 x
			WHERE x.[2018] = 0 AND x.[2019] = 0
			ORDER BY x.Rank21	
		
			INSERT @tgtYrs (Yr)
			VALUES (2020), (2021)
		END
		ELSE IF @LAST_2YRS = 4
		BEGIN
			INSERT #topTechniques (Fk, RootId, Technique, TechType, TechTypeId, 
					Rank18, Rank19, Rank20, Rank21, 
					[2018], [2019], [2020], [2021])
			SELECT x.Pk, x.RootId, x.Technique, x.TechType, x.TechTypeId,
					x.Rank18, x.Rank19, x.Rank20, x.Rank21, 
					x.[2018], x.[2019], x.[2020], x.[2021]
			FROM @temp1 x
			ORDER BY x.Rank21, x.[2020], x.[2019], x.[2018]
		
			INSERT @tgtYrs (Yr)
			VALUES(2018), (2019), (2020), (2021)
		END

		--DECLARE @p			FLOAT = 2
		--UPDATE #topTechniques SET BitMask = POWER(@p, (Pk-1));

	END		---> Get Data

	
	IF @ACTION & 1 > 0
	BEGIN	--> Killchain (Techniques)

			SELECT 'Distribution of Techniques over Killchain' [Comment], @Top_Techniques [Top N];

			SELECT @filter [Filter], P.KcOrd, P.Killchain, 
			ISNULL(P.[2018], 0) [2018], ISNULL(P.[2019], 0) [2019], ISNULL(P.[2020], 0) [2020], ISNULL(P.[2021], 0) [2021]
			FROM (
				SELECT kp.kcOrder KcOrd, kp.kcName Killchain, r.relYear Yr, COUNT(*) KcCount
				FROM #topTechniques x
				INNER JOIN dbo.mkRelationship r ON r.relTargetRef = x.RootId
					AND r.relType = 'mitigates'
				INNER JOIN dbo.mkObject t ON t.objRootObjPk = r.relTargetRef
					AND t.objYear = r.relYear
				INNER JOIN dbo.mkObjectToKillchain ok ON ok.okObjectId = t.[objId]
				INNER JOIN dbo.mkKillchainPhases kp ON kp.kcPk = ok.okKillchainId
				GROUP BY kp.kcOrder, kp.kcName, r.relYear
			 ) S
			 PIVOT (
				SUM(KcCount) FOR Yr IN ([2018], [2019], [2020], [2021])
			 ) P
			 WHERE P.KcOrd > 3 AND P.KcOrd < 14
			 ORDER BY P.KcOrd

	END		--> Killchain (Techniques)

	IF @ACTION & 2 > 0
	BEGIN	--> Malware and Tool use of Top N Techniques
	
		SELECT 'Top N usage by X' [Comment], @Top_Techniques [Top N], @filter [Filter];

		SELECT @Top_Techniques [Top N], @filter [Filter],
			[Item], 
			ISNULL(P.[2018], 0) [2018], ISNULL(P.[2019], 0) [2019], ISNULL(P.[2020], 0) [2020], ISNULL(P.[2021], 0) [2021]
		FROM (
			SELECT t.LocalName [Item], t.tId, r.relYear Yr, COUNT(*) [Usage]
			FROM #topTechniques tx 
			INNER JOIN dbo.mkRelationship r ON r.relTargetRef = tx.RootId
				AND r.relType = 'uses'
				--AND (r.relSourceRef LIKE 'malware%' OR r.relSourceRef LIKE 'tool%')
			INNER JOIN dbo.mkObject mal ON mal.objRootObjPk = r.relSourceRef
				AND mal.objYear = r.relYear
				AND mal.objDeprecated = 0
				AND mal.objRevoked = 0
			INNER JOIN dbo.mkRootObject ro ON ro.roPk = r.relSourceRef
			INNER JOIN dbo.mkType t ON t.tId = ro.roTypeId
			GROUP BY t.LocalName, t.tId, r.relYear
		) S
		PIVOT (
			SUM(Usage) FOR Yr IN ([2018], [2019], [2020], [2021])
		) P


	END	--> Malware and Tool use of Top N Techniques

	IF @ACTION & 4 > 0
	BEGIN	--> Mitigations

		BEGIN	--> Get all mits first	

			DECLARE @allMits TABLE (
				MitRoot		VARCHAR(100),
				[2018]		INT,
				[2019]		INT,
				[2020]		INT,
				[2021]		INT,

				Rank19		INT,
				Rank21		INT
			);

			INSERT @allMits (MitRoot, [2018], [2019], [2020], [2021])
			SELECT P.MitRoot,
				ISNULL(P.[2018], 0) [2018], ISNULL(P.[2019], 0) [2019], ISNULL(P.[2020], 0) [2020], ISNULL(P.[2021], 0) [2021]
			FROM (
				SELECT r.relSourceRef MitRoot, r.relYear Yr, COUNT(*) TechCount
				FROM dbo.mkRelationship r
				INNER JOIN dbo.mkObject mit ON mit.objRootObjPk = r.relSourceRef
					AND r.relType = 'mitigates'
					AND r.relYear = mit.objYear
					AND mit.objDeprecated =	0
					AND mit.objRevoked = 0
				GROUP BY r.relSourceRef, r.relYear
			)S 
			PIVOT (
				SUM(S.TechCount) FOR S.Yr IN ([2018], [2019], [2020], [2021])
			) P;

			MERGE @allMits mx
			USING (
				SELECT 
					mx.MitRoot, ROW_NUMBER() OVER(ORDER BY mx.[2019] DESC, mx.[2020] DESC, mx.[2021] DESC) Rnk
				FROM @allMits mx
			) S ON S.MitRoot = mx.MitRoot
			WHEN MATCHED THEN UPDATE SET mx.Rank19 = S.Rnk;

			MERGE @allMits mx
			USING (
				SELECT 
					mx.MitRoot, ROW_NUMBER() OVER(ORDER BY mx.[2021] DESC, mx.[2020] DESC, mx.[2019] DESC) Rnk
				FROM @allMits mx
			) S ON S.MitRoot = mx.MitRoot
			WHEN MATCHED THEN UPDATE SET mx.Rank21 = S.Rnk;		

			IF 1=1
			SELECT COUNT(*) [MitCount ALL] FROM @allMits mx;

			IF 1=1
			SELECT --TOP(@Top_Techniques)
				@filter [All Mits],
				CASE 
					WHEN @LAST_2YRS = 0			THEN mx.Rank19 
					WHEN @LAST_2YRS IN (1,2)	THEN mx.Rank21 
				END as [Rank],
					mo.objName Mitigation, 
					mx.Rank19, mx.Rank21, 
					mx.[2018], mx.[2019], mx.[2020], mx.[2021]
			FROM @allMits mx
			INNER JOIN dbo.mkRootObject ro ON ro.roPk = mx.MitRoot
			INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
			ORDER BY 
			CASE WHEN @LAST_2YRS = 0 THEN mx.Rank19 END,
			CASE WHEN @LAST_2YRS IN (1,2) THEN mx.Rank21 END

		END		--> Get all mits first

		DECLARE @mits TABLE (
			Pk			INT IDENTITY(1,1),
			RootId		VARCHAR(100),
			MitName		VARCHAR(100),
			RankAll		INT,
			RankTT		INT,

			Rank18		INT,
			Rank21		INT
		);


		--> Insert all Mitigations used against the Top 10 into @mits
		INSERT @mits (RootId, MitName)
		SELECT DISTINCT 
			r.relSourceRef MitRootId, mit.objName [Mit]
		FROM #topTechniques x
		INNER JOIN dbo.mkRelationship r ON r.relTargetRef = x.RootId
			AND r.relType = 'mitigates'
		INNER JOIN dbo.mkObject mit ON mit.objRootObjPk = r.relSourceRef
			AND mit.objYear = r.relYear
			AND mit.objDeprecated = 0 AND mit.objRevoked = 0
		INNER JOIN @tgtYrs yx ON r.relyear IN (yx.yr);

		IF 1=0
		SELECT mo.objName Mitigation, mx.* 
		FROM @allMits mx 
		INNER JOIN dbo.mkRootObject ro ON ro.roPk = mx.MitRoot
		INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
		--ORDER BY mx.Rank19
		ORDER BY mx.Rank21


		SELECT --TOP (@Top_Techniques)
			'Mit (' + @filter + ') ->' [Mits], --@Top_Techniques [Top N], 
			--> Order by the number of Top 10s covered
			CASE 
				WHEN @LAST_2YRS = 0			THEN ROW_NUMBER() OVER (ORDER BY P.[2018] DESC, P.[2019] DESC, P.[2020] DESC, P.[2021] DESC, mx.Rank19) 
				WHEN @LAST_2YRS IN (1,2)	THEN ROW_NUMBER() OVER (ORDER BY P.[2021] DESC, P.[2020] DESC, P.[2019] DESC, P.[2018] DESC, mx.Rank21) 
			END as [Rank],

			--> The Ranks of ALL mitigations in 2019 and 2021
			mx.Rank19, mx.Rank21,
			P.Mit,
			ISNULL(P.[2018], 0) [2018], ISNULL(P.[2019], 0) [2019], ISNULL(P.[2020], 0) [2020], ISNULL(P.[2021], 0) [2021]
			, momit.objDescription  [Details]
		FROM (
			SELECT --DISTINCT 
				mit.objName [Mit], r.relSourceRef MitRoot, mit.objYear Yr, COUNT(r.relTargetRef) TCount
			FROM #topTechniques x
			INNER JOIN dbo.mkRelationship r ON r.relTargetRef = x.RootId
				AND r.relType = 'mitigates'
			INNER JOIN dbo.mkObject mit ON mit.objRootObjPk = r.relSourceRef
				AND mit.objYear = r.relYear
				AND mit.objDeprecated = 0 AND mit.objRevoked = 0
			--INNER JOIN @tgtYrs yx ON r.relyear IN (yx.yr)
			GROUP BY mit.objName, r.relSourceRef, mit.objYear
		) S 
		PIVOT (
			SUM(S.TCount) FOR Yr IN ([2018], [2019], [2020], [2021])
		) P
		INNER JOIN @allMits mx ON mx.MitRoot = P.MitRoot
		INNER JOIN dbo.mkRootObject romit ON romit.roPk = P.MitRoot
		INNER JOIN dbo.mkObject momit ON momit.[objId] = romit.roMaxObjPk
		WHERE 1=1
			AND P.[2021] > 0

	END		--> Mitigations

	IF @ACTION & 8 > 0
	BEGIN	--> Extract IOCs

		BEGIN --> IOC inits

			--> All the DSs associated with #topTechniques
			IF OBJECT_ID('tempdb..#DataSources') IS NOT NULL
				DROP TABLE #DataSources
			CREATE TABLE #DataSources (
				Pk				INT IDENTITY(1,1), 
				DsPk			INT,
				TopNCount		INT,					--> The number of Top N Techniques associated with this Data Source
				BitMask			BIGINT,					--> A unique bit mask for this DS entry
				[DS_Source]		NVARCHAR(300),			--> The category of the DS, taken as the prefix
				DS_Component	NVARCHAR(200),
				TotalTechCount	INT,					--> Across 2021, the total Techniques associated with this DataSource.Component

				OptimalCount	INT	DEFAULT 0,			--> The number of times this DS is used in the optimum collection of DSs
				OptimumOrder	INT	DEFAULT 999,		--> The orderin which to optimally use these DSs (8 Oct, added)
				DsRank			INT DEFAULT 9999
			);

			--> Running table for use in WHILE loop
			IF OBJECT_ID('tempdb..#TechniquesDsTemp') IS NOT NULL
				DROP TABLE #TechniquesDsTemp
			CREATE TABLE #TechniquesDsTemp (
				Pk			INT IDENTITY(1,1),
				TechPk		INT,
				DsMask		BIGINT,			--> Mask of all DSs associated with this Technique
				OptimalDsPk	INT				--> ID of optimal DS used for this Technique
			);
				
			INSERT #DataSources (DsPk, DS_Source, DS_Component, TopNCount, TotalTechCount)
			SELECT R.DsPk, ds.dsSource, ds.dsComponent, R.DsTtlTs TT_Ttls, R.TtlDsCount All_Ttls
			FROM (
				SELECT S.DsPk, S.DsTtlTs, COUNT(DISTINCT ods.odsObjectId) TtlDsCount
				FROM (
					SELECT ods.odsDataSourceId DsPk, COUNT(ods.odsObjectId) DsTtlTs
					FROM #topTechniques tt 				
					INNER JOIN dbo.mkObject mo ON mo.objRootObjPk = tt.RootId
					INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsObjectId = mo.[objId]
					--WHERE dsx.Pk < 10
					GROUP BY ods.odsDataSourceId
				) S
				INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsDataSourceId = S.DsPk
				GROUP BY S.DsPk, S.DsTtlTs			--ORDER BY S.DsTtlTs DESC, TtlDsCount DESC;
			) R 
			INNER JOIN dbo.mkDataSource ds ON ds.dsPk = R.DsPk
			WHERE 1=1 AND
				-- ds.dsComponent NOT IN ('Command Execution', 'Network Traffic Content') AND	--> To intentionally exclude, say, complicated Data Sources
				LEN(ds.dsComponent) > 0							--> VIP, VIP, VIP
			--> VIP: since Data Sources changed in 2021, we only used the new ones, identified as those that have a dsComponent

			DECLARE @p DECIMAL(5,2) = 2
			UPDATE #DataSources SET BitMask = POWER(@p, (Pk-1));

			IF 1=0 SELECT '==>' [DS 499], * FROM #DataSources ds ORDER BY ds.TopNCount DESC, ds.TotalTechCount DESC

			--> This holds the results of our query (i.e. the optimal mix of Data Sources across the Top N Techniques)
			INSERT #TechniquesDsTemp (TechPk, DsMask)
			SELECT ro.roMaxObjPk TechPk, SUM(DISTINCT ds.BitMask) DsMask
			FROM #DataSources ds
			INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsDataSourceId = ds.DsPk
			INNER JOIN dbo.mkObject mo ON mo.[objId] = ods.odsObjectId
			INNER JOIN #topTechniques tt ON tt.RootId = mo.objRootObjPk
			INNER JOIN dbo.mkRootObject ro ON ro.roPk = tt.RootId
			WHERE tt.RootId IS NOT NULL
			GROUP BY ro.roMaxObjPk;

		END		--> IOC inits
		
		BEGIN	--> Work on Data Sources: Extract unique DSs; assign bitmasks to each

			IF 1=1	--> WE WANT THIS SECTION: Work on Data Sources
			BEGIN

				IF (OBJECT_ID('tempdb..#optimalDataSources')) IS NOT NULL DROP TABLE #optimalDataSources
				CREATE TABLE #optimalDataSources (
					Pk			INT IDENTITY(1,1),
					DsPk		INT,
					TechCount	INT,				--> Number of outstanding Techniques covered
					BitMask		BIGINT,				--> BitMask of this technique
					TtlTechs	INT				--> Total number of all Techniques covered by this DS
				);

				DECLARE @dsCountMax INT = 10, @break BIT = 0, @tDsPk INT, @tMinPk INT, @tMask INT, @loopCount INT = 1,
				@showLoopComments BIT = 0;

				--> Find the optimal collection of Data Sources that cover the collection of Top Techniques
				WHILE @loopCount < @dsCountMax AND @break = 0 AND EXISTS (SELECT 1 FROM #TechniquesDsTemp x WHERE x.OptimalDsPk IS NULL)
				BEGIN
					
					TRUNCATE TABLE #optimalDataSources
					SELECT @tMinPk = 0, @tMask = 0, @tDsPk = 0;

					INSERT #optimalDataSources (DsPk, TechCount, BitMask, TtlTechs)
					SELECT --'#]#]#]#]', 
						dsx.DsPk, S.TechCount, dsx.BitMask, dsx.TotalTechCount
					FROM #DataSources dsx 
					INNER JOIN (
						SELECT dsx.DsPk, COUNT(tdt.Pk) TechCount 
						FROM #DataSources dsx
						INNER JOIN #TechniquesDsTemp tdt ON tdt.DsMask & dsx.BitMask > 0
							AND tdt.OptimalDsPk IS NULL
						GROUP BY dsx.DsPk
					) S ON S.DsPk = dsx.DsPk
					ORDER BY S.TechCount DESC, dsx.TotalTechCount DESC;

					SELECT @tMinPk = MIN(o.Pk) FROM #optimalDataSources o;
					SELECT @tDsPk = o.DsPk, @tMask = o.BitMask FROM #optimalDataSources o WHERE o.Pk = @tMinPk;

					IF @showLoopComments = 1
						SELECT 
							CASE WHEN @tMinPk = o.Pk THEN '->' ELSE '' END [Loop], @loopCount [@loopCount], o.*
						FROM #optimalDataSources o
						--WHERE @tMinPk = o.Pk;

					UPDATE #TechniquesDsTemp SET OptimalDsPk = @tDsPk
					WHERE OptimalDsPk IS NULL
					AND @tMask & DsMask > 1;

					MERGE #DataSources xds
					USING (
						SELECT @tDsPk Pk, COUNT(tx.Pk) x
						FROM #TechniquesDsTemp tx
						WHERE tx.OptimalDsPk = @tDsPk
					) S ON S.Pk = xds.DsPk
					WHEN MATCHED THEN UPDATE SET OptimalCount = S.x, OptimumOrder = @loopCount;

					SELECT @loopCount += 1;

				END		--> WHILE

			END

			IF @showLoopComments = 1
			BEGIN
				SELECT 'FINAL' [FINAL], @loopCount-1 [@loopCount < ], @dsCountMax [@dsCountMax],  @break [@break = 0]-- (SELECT 1 FROM #TechniquesDsTemp x WHERE x.OptimalDsPk IS NULL)
				SELECT 'FINAL' [FINAL], *, x.DsMask & 2 FROM #TechniquesDsTemp x;
			END

			MERGE #DataSources dx
			USING(
				SELECT dx.Pk,
					ROW_NUMBER() OVER (ORDER BY dx.OptimumOrder, dx.TopNCount DESC, dx.TotalTechCount DESC) DsRank
					, dx.OptimumOrder, dx.TopNCount, dx.TotalTechCount
				FROM #DataSources dx
			) S ON S.Pk = dx.PK
			WHEN MATCHED THEN UPDATE SET dx.DsRank = S.DsRank;

		END		--> Work on Datasources

		IF 1=1
		BEGIN	--> Display Data Sources results	IF 1=0 
			BEGIN
				SELECT 'Reset filter in [dbo.aMkDataComponentDetails]' [Filter Reset]

				UPDATE dbo.aMkDataComponentDetails SET Dc_Rank = NULL;		

				MERGE dbo.aMkDataComponentDetails x
				USING (
					SELECT --'DS ->' [Data Sources], 
						--S.Pk, 
				
						S.DS_Component,
						ROW_NUMBER() OVER(ORDER BY S.OptimumOrder, S.TopNCount DESC, S.TotalTechCount DESC) [Rank]
					FROM (
						SELECT
							d.Pk, d.DsPk, d.TopNCount, d.BitMask, d.[DS_Source], d.DS_Component, d.OptimalCount, ISNULL(d.OptimumOrder, 999) OptimumOrder
							, d.TotalTechCount
						FROM #DataSources d 
						WHERE (@Top_DataSources = 0 OR d.TopNCount >= @Top_DataSources)
					) S
					--INNER JOIN dbo.mkDataSource ds ON ds.
				) S ON S.DS_Component = x.Data_Component
				WHEN MATCHED THEN UPDATE SET x.Dc_Rank = S.[Rank];
			END		

			SELECT 'RS1: All data sources' [Comment], @Top_Techniques [Top N], @filter [Filter];
			SELECT --'DS ->' [Data Sources], 
				S.DS_Component, --S.[DS_Source], 
				DsRank,
				--S.Pk, 
				S.TopNCount, S.TotalTechCount, S.BitMask, S.OptimalCount, 
				CASE WHEN OptimumOrder = 999 THEN 0 ELSE OptimumOrder END OptimumOrder
			FROM (
				SELECT
					d.Pk, d.TopNCount, d.TotalTechCount, d.BitMask, d.[DS_Source], d.DS_Component, d.OptimalCount, d.OptimumOrder OptimumOrder,
					d.DsRank
				FROM #DataSources d 
				WHERE (@Top_DataSources = 0 OR d.TopNCount >= @Top_DataSources)
			) S
			ORDER BY DsRank;

			SELECT 'RS2: DSs / Technique' [Comment], @Top_Techniques [Top N], @filter [Filter];

			SELECT tt.Rank18, mo.objName Technique, tt.Rank21, d.DS_Component, d.DS_Source, d.DsRank, d.TopNCount, d.TotalTechCount 
			FROM  #DataSources d 
			INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsDataSourceId = d.DsPk
			INNER JOIN dbo.mkRootObject ro ON ro.roMaxObjPk = ods.odsObjectId
			INNER JOIN #topTechniques tt ON tt.RootId = ro.roPk
			INNER JOIN dbo.mkObject mo ON mo.[objId] = ods.odsObjectId
			ORDER BY tt.[Rank21], d.DsRank


			--SELECT 'DS/Tech ->' [DS/Tech], 
			--	tx.[Rank] TechRank, tx.TechniquePk, mo.objName Technique, COUNT(ds.Pk) DsCount
			--FROM #Detections dx	
			--INNER JOIN #topTechniques tx ON tx.TechniquePk = dx.TechPk
			--LEFT JOIN #DataSources ds ON dx.Val = ds.DataSource
			--	AND (@Top_DataSources = 0 OR ds.TopNCount >= @Top_DataSources)
			--INNER JOIN dbo.mkObject mo ON mo.[objId] = dx.TechPk
			--GROUP BY tx.[Rank], mo.objName, tx.TechniquePk
			----HAVING COUNT(ds.Pk) = 0
			--ORDER BY 
			--	tx.[Rank]
			--	--DsCount DESC;
			
			--> For the top Techniques, these are the primary data sources used to detect them
			SELECT 'RS3: Optimum DS collection to cover the top Techniques' [Comment], @Top_Techniques [Top N], @filter [Filter];
			SELECT *
			FROM #DataSources ds
			WHERE ds.OptimalCount > 0
			ORDER BY ds.OptimalCount DESC;

			SELECT 'RS4: All Techniques covered by the Optimum DS collection' [Comment], @Top_Techniques [Top N], @filter [Filter];
			SELECT mo.objName Technique, tt.[Rank21], ds.*
			FROM #topTechniques tt
			INNER JOIN dbo.mkRootObject ro ON ro.roPk = tt.RootId
			INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsObjectId = ro.roMaxObjPk
			INNER JOIN #DataSources ds ON ds.DsPk = ods.odsDataSourceId
				AND ds.OptimumOrder > 0
			INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
			ORDER BY ds.OptimumOrder, tt.[Rank21] 

		END		--> Display DS results

	END	--> Extract IOCs
	--> ####################################################################################


	IF @ACTION & 64 > 0
	BEGIN

		SELECT mot.objName [Tech], mos.objName SubTechnique
			,mos.objDescription [Dets]
			--, r.relSourceRef, r.relYear Yr
		FROM dbo.mkRelationship r
		INNER JOIN dbo.mkRootObject rot ON rot.roPk = r.relTargetRef
		INNER JOIN dbo.mkObject mot ON mot.[objId] = rot.roMaxObjPk

		INNER JOIN dbo.mkRootObject ros ON ros.roPk = r.relSourceRef
		INNER JOIN dbo.mkObject mos ON mos.[objId] = ros.roMaxObjPk
		WHERE r.relTargetRef = 'attack-pattern--0a3ead4e-6d47-4ccb-854c-a6a4f9d96b22'
			AND r.relType = 'subtechnique-of'
			AND r.relYear IN (2021)
		ORDER BY mos.objName


		SELECT 'Tech ->' [Techs],
			tx.Pk [Rank],
			tx.Rank18, tx.Rank21,
			tx.Technique, tx.RootId, 
			tx.[2018], tx.[2019], tx.[2020], tx.[2021]
			, kp.kcName [KCP], mot.objDescription [Description]	
		FROM #topTechniques tx
		INNER JOIN dbo.mkRootObject ro ON ro.roPk = tx.RootId
		INNER JOIN dbo.mkObject mot ON mot.[objId] = ro.roMaxObjPk
		INNER JOIN dbo.mkObjectToKillchain kc ON kc.okObjectId = mot.[objId]
		INNER JOIN dbo.mkKillchainPhases kp ON kp.kcPk = kc.okKillchainId

		SELECT TOP(@Top_Techniques) '18-20' [Top N], 
			x.Rank18, 
			--x.Rank19, x.Rank20, 
			x.Rank21, x.Rank21 - x.Rank18 [Mover],
			x.Technique, --x.TechType, 
			x.[2018], x.[2019], x.[2020], x.[2021]
		FROM @temp1 x
		ORDER BY x.Rank18
			--, x.Rank19, x.Rank20 
			--,x.Rank21

		SELECT '20/21' [Top N], 
			S.Rank18, 
			--x.Rank19, x.Rank20, 
			S.Rank21, S.Rank21 - S.Rank18 [Mover],
			S.Technique, --S.TechType, 
			S.[2018], S.[2019], S.[2020], S.[2021]
		FROM (
			SELECT TOP(@Top_Techniques)  
				x.[2018], x.[2019], x.[2020], x.[2021],
				x.Technique, x.TechType, 
				x.Rank18, 
				--x.Rank19, x.Rank20, 
				x.Rank21, x.Rank21 - x.Rank18 [Mover]
			FROM @temp1 x
			ORDER BY x.Rank21
		) S
		ORDER BY S.Rank21 

		SELECT TOP(@Top_Techniques) '20/21 - ONLY' [Top N], 
			x.Rank21,
			--x.[2018], x.[2019], 
			x.Technique, 
			x.[2020], x.[2021]
		FROM @temp1 x
		WHERE x.[2018] = 0 AND x.[2019] = 0
		ORDER BY x.Rank21

	END

END

GO
------------------------------------------------------------------------------
------------------------------------------------------------------------------
GO
/* ===========================================
	Author:			Marko Kennedy
	Create date:	July 2021
	Description:	Return the list of object types, containing core details

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
	
	============================================= */
CREATE OR ALTER PROCEDURE [dbo].[usp_Mitre_Analysis_102_Top_N_OLD] 
(
	@ACTION				INT = 0,			--> 
	@Top_Techniques		INT = 10,			--> Select the top [N] most used Techniques
	@Top_DataSources	INT = 1,			--> Filter where TechCount >= @Top_DataSources
	@LAST_2YRS			BIT = 0				--> 
)
AS
BEGIN


--> ##########################################################################################
--> ##########################################################################################
--> ##########################################################################################
IF 1=1 OR @ACTION & 128 > 0
BEGIN	--> Extract Techniques and Mitigations                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

	IF 1=0 SELECT * FROM dbo.mkType

	DECLARE 
	@yr2021		INT = 2021,
	@last2Yrs	VARCHAR(3) = (SELECT CASE WHEN @LAST_2YRS = 1 THEN 'YES' ELSE 'No' END),
	@p			FLOAT = 2

	BEGIN	--> Inits
	/* ################################################################################################
		Primary store of Technique data for the data extract.
		This table contains the most used techniques. Since some techniques are used by both 
		Malware and Tools, they are listed twice in the MUT table. For our purpose, we take the entry
		with the lowest [[Rank]] value (i.e. the highest ranked of the two), but we store data from both 
		entries.
	   ################################################################################################ */
	DECLARE @topTechniques TABLE (
		Pk					INT,				--> PK from dbo.aMaT_MuTechniquesAndMitigations
		BmPk				INT IDENTITY(1,1),	--> Identity within this collection. Required for BitMask
		BitMask				BIGINT,				--> POWER(BmPk, 2) to allow identification of unique combinations of Techniques
		[Rank]				INT,				--> 
		[MinRank]			INT,				--> Sequence # of Most-Used-Techniques [ORDER BY x.[2021] DESC, x.[2020] DESC, x.[2019] DESC, x.[2018] DESC]
		
		PkMax				INT,				--> PK, second
		PosMax				INT,				--> [Rank], second
		PkCount				INT,				--> Number of MUT entries for this Technique

		TechniquePk			INT,				--> To help with subsequent lookups
		TechniqueRootPk		VARCHAR(100),		--> To help with subsequent lookups
		IsSubTechnique		BIT DEFAULT 0,		--> Is sub-technique
		ParentRootPk		VARCHAR(100),		--> Parent of a sub-technique
		HasCoAs				BIT DEFAULT 1,		--> We found that 24 sub-Techniques have no CoAs

		KC_Masks			INT,				--> Sum KC phase masks that this Technique has
		KC_Count			INT,				--> Count of associated KC phases for this Technique
		Mitigations			INT DEFAULT 0		--> The number of mitigations for this Technique
	);

	/* ################################################################################################
		Primary store of Mitigation data for the data extract.

		KILLCHAIN DATA: CoAs are not directly associated with the Killchain. To find valid KC links,
		for each CoA, we find the techniques each CoA mitigates. For each associated Technique, we 
		find its Killchain links. Finally, we associate those KC links back to the CoA.
	   ################################################################################################ */
	DECLARE @mitigationsYr TABLE (
		CoA_Pk				INT,
		CoA_RootPk			VARCHAR(100),
		[Rank]				INT,

		CoA					VARCHAR(100),	--> Name of the CoA
		
		[2018]				INT,			--> 
		[2019]				INT,			--> 
		[2020]				INT,			--> 
		[2021]				INT,			-->

		KC_Count			INT,			--> Count of killchains
		KC_Masks			INT,			--> The collection of KC Masks for this CoA
		KC_Pks				VARCHAR(MAX),	--> String of KC Pks 
		TtlTechs			INT				--> The total number of Techniques that this CoA affects in 2021
	);
	
	/* ################################################################################################
		Get most used Techniques across the years; exclude those not used in 2021.
		Optionally, restrict to those techniques that were not used in [2018, 2019].

		This query is complicated by the fact that some techniques appear twice (Tools and Malware).
	   ################################################################################################ */
	BEGIN	--> Seed Techniques

		--> -------------------------------------------------------------------------------------------
		--> FIND T1 - Seed the data
		INSERT @topTechniques (Pk, [Rank], MinRank, PkMax, PosMax, PkCount, TechniquePk, TechniqueRootPk)
		SELECT TOP (@Top_Techniques)
			T.Pk,
			ROW_NUMBER() OVER (ORDER BY mut.[2021] DESC, mut.[2020] DESC, mut.[2019] DESC, mut.[2018] DESC) [Rank],
			T.[MinRank], 
			T.PkMax, T.PosMax, 
			T.PkCount, 
			T.TechPk, T.TechRootPk
		FROM (
			SELECT
				MIN(S.Pk) Pk,
				MIN(S.[Rank]) [MinRank], 
				MAX(S.Pk) PkMax, MAX(S.[Rank]) PosMax, 
				COUNT(S.Pk) PkCount, 
				S.TechPk, S.TechRootPk
			FROM (
				SELECT TOP(1000) 
					x.Pk Pk,
					ROW_NUMBER() OVER(ORDER BY x.[2021] DESC, x.[2020] DESC, x.[2019] DESC, x.[2018] DESC) [Rank],
					x.ToTypeObjMaxPk TechPk, x.ToTypeRootPk TechRootPk
				FROM dbo.aMaT_MuTechniquesAndMitigations x
				INNER JOIN dbo.mkObject mo ON mo.[objId] = x.ToTypePk
					AND mo.objDeprecated = 0 AND mo.objRevoked = 0
				WHERE 1=1
					AND x.[2021] > 0		--> Exclude Techniques that are unused in 2021
					AND (
						(@LAST_2YRS = 0 OR (@LAST_2YRS = 1 AND x.[2018] = 0 AND x.[2019] = 0))
					)
			) S
			GROUP BY S.TechPk, S.TechRootPk
			HAVING COUNT(S.Pk) > 0
		) T
		INNER JOIN dbo.aMaT_MuTechniquesAndMitigations mut ON mut.Pk = T.Pk
		INNER JOIN dbo.mkObject mo ON mo.[objId] = mut.ToTypeObjMaxPk
			AND mo.objRevoked = 0 AND mo.objDeprecated = 0;

		--> Assign each Tech/CoA a unique binary mask.
		UPDATE @topTechniques SET BitMask = POWER(@p, (BmPk-1));

		IF 1=0	--> For Testing
		SELECT '->' [Core Techniques], mo.objRevoked Revoked, mo.objDeprecated Deprecated,  x.*, mut.ToTypeName [Technique] 
		FROM @topTechniques x
		INNER JOIN dbo.aMaT_MuTechniquesAndMitigations mut ON mut.Pk = x.Pk
		INNER JOIN dbo.mkObject mo ON mo.[objId] = mut.ToTypeObjMaxPk
			
	
		--> -------------------------------------------------------------------------------------------
		--> FIND 2 - Does sub-/Technique have zero mitigations
		MERGE @topTechniques x
		USING (
			SELECT
				x.Pk
			FROM @topTechniques x
			LEFT JOIN dbo.mkRelationship r ON 
				r.relTargetRef = x.TechniqueRootPk
				AND r.relType = 'mitigates' AND r.relYear = @yr2021
			WHERE r.relId IS NULL
		) Orphans ON Orphans.Pk = x.Pk
		WHEN MATCHED THEN UPDATE SET x.HasCoAs = 0;
	
		--> -------------------------------------------------------------------------------------------
		--> FIND 3 - Set IsSubTechnique
		MERGE @topTechniques x
		USING (
			SELECT t.Pk, 
				CASE WHEN ro.roTypeId = 11 THEN 1 ELSE 0 END IsSubTech
			FROM @topTechniques t
			INNER JOIN dbo.mkRootObject ro ON ro.roPk = t.TechniqueRootPk
		) S ON S.Pk = x.PK
		WHEN MATCHED THEN UPDATE SET x.IsSubTechnique = S.IsSubTech;

		
		--> -------------------------------------------------------------------------------------------
		--> FIND T4.1 - Get parent of each entry that has zero mitigations
		MERGE @topTechniques x
		USING (
			SELECT 
				y.Pk, y.TechniqueRootPk, r.relTargetRef Parent_RootPk
			FROM @topTechniques y
			INNER JOIN dbo.aMaT_MuTechniquesAndMitigations mut ON mut.Pk = y.Pk
			--> Get parent details
			INNER JOIN dbo.mkRelationship r ON r.relSourceRef = y.TechniqueRootPk
				AND r.relType = 'subtechnique-of' AND r.relYear = @yr2021
			WHERE 1=1
				AND y.HasCoAs = 0
		) S ON S.Pk = x.PK
		WHEN MATCHED THEN UPDATE SET x.ParentRootPk = S.Parent_RootPk;
		

		--> -------------------------------------------------------------------------------------------
		--> FIND T4.2 - And for rest, simply update the parent to be the Technique RootPk, to simplify later queries
		MERGE @topTechniques x
		USING (
			SELECT 
				y.Pk, y.TechniqueRootPk Parent_RootPk
			FROM @topTechniques y
			WHERE 1=1
				AND y.HasCoAs = 1
		) S ON S.Pk = x.PK
		WHEN MATCHED THEN UPDATE SET x.ParentRootPk = S.Parent_RootPk;
		
		
		--> -------------------------------------------------------------------------------------------
		--> FIND T4 - Add the number of Mitigations per technique.
		IF 1=1
		MERGE @topTechniques x
		USING (
			SELECT --TOP(50)
				x.Pk,  
				COUNT(r.relType) [CoA Count]
			FROM @topTechniques x
			INNER JOIN dbo.mkRelationship r ON 
				r.relTargetRef = x.ParentRootPk
				AND r.relType = 'mitigates' AND r.relYear = @yr2021
			GROUP BY x.Pk
		) S ON S.Pk = x.PK
		WHEN MATCHED THEN UPDATE SET x.Mitigations = S.[CoA Count];

		
		--> -------------------------------------------------------------------------------------------
		--> FIND T5 - Add Killchain phases to each technique (i.e. the sum of its KC Phase mask values).
		MERGE @topTechniques x
		USING (
			SELECT mut.Pk, SUM(kp.kcMask) MaskSum, COUNT(kp.kcPk) KC_Count
			FROM @topTechniques x
				INNER JOIN dbo.aMaT_MuTechniquesAndMitigations mut ON mut.Pk = x.Pk
				INNER JOIN dbo.mkObjectToKillchain kc ON kc.okObjectId = x.TechniquePk
				INNER JOIN dbo.mkKillchainPhases kp ON kp.kcPk = kc.okKillchainId
			GROUP BY mut.Pk, mut.ToType
		) S ON S.Pk = x.PK
		WHEN MATCHED THEN UPDATE SET x.KC_Masks = S.MaskSum, x.KC_Count = S.KC_Count;

	END		--> Seed Techniques

	BEGIN	--> Seed Mitigations (CoAs)

		/*	------------------------------------------------------------------------------------------
			IMPORTANT:
			In the Mitre data structure, only Techniques are associated with CoAs and the Killchain.
			Due to this structure, it seems that we cannot associate CoAs back to the Killchain, via
			Techniques. Doing so results in cross-multiplying the CoA/Tech relationships in a meaningless
			way.

			Also, since sub-techniques are not linked to CoAs, we link sub-techniques to their parent 
			Technique. This enables us to find the CoAs used to mitigate the sub-techniques.
			IMO, the results of this are confusing. 4x, 
			------------------------------------------------------------------------------------------ */

		--> -------------------------------------------------------------------------------------------
		--> FIND M1 - Get Mitigation (CoA) seed data (i.e. All CoAs for the Techniques in @topTechniques) per year
		INSERT @mitigationsYr (CoA_Pk, CoA_RootPk, [Rank], CoA, [2018], [2019], [2020], [2021])
		SELECT 
			ro.roMaxObjPk CoA_MaxPk, R.CoA_RootPk,
			ROW_NUMBER() OVER (ORDER BY [2021] DESC, [2020] DESC, [2019] DESC,[2018] DESC) [Rank],
			mo.objName CoA, 
			R.[2018], R.[2019], R.[2020], R.[2021]
		FROM (
			SELECT 
				CoA_RootPk, 
				ISNULL([2018], 0) [2018],
				ISNULL([2019], 0) [2019], 
				ISNULL([2020], 0) [2020], 
				ISNULL([2021], 0) [2021]
			FROM (
				SELECT 
					r.relSourceRef CoA_RootPk, r.relYear Yr, 
					COUNT(r.relId) CoA_Count
				FROM @topTechniques y
				INNER JOIN dbo.mkRelationship r ON r.relTargetRef = y.ParentRootPk
					AND r.relType = 'mitigates'
				INNER JOIN dbo.mkObject mo ON mo.objRootObjPk = r.relSourceRef
					AND mo.objYear = r.relYear
					--AND mo.objRevoked = 0
					--AND mo.objDeprecated = 0
				WHERE 1=1
				GROUP BY r.relSourceRef, r.relYear
			) Src
			PIVOT (
				SUM(CoA_Count) FOR Yr IN ([2018],[2019],[2020],[2021])
			) PT
		) R
		INNER JOIN dbo.mkRootObject ro ON ro.roPk = R.CoA_RootPk
		INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
		WHERE 1=1 
			--> For six techniques, their only mitigations were deprecated from 2019
			--> Application Window Discovery; Process Discovery; Remote System Discovery; System Information Discovery; 
			--> System Network Configuration Discovery; System Network Connections Discovery 
			--AND mo.objRevoked = 0
			AND mo.objDeprecated = 0
			--AND mo.objName IN ('Privileged Account Management','Network Intrusion Prevention')
		ORDER BY 
			[2021] DESC, [2020] DESC, [2019] DESC,[2018] DESC;

			
		--> -------------------------------------------------------------------------------------------
		--> FIND M2 - For each CoA, get Killchain count and sum of KC Masks.
		MERGE @mitigationsYr m
		USING (
			SELECT R.Pk, SUM(R.kcMask) KC_Mask, COUNT(R.kcPk) KC_Count
			FROM (
				SELECT DISTINCT m.CoA_Pk Pk, kp.kcMask, kp.kcPk 
				FROM @mitigationsYr m
				INNER JOIN dbo.mkRelationship r ON r.relSourceRef = m.CoA_RootPk
					AND r.relType = 'mitigates' AND r.relYear = @yr2021
				INNER JOIN dbo.mkRootObject ro ON ro.roPk = r.relTargetRef
				INNER JOIN dbo.mkObjectToKillchain kc ON kc.okObjectId = ro.roMaxObjPk
				INNER JOIN dbo.mkKillchainPhases kp ON kp.kcPk = kc.okKillchainId
			) R
			GROUP BY R.Pk
		) S ON S.Pk = m.CoA_Pk
		WHEN MATCHED THEN UPDATE SET m.KC_Count = S.KC_Count, m.KC_Masks = S.KC_Mask;
			
		--> -------------------------------------------------------------------------------------------
		--> FIND M3 - For each CoA, get a string of all the Killchain PKs associated with the CoA
		BEGIN	--> M3
			DECLARE @resultMits TABLE (CoA_Pk INT, KC_String VARCHAR(MAX))
			DECLARE @tempMits TABLE (CoA_Pk INT, Ord INT, KcPk INT)
			INSERT @tempMits (CoA_Pk, Ord, KcPk)
			SELECT m.CoA_Pk, 
				ROW_NUMBER() OVER (PARTITION BY m.CoA_Pk ORDER BY kp.kcPk) Ord,
				CONVERT(VARCHAR(2), kp.kcPk) KcPk
			FROM @mitigationsYr m
			INNER JOIN dbo.mkKillchainPhases kp ON kp.kcMask & m.KC_Masks > 0;

			--> Ref: https://www.sqlmatters.com/Articles/Converting%20row%20values%20in%20a%20table%20to%20a%20single%20concatenated%20string.aspx
			;WITH CTE AS
			(
				SELECT x.CoA_Pk, x.Ord, CONVERT(VARCHAR(MAX), kp.kcPk) KcPkx
				FROM @tempMits x
				INNER JOIN dbo.mkKillchainPhases kp ON kp.kcPk = x.KcPk
				WHERE x.Ord = 1
				UNION ALL
				SELECT x.CoA_Pk, x.Ord, c.KcPkx + ';' + CONVERT(VARCHAR(MAX), kp2.kcPk) KcPkx
				FROM CTE c
				INNER JOIN @tempMits x ON x.CoA_Pk = c.CoA_Pk
					AND x.Ord - 1 = c.Ord
				INNER JOIN dbo.mkKillchainPhases kp2 ON kp2.kcPk = x.KcPk
			)
			INSERT @resultMits (CoA_Pk, KC_String)
			SELECT c.CoA_Pk, '[' + c.KcPkx + ']'
			FROM CTE c
			INNER JOIN (
				SELECT MAX(c.Ord) Ord, c.CoA_Pk Pk
				FROM CTE c
				GROUP BY c.CoA_Pk
			) Cx ON c.Ord = Cx.Ord AND c.CoA_Pk = Cx.Pk
			--WHERE c.Ord = (SELECT MAX(c.Ord) FROM CTE c GROUP BY c.CoA_Pk);

			MERGE @mitigationsYr m
			USING (
				SELECT CoA_Pk, KC_String
				FROM @resultMits r
			) S ON S.CoA_Pk = m.CoA_Pk
			WHEN MATCHED THEN UPDATE SET m.KC_Pks = S.KC_String;

		END

		--> -------------------------------------------------------------------------------------------
		--> FIND M4 - Find total number of techniques in 2021 affected by each CoA (an after thought)
		BEGIN	--> M4 
			MERGE @mitigationsYr my
			USING (
				SELECT my.CoA_RootPk Pk, COUNT(r.relId) [TtlTechs]
				FROM @mitigationsYr my
				INNER JOIN dbo.mkRelationship r ON my.CoA_RootPk = r.relSourceRef 
					AND r.relType = 'mitigates' 
					AND r.relYear = @yr2021
				GROUP BY my.CoA_RootPk
			) S ON S.Pk = my.CoA_RootPk
			WHEN MATCHED THEN UPDATE SET my.TtlTechs = S.TtlTechs;
		END		--> M4

	END		--> Seed Mitigations (CoAs)

	BEGIN	--> Testing

		IF 1=0	--> Testing only
		BEGIN	--> Testing only
			DECLARE 
			@rootPkT VARCHAR(100)		= 'attack-pattern--0c2d00da-7742-49e7-9928-4514e5075d32',
			@coaRootPkT VARCHAR(100)	= 'course-of-action--28c0f30c-32c3-4c6c-a474-74820e55854f',
			@techNameT VARCHAR(100)		= 'Path Interception by PATH Environment Variable'

			SELECT 't1' [t1], mo.[objId], mo.objName [Tech], mo.objYear Yr, moc.objName [CoA]
			FROM mkObject mo 
			INNER JOIN dbo.mkRelationship r ON r.relTargetRef = mo.objRootObjPk
				AND r.relYear = mo.objYear AND r.relType = 'mitigates'
			INNER JOIN dbo.mkObject moc ON moc.objRootObjPk = r.relSourceRef
				AND moc.objYear = r.relYear
			WHERE 1=1
				--AND mo.objRootObjPk = @rootPkT
				--AND mo.objName = @techNameT
				AND r.relSourceRef = @coaRootPkT

			SELECT 't2' [t2], mo.[objId], mo.objName [Tech], mo.objYear Yr, kp.kcName KC
			FROM mkObject mo 
			INNER JOIN dbo.mkObjectToKillchain ok ON mo.[objId] = ok.okObjectId
			INNER JOIN dbo.mkKillchainPhases kp ON kp.kcPk = ok.okKillchainId
			WHERE  1=1
				--AND mo.objRootObjPk = @rootPkT
				AND mo.objName = @techNameT
		END		--> Testing only

		IF 1=0	--> Testing only
		BEGIN	--> Testing only
			--SELECT '1. =>' [MK2], 
			--	ro.roMaxObjPk CoA_MaxPk, R.CoA_RootPk,
			--	ROW_NUMBER() OVER (ORDER BY [2021] DESC, [2020] DESC, [2019] DESC,[2018] DESC) [Rank],
			--	mo.objName CoA, 
			--	R.[2018], R.[2019], R.[2020], R.[2021]
			--FROM (
				SELECT '1. =>' [MK1], 
					CoA_RootPk, 
					ISNULL([2018], 0) [2018],
					ISNULL([2019], 0) [2019], 
					ISNULL([2020], 0) [2020], 
					ISNULL([2021], 0) [2021]
					, CoA
				FROM (
					SELECT '1. =>' [MK2], 
						mo.objRootObjPk CoA_RootPk, r.relYear Yr, COUNT(mo.[objId]) CoA_Count, mo.objName [CoA]
					FROM @topTechniques y
					INNER JOIN dbo.aMaT_MuTechniquesAndMitigations mut ON mut.Pk = y.Pk
					INNER JOIN dbo.mkRelationship r ON r.relTargetRef = y.ParentRootPk
						AND r.relType = 'mitigates'
						--AND r.relSourceRef = 'course-of-action--9bb9e696-bff8-4ae1-9454-961fc7d91d5f'
						--AND r.relTargetRef = 'attack-pattern--0c2d00da-7742-49e7-9928-4514e5075d32'
					INNER JOIN dbo.mkObject mo ON mo.objRootObjPk = r.relSourceRef
						AND mo.objYear = r.relYear
						AND mo.objRevoked = 0
						--AND mut.ToTypeName = ''
					WHERE 1=1
					GROUP BY mo.objRootObjPk, r.relYear, mo.objName
				) Src
				PIVOT (
					SUM(CoA_Count) FOR Yr IN ([2018],[2019],[2020],[2021])
				) PT
				--GROUP BY CoA_RootPk, [2018], [2019], [2020], [2021]
			--) R
			--INNER JOIN dbo.mkRootObject ro ON ro.roPk = R.CoA_RootPk
			--INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
			--WHERE 1=1 
			--	AND mo.objRevoked = 0
			--	--AND mo.objDeprecated = 1
			--	--AND mo.objName IN ('Privileged Account Management','Network Intrusion Prevention')
			--ORDER BY 
			--	[2021] DESC, [2020] DESC, [2019] DESC,[2018] DESC;
			
			--############################################################
			--############################################################
		
				SELECT '2. =>' [MK2], 
					Pk, CoA, KC, 				 
					ISNULL([2018], 0) [2018],
					ISNULL([2019], 0) [2019], 
					ISNULL([2020], 0) [2020], 
					ISNULL([2021], 0) [2021]
					--,(ISNULL([2018], 0) + ISNULL([2019], 0) + ISNULL([2020], 0) + ISNULL([2021], 0)) Ttl
				FROM (
					SELECT 
						m.CoA_Pk Pk, 
						m.CoA,
						r.relYear Yr, 
						--kp.kcMask, 
						kp.kcPk, 
						kp.kcName KC,
						COUNT(kp.kcPk) KcYrCount
					FROM @mitigationsYr m
					INNER JOIN dbo.mkRelationship r ON r.relSourceRef = m.CoA_RootPk
						AND r.relType = 'mitigates' --AND r.relYear IN (2020, @yr2021)
					INNER JOIN @topTechniques y ON y.ParentRootPk = r.relTargetRef			--> Filtered against our Techniques
					INNER JOIN dbo.mkRootObject ro ON ro.roPk = r.relTargetRef
					INNER JOIN dbo.mkObjectToKillchain kc ON kc.okObjectId = ro.roMaxObjPk
					INNER JOIN dbo.mkKillchainPhases kp ON kp.kcPk = kc.okKillchainId
					WHERE 1=1
						--AND m.CoA_Pk IN (20682, 20526)
						AND m.CoA_Pk IN (20682)
						--AND kp.kcPk IN (6,7)
					GROUP BY m.CoA_Pk, m.CoA, r.relYear, kp.kcName, kp.kcPk) Src
				PIVOT (
					SUM(KcYrCount) FOR Yr IN ([2018],[2019],[2020],[2021])
				) PT
				ORDER BY [2021] DESC, [2020] DESC, [2019] DESC
		END		--> Testing only

	END		--> Testing

	END		--> Inits

	/* ################################################################################################
		RESULTS 1 - Total number of Techniques per Killchain Phase, for each year
	   ################################################################################################ */	
	IF @ACTION & 1 > 0	--> Technique KCs
	BEGIN
		SELECT 'Distribution of Techniques over Killchain' [Comment], @Top_Techniques [Top N], @last2Yrs [Last Two Yrs];

		SELECT 
			kp.kcOrder KcOrder, kp.kcName Killchain, 
			ISNULL(Q.[2018], 0) [2018], ISNULL(Q.[2019], 0) [2019], ISNULL(Q.[2020], 0) [2020], ISNULL(Q.[2021], 0) [2021]
			--, ISNULL(Q.Mitigations, 0) [Mitigations]
		FROM mkKillchainPhases kp
		LEFT JOIN (
			SELECT 
				S.* 
			FROM (
				SELECT
					kp.kcName Killchain
					, SUM(mut.[2018]) [2018], SUM(mut.[2019]) [2019], SUM(mut.[2020]) [2020], SUM(mut.[2021]) [2021]
					,SUM(y.Mitigations) Mitigations
				FROM  dbo.aMaT_MuTechniquesAndMitigations mut
				INNER JOIN @topTechniques y ON y.Pk = mut.Pk
					AND y.IsSubTechnique IN (1,0)
				INNER JOIN dbo.mkObjectToKillchain kc ON kc.okObjectId = mut.ToTypeObjMaxPk
				INNER JOIN dbo.mkKillchainPhases kp ON kp.kcPk = kc.okKillchainId
				GROUP BY kp.kcName
			) S
		) Q ON Q.Killchain = kp.kcName
		WHERE 1=1
		AND kp.kcOrder > 3 AND kp.kcOrder < 14
		--AND Q.Killchain IS NOT NULL

		ORDER BY kp.kcOrder;

	END

	IF @ACTION & 2 > 0	--> Mitigations KCs
	BEGIN
		SELECT 'Distribution of Mitigations over Killchain. @Action:4 is better' [Comment], @Top_Techniques [Top N], @last2Yrs [Last Two Yrs]
			,'Excel: CoAs for Top N Techniques over the KC' [->> MK <<-];

		IF 1=0 SELECT kp.kcMask, kp.kcOrder, kp.kcName [KC] FROM dbo.mkKillchainPhases kp

		DECLARE @y VARCHAR(3) = 'Y'

		SELECT Mitigation, 
			--[2018], [2019], [2020], 
			[2021], 
			--KC_Count [KC Count], 
			'##' [##],

			--ISNULL([Reconnaissance], 0) [Reconnaissance],
			--[Resource Development] [Resource Development],
			CASE WHEN ISNULL([Initial Access], 0) = 1 THEN @y ELSE '' END [Initial Access],
			CASE WHEN ISNULL([Execution], 0) = 1 THEN @y ELSE '' END [Execution],
			CASE WHEN ISNULL([Persistence], 0) = 1 THEN @y ELSE '' END [Persistence],
			CASE WHEN ISNULL([Privilege Escalation], 0) = 1 THEN @y ELSE '' END [Privilege Escalation],
			CASE WHEN ISNULL([Defense Evasion], 0) = 1 THEN @y ELSE '' END [Defense Evasion],
			CASE WHEN ISNULL([Credential Access], 0) = 1 THEN @y ELSE '' END [Credential Access],
			CASE WHEN ISNULL([Discovery], 0) = 1 THEN @y ELSE '' END [Discovery],
			CASE WHEN ISNULL([Lateral Movement], 0) = 1 THEN @y ELSE '' END [Lateral Movement],
			CASE WHEN ISNULL([Collection], 0) = 1 THEN @y ELSE '' END [Collection],
			CASE WHEN ISNULL([Command and Control], 0) = 1 THEN @y ELSE '' END [CnC],
			CASE WHEN ISNULL([Exfiltration], 0) = 1 THEN @y ELSE '' END [Exfiltration],
			CASE WHEN ISNULL([Impact], 0) = 1 THEN @y ELSE '' END [Impact]
			, mo.objDescription [CoA Dets]

		FROM (
			SELECT 
				1 xx,
				CoA_Pk,
				m.CoA [Mitigation], 
				m.[2018], m.[2019], m.[2020], m.[2021],
				--m.[2021], 
				m.KC_Count
				,kp.kcName [KC]			
			FROM @mitigationsYr m
			INNER JOIN dbo.mkKillchainPhases kp ON kp.kcMask & m.KC_Masks > 0
		) Src
		PIVOT (
			MAX([xx]) FOR KC IN (	[Reconnaissance],
									--[Resource Development],
									[Initial Access],
									[Execution],
									[Persistence],
									[Privilege Escalation],
									[Defense Evasion],
									[Credential Access],
									[Discovery],
									[Lateral Movement],
									[Collection],
									[Command and Control],
									[Exfiltration],
									[Impact])
		) PT
		LEFT JOIN dbo.mkObject mo ON mo.[objId] = CoA_Pk
		ORDER BY KC_Count DESC, [2021] DESC;
		
		IF 1=0
		SELECT 
			m.CoA [Mitigation], 
			m.[2018], m.[2019], m.[2020], m.[2021]	

			, m.[Rank] [CoA Rank]
			, m.KC_Count, m.KC_Masks
			, KC_Pks
			, m.CoA_Pk 
		FROM @mitigationsYr m
		ORDER BY KC_Count DESC, [2021] DESC;

	END
	

	/* ################################################################################################
		RESULTS 2 - Total Mitigations per Technique
	   ################################################################################################ */	
	IF @ACTION & 4 > 0
	BEGIN

		IF 1=1 --> We WANT this section
		BEGIN
			IF 1=1
			BEGIN
				SELECT 'RS1: Distribution of Mitigations over Killchain.' [Comment], @Top_Techniques [Top N], @last2Yrs [Last Two Yrs], 'Prob prefer the @ACTION=2 data' [MK];

				SELECT 
					'Top Mits' [Top Mits], my.[Rank],				
					--ROW_NUMBER() OVER (ORDER BY [2021] DESC, [2020] DESC, [2019] DESC,[2018] DESC) [Rank2],
					--my.CoA_RootPk, my.CoA_Pk,
					my.CoA, my.[2018], my.[2019], my.[2020], my.[2021], my.KC_Count, my.KC_Pks
					, mo.objDescription Dets
				FROM @mitigationsYr my
				INNER JOIN dbo.mkObject mo ON mo.[objId] = my.CoA_Pk;

			END

			SELECT 'RS2: Most effective mitigations (VIP)' [Comment], @Top_Techniques [Top N], @last2Yrs [Last Two Yrs]

			SELECT 'Techs/Mit' [Techs/Mit], my.[Rank], 
				my.CoA,
				Piv.[2018], Piv.[2019], Piv.[2020], Piv.[2021]
				, my.KC_Pks
			FROM (
				SELECT my.CoA_Pk, r.relTargetRef MitRootPk, r.relYear Yr
				FROM @mitigationsYr my
				INNER JOIN dbo.mkRelationship r ON r.relSourceRef = my.CoA_RootPk
					AND r.relType = 'mitigates'
				--INNER JOIN @topTechniques tx ON tx.TechniqueRootPk = r.relTargetRef
				INNER JOIN dbo.mkRootObject ro ON ro.roPk = r.relTargetRef
				INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
					AND mo.objDeprecated = 0 AND mo.objRevoked = 0
			) Src
			PIVOT (
				COUNT(MitRootPk) FOR Yr IN ([2018],[2019],[2020],[2021])
			) Piv
			INNER JOIN @mitigationsYr my ON my.CoA_Pk = Piv.CoA_Pk
			ORDER BY 
				[2021] DESC, [2020] DESC, [2019] DESC,[2018] DESC;
			
		END		--> We WANT this section
			
		BEGIN
			SELECT 'RS3: CoAs/Tech' [Comment], @Top_Techniques [Top N], @last2Yrs [Last Two Yrs];
			SELECT 'CoA / Tech' [CoA/Tech], @Top_Techniques [Top N],
				tx.TechniquePk, tx.[Rank], mo.objName Technique,
				S.[2018], S.[2019], S.[2020], S.[2021]
				--ISNULL(S.[2018], 0) [2018], ISNULL(S.[2019], 0) [2019],  ISNULL(S.[2020], 0) [2020], ISNULL(S.[2021], 0) [2021]
				, mo.objRootObjPk TechRootPk
				, mo.objDescription [Technique Details]
			FROM @topTechniques tx
			LEFT JOIN ( 
				SELECT 
					tx.Pk,
					PT.TechniquePk,
					tx.[Rank],
					ISNULL([2018], 0) [2018],
					ISNULL([2019], 0) [2019], 
					ISNULL([2020], 0) [2020], 
					ISNULL([2021], 0) [2021]
				FROM (
					SELECT
						r.relYear Yr, 
						tx.TechniquePk,
						COUNT(tx.TechniquePk) TechCount
					FROM @mitigationsYr mx
					INNER JOIN dbo.mkRelationship r ON r.relSourceRef = mx.CoA_RootPk
						AND r.relType = 'mitigates'
					INNER JOIN @topTechniques tx ON tx.TechniqueRootPk = r.relTargetRef
					INNER JOIN dbo.mkObject mo ON mo.[objId] = tx.Pk
						AND mo.objRevoked = 0 AND mo.objDeprecated = 0
					GROUP BY r.relYear, tx.TechniquePk
					--ORDER BY r.relYear DESC, TechCount DESC
				) Src
				PIVOT (
					SUM(TechCount) FOR Yr IN ([2018],[2019],[2020],[2021])
				) PT
				--LEFT JOIN dbo.mkObject mo ON mo.[objId] = PT.TechniquePk
				LEFT JOIN @topTechniques tx ON tx.TechniquePk = PT.TechniquePk
			) S ON S.Pk = tx.Pk
			INNER JOIN dbo.mkObject mo ON mo.[objId] = tx.TechniquePk
			--WHERE S.[2021] IS NULL
			ORDER BY tx.[Rank];
		

			SELECT 'RS4: Which of the top Techniques each of the top CoAs addresses.' [Comment];
			SELECT 'Tech / CoA' [Techs / CoA],
				tx.[Rank] TechRank, mot.objName [Tech], 
				mom.objName [CoA], mx.[Rank] CoARank, mx.[2021]
				--, mot.objDescription TechDets, mom.objDescription CoADets
				--, mx.KC_Pks
			FROM @mitigationsYr mx
			INNER JOIN dbo.mkRelationship r ON r.relSourceRef = mx.CoA_RootPk
				AND r.relType = 'mitigates' AND r.relYear = @yr2021
			INNER JOIN @topTechniques tx ON tx.TechniqueRootPk = r.relTargetRef
			INNER JOIN dbo.mkObject mot ON mot.[objId] = tx.TechniquePk
				AND mot.objRevoked = 0 AND mot.objDeprecated = 0
			INNER JOIN dbo.mkObject mom ON mom.[objId] = mx.CoA_Pk
				AND mom.objRevoked = 0 AND mom.objDeprecated = 0
			--WHERE tx.[Rank] IN (3)
			ORDER BY 
				--tx.[Rank], mot.objName
				mx.[Rank], mom.objName
		END

		IF 1=0
		BEGIN	--> Six deprecated mitigations

			/*	NOTE:			
				The mitigations for the six techniques listed below were deprecated from 2019 and therefore,
				these techniques do not appear in the Mitigations list
				Notice, for example, that the Rank 2 Technique has no mitigations!

				1) Application Window Discovery; 2) Process Discovery; 3) Remote System Discovery; 4) System Information Discovery; 
				5) System Network Configuration Discovery; 6) System Network Connections Discovery 
			*/	

			DECLARE @missingMits TABLE (RootPk VARCHAR(100))
			INSERT @missingMits (RootPk)
			VALUES 
			('attack-pattern--707399d6-ab3e-4963-9315-d9d3818cd6a0'),
			('attack-pattern--354a7f88-63fb-41b5-a801-ce3b377b36f1'),
			('attack-pattern--e358d692-23c0-4a31-9eb6-ecc13a8d7735'),
			('attack-pattern--4ae4f953-fe58-4cc8-a327-33257e30a830'),
			('attack-pattern--7e150503-88e7-4861-866b-ff1ac82c4475'),
			('attack-pattern--8f4a33ec-8b1f-4b80-a2f6-642b2e479580');

			SELECT
				r.relYear Yr, 
				tx.TechniquePk
				--,
				--COUNT(tx.TechniquePk) TechCount
			FROM @mitigationsYr mx
			INNER JOIN dbo.mkRelationship r ON r.relSourceRef = mx.CoA_RootPk
				AND r.relType = 'mitigates'
			INNER JOIN @topTechniques tx ON tx.TechniqueRootPk = r.relTargetRef
			INNER JOIN @missingMits mm ON mm.RootPk = tx.TechniqueRootPk
			--GROUP BY r.relYear, tx.TechniquePk
				
			SELECT
				r.relYear Yr, 
				tx.TechniquePk
			
				, mom.objDeprecated
				, mx.[Rank]
				--,
				--COUNT(tx.TechniquePk) TechCount
			FROM @topTechniques tx 
			--INNER JOIN @missingMits mm ON mm.RootPk = tx.TechniqueRootPk
			INNER JOIN dbo.mkRelationship r ON r.relTargetRef = tx.TechniqueRootPk
				AND r.relType = 'mitigates'
			LEFT JOIN @mitigationsYr mx ON mx.CoA_RootPk = r.relSourceRef
			--LEFT JOIN dbo.mkRootObject rom ON rom.roPk = mx.CoA_RootPk
			INNER JOIN dbo.mkObject mom ON mom.objRootObjPk = r.relSourceRef
				AND mom.objYear = r.relYear
				--AND mom.objDeprecated = 0
			--GROUP BY r.relYear, tx.TechniquePk
			WHERE 1=1
				AND mx.CoA_Pk IS NOT NULL
			ORDER BY r.relYear, tx.TechniquePk;

		END		--> Six deprecated mitigations

	END
	

	/* ################################################################################################
		RESULTS 3 - How to DETECT Techniques from Data Sources

		Ref: https://stackoverflow.com/questions/273238/how-to-use-group-by-to-concatenate-strings-in-sql-server
	   ################################################################################################ */	
	IF @ACTION & 8 > 0
	BEGIN	--> DETECTing Techniques

		IF 1=0
		SELECT 'MK =>' [>> Add this to DS analysis <<], S.*, ds.dsSource, ds.dsComponent
		FROM (
			SELECT 
				ods.odsDataSourceId Pk, COUNT(ods.odsObjectId) DS_Count
			FROM dbo.mkObjectToDataSource ods
			INNER JOIN dbo.mkObject mo ON mo.[objId] = ods.odsObjectId
			WHERE 1=1
			AND mo.objYear = @yr2021			--> DSs completely changed in 2021. Ref: https://medium.com/mitre-attack/attack-april-2021-release-39accaf23c81
			GROUP BY ods.odsDataSourceId
		) S
		LEFT JOIN dbo.mkDataSource ds ON ds.dsPk = S.Pk
		ORDER BY S.DS_Count DESC;

		--> All the DSs associated with @topTechniques
		IF OBJECT_ID('tempdb..#DataSources') IS NOT NULL
			DROP TABLE #DataSources
		CREATE TABLE #DataSources (
			Pk				INT IDENTITY(1,1), 
			DsPk			INT,
			TechCount		INT,					--> The number of Techniques associated with this Data Source
			BitMask			INT,					--> A unique bit mask for this DS entry
			[DS_Source]		VARCHAR(30),			--> The category of the DS, taken as the prefix
			DS_Component	VARCHAR(200),
			TotalTechCount	INT,						--> Across 2021, the total Techniques associated with this DataSource.Component

			OptimalCount	INT	DEFAULT 0,			--> The number of times this DS is used in the optimum collection of DSs
			OptimumOrder	INT						--> The orderin which to optimally use these DSs (8 Oct, added)
		);

		--> Running table for use in WHILE loop
		IF OBJECT_ID('tempdb..#TechniquesDsTemp') IS NOT NULL
			DROP TABLE #TechniquesDsTemp
		CREATE TABLE #TechniquesDsTemp (
			Pk			INT IDENTITY(1,1),
			TechPk		INT,
			DsMask		INT,			--> Mask of all DSs associated with this Technique
			OptimalDsPk	INT				--> ID of optimal DS used for this Technique
		);


		INSERT #DataSources (DS_Source, DS_Component, TechCount, DsPk)
		SELECT ds.dsSource, ds.dsComponent, S.TT_Count, S.Pk
		FROM (
			SELECT ods.odsDataSourceId Pk, COUNT(tt.TechniquePk) TT_Count
			FROM @topTechniques tt 
			INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsObjectId = tt.TechniquePk			
			GROUP BY ods.odsDataSourceId
		) S
		INNER JOIN dbo.mkDataSource ds ON ds.dsPk = S.Pk;

		UPDATE #DataSources SET BitMask = POWER(@p, (Pk-1));

		--> Total Techniques associated with each DS
		MERGE #DataSources dsx
		USING (
			SELECT dsx.DsPk, COUNT(ods.odsDataSourceId) TtlTs
			FROM #DataSources dsx
			INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsDataSourceId = dsx.DsPk
			GROUP BY dsx.DsPk
		) S ON S.DsPk = dsx.DsPk
		WHEN MATCHED THEN UPDATE SET dsx.TotalTechCount = S.TtlTs;

		IF 1=0
		BEGIN
			SELECT '===>' [MK: DSs],  * FROM #DataSources ds ORDER BY ds.TechCount DESC, ds.TotalTechCount DESC;

			SELECT '===>' [MK: DSs], ods.odsDataSourceId, COUNT(tt.TechniqueRootPk) TtCount, MAX(dsx.TotalTechCount) TtlTechCount
			FROM #DataSources dsx
			INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsDataSourceId = dsx.DsPk
			INNER JOIN @topTechniques tt ON tt.TechniquePk = ods.odsObjectId
			GROUP BY ods.odsDataSourceId
			ORDER BY TtCount DESC;
		END

		--> This holds the results of our query (i.e. the optimal mix of Data Sources across the Top N Techniques)
		INSERT #TechniquesDsTemp (TechPk, DsMask)
		SELECT tt.TechniquePk, SUM(ds.BitMask) DsMask
		FROM #DataSources ds
		INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsDataSourceId = ds.DsPk
		INNER JOIN @topTechniques tt ON tt.TechniquePk = ods.odsObjectId
		GROUP BY tt.TechniquePk;

		
		BEGIN	--> Work on Data Sources: Extract unique DSs; assign bitmasks to each

			IF 1=1	--> WE WANT THIS SECTION: Work on Data Sources
			BEGIN

				IF (OBJECT_ID('tempdb..#optimalDataSources')) IS NOT NULL DROP TABLE #optimalDataSources
				CREATE TABLE #optimalDataSources (
					Pk			INT IDENTITY(1,1),
					DsPk		INT,
					TechCount	INT,				--> Number of outstanding Techniques covered
					BitMask		INT,				--> BitMask of this technique
					TtlTechs	INT				--> Total number of all Techniques covered by this DS
				);

				DECLARE @dsCountMax INT = 10, @break BIT = 0, @tDsPk INT, @tMinPk INT, @tMask INT, @loopCount INT = 1,
				@showLoopComments BIT = 0;

				--> Find the optimal collection of Data Sources that cover the collection of Top Techniques
				WHILE @loopCount < @dsCountMax AND @break = 0 AND EXISTS (SELECT 1 FROM #TechniquesDsTemp x WHERE x.OptimalDsPk IS NULL)
				BEGIN
					
					TRUNCATE TABLE #optimalDataSources
					SELECT @tMinPk = 0, @tMask = 0, @tDsPk = 0;

					INSERT #optimalDataSources (DsPk, TechCount, BitMask, TtlTechs)
					SELECT --'#]#]#]#]', 
						dsx.DsPk, S.TechCount, dsx.BitMask, dsx.TotalTechCount
					FROM #DataSources dsx 
					INNER JOIN (
						SELECT dsx.DsPk, COUNT(tdt.Pk) TechCount 
						FROM #DataSources dsx
						INNER JOIN #TechniquesDsTemp tdt ON tdt.DsMask & dsx.BitMask > 0
							AND tdt.OptimalDsPk IS NULL
						GROUP BY dsx.DsPk
					) S ON S.DsPk = dsx.DsPk
					ORDER BY S.TechCount DESC, dsx.TotalTechCount DESC;

					SELECT @tMinPk = MIN(o.Pk) FROM #optimalDataSources o;
					SELECT @tDsPk = o.DsPk, @tMask = o.BitMask FROM #optimalDataSources o WHERE o.Pk = @tMinPk;

					IF @showLoopComments = 1
						SELECT 
							CASE WHEN @tMinPk = o.Pk THEN '->' ELSE '' END [Loop], @loopCount [@loopCount], o.*
						FROM #optimalDataSources o
						--WHERE @tMinPk = o.Pk;

					UPDATE #TechniquesDsTemp SET OptimalDsPk = @tDsPk
					WHERE OptimalDsPk IS NULL
					AND @tMask & DsMask > 1;

					MERGE #DataSources xds
					USING (
						SELECT @tDsPk Pk, COUNT(tx.Pk) x
						FROM #TechniquesDsTemp tx
						WHERE tx.OptimalDsPk = @tDsPk
					) S ON S.Pk = xds.DsPk
					WHEN MATCHED THEN UPDATE SET OptimalCount = S.x, OptimumOrder = @loopCount;

					SELECT @loopCount += 1;

				END		--> WHILE

			END

			IF @showLoopComments = 1
			BEGIN
				SELECT 'FINAL' [FINAL], @loopCount-1 [@loopCount < ], @dsCountMax [@dsCountMax],  @break [@break = 0]-- (SELECT 1 FROM #TechniquesDsTemp x WHERE x.OptimalDsPk IS NULL)
				SELECT 'FINAL' [FINAL], *, x.DsMask & 2 FROM #TechniquesDsTemp x;
			END

		END		--> Work on Datasources

		IF 1=1
		BEGIN	--> Display Data Sources results		

			SELECT 'RS1: All data sources' [Comment], @Top_Techniques [Top N];
			SELECT --'DS ->' [Data Sources], 
				S.Pk, S.TechCount, S.BitMask, S.[DS_Source], S.DS_Component, S.OptimalCount, 
					CASE WHEN OptimumOrder = 999 THEN 0 ELSE OptimumOrder END OptimumOrder
			FROM (
				SELECT
					d.Pk, d.TechCount, d.BitMask, d.[DS_Source], d.DS_Component, d.OptimalCount, ISNULL(d.OptimumOrder, 999) OptimumOrder
				FROM #DataSources d 
				WHERE (@Top_DataSources = 0 OR d.TechCount >= @Top_DataSources)
			) S
			ORDER BY S.OptimumOrder, S.TechCount DESC;

			SELECT 'RS2: DSs / Technique' [Comment], @Top_Techniques [Top N];
			SELECT d.DS_Component, d.TechCount, d.TotalTechCount, mo.objName Technique
			FROM  #DataSources d 
			INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsDataSourceId = d.DsPk
			INNER JOIN @topTechniques tt ON tt.TechniquePk = ods.odsObjectId
			INNER JOIN dbo.mkObject mo ON mo.[objId] = tt.TechniquePk
			ORDER BY d.TechCount DESC, tt.[Rank]


			--SELECT 'DS/Tech ->' [DS/Tech], 
			--	tx.[Rank] TechRank, tx.TechniquePk, mo.objName Technique, COUNT(ds.Pk) DsCount
			--FROM #Detections dx	
			--INNER JOIN @topTechniques tx ON tx.TechniquePk = dx.TechPk
			--LEFT JOIN #DataSources ds ON dx.Val = ds.DataSource
			--	AND (@Top_DataSources = 0 OR ds.TechCount >= @Top_DataSources)
			--INNER JOIN dbo.mkObject mo ON mo.[objId] = dx.TechPk
			--GROUP BY tx.[Rank], mo.objName, tx.TechniquePk
			----HAVING COUNT(ds.Pk) = 0
			--ORDER BY 
			--	tx.[Rank]
			--	--DsCount DESC;
			
			--> For the top Techniques, these are the primary data sources used to detect them
			SELECT 'RS3: Optimum DS collection to cover the top Techniques' [Comment], @Top_Techniques [Top N];
			SELECT *
			FROM #DataSources ds
			WHERE ds.OptimalCount > 0
			ORDER BY ds.OptimalCount DESC;

			SELECT 'RS4: All Techniques covered by the Optimum DS collection' [Comment], @Top_Techniques [Top N];
			SELECT mo.objName Technique, tt.[Rank], ds.*
			FROM @topTechniques tt
			INNER JOIN dbo.mkObjectToDataSource ods ON ods.odsObjectId = tt.TechniquePk
			INNER JOIN #DataSources ds ON ds.DsPk = ods.odsDataSourceId
				AND ds.OptimumOrder > 0
			INNER JOIN dbo.mkObject mo ON mo.[objId] = tt.TechniquePk
			ORDER BY ds.OptimumOrder, tt.[Rank] 



		END		--> Display DS results


	END		--> DETECTing Techniques

	
	
	/* ################################################################################################
		RESULTS 4 - Most effective CoA combinations against Top N Techniques
	   ################################################################################################ */	
	IF @ACTION & 16 > 0
	BEGIN
		--SELECT COUNT(*) [Tech Count], SUM(tx.Mitigations) [Mit Count] FROM @topTechniques tx

		--> All Technique/CoA combinations
		DECLARE @allMits TABLE (TechRootPk VARCHAR(100), CoARootPk VARCHAR(100), YrCount INT, MaxYr INT)

		--> The distinct collection of CoAs from [@allMits]
		IF (OBJECT_ID('tempdb..#distinctMits')) IS NOT NULL DROP TABLE #distinctMits
		CREATE TABLE #distinctMits (Id INT IDENTITY(1,1), 
			CoARootPk VARCHAR(100), TechCount INT, TtlTechMask INT, 			
			TotalTechs INT			--> The total number of techniques covered by each of the distinct techniques
		)
		
		IF (OBJECT_ID('tempdb..#optimalMits')) IS NOT NULL DROP TABLE #optimalMits
		CREATE TABLE #optimalMits (Id INT IDENTITY(1,1), 
			TechRootPk		VARCHAR(100), 
			TechBitMask		INT, 
			TechRank		INT, 
			CoACountT		INT,		--> Used in the loop
			CoACount		INT,		--> Holds actual "optimal usage" count
			CoARootPk		VARCHAR(100))

		INSERT #optimalMits (TechRootPk, TechBitMask, TechRank)
		SELECT tt.TechniqueRootPk, tt.BitMask, tt.[Rank]
		FROM @topTechniques tt
		ORDER BY tt.[Rank]

		IF 1=0
		SELECT 'The MITs ->' [MK], S.*
		FROM (
			SELECT
			tx.TechniqueRootPk, r.relSourceRef [CoA], COUNT(*) YrCount, MAX(r.relYear) Yr, MAX(tx.[Rank]) [Rank]
			FROM @topTechniques tx
			LEFT JOIN dbo.mkRelationship r ON r.relTargetRef = tx.TechniqueRootPk
				AND r.relType = 'mitigates'
				AND r.relYear = @yr2021
			GROUP BY tx.TechniqueRootPk, r.relSourceRef
		) S
			ORDER BY S.[Rank]

		--> Get all Technique/CoA combinations, using Top N Techniques, but only for one 2021.
		INSERT @allMits (TechRootPk, CoARootPk, YrCount, MaxYr)
		SELECT S.TechniqueRootPk, S.CoA, S.YrCount, S.Yr
		FROM (
			SELECT tx.TechniqueRootPk, r.relSourceRef [CoA], COUNT(*) YrCount, MAX(r.relYear) Yr, MAX(tx.[Rank]) [Rank]
			FROM @topTechniques tx
			LEFT JOIN dbo.mkRelationship r ON r.relTargetRef = tx.TechniqueRootPk
				AND r.relType = 'mitigates'
				AND r.relYear = @yr2021
			WHERE r.relId IS NOT NULL						--> There are no mitigations for 'attack-pattern--29be378d-262d-4e99-b00d-852d573628e6' (System Checks)
			GROUP BY tx.TechniqueRootPk, r.relSourceRef
		) S
		ORDER BY S.[Rank];
		
		IF 1=1 SELECT DISTINCT '-> MK (1145)' [All COAz], * FROM @mitigationsYr my ORDER BY my.TtlTechs DESC
		IF 1=1 SELECT DISTINCT '-> MK (1145)' [All mitz], am.CoARootPk FROM @allMits am
		IF 1=1 SELECT '-> MK (1145)' [All mitz], * FROM @mitigationsYr


		DECLARE 
		@breakoutCount	INT = 20,
		@dmPk			INT,				--> Id from @distinctMits
		@techMask		INT,
		@coaRootPk		VARCHAR(100)
		;

		IF 1=1
		WHILE (  (@breakoutCount > 0) AND (EXISTS (SELECT 1 FROM #optimalMits x WHERE x.CoARootPk IS NULL)) )
		BEGIN
			TRUNCATE TABLE #distinctMits;

			--> Get all mitigations for the set of Techniques that has not been mitigated
			INSERT #distinctMits (CoARootPk, TechCount, TtlTechMask)
			SELECT S.CoARootPk, S.[Tech Count], S.TtlTechMask
			FROM (
				SELECT am.CoARootPk, COUNT(*) [Tech Count], SUM(om.TechBitMask) [TtlTechMask]
				FROM @allMits am
				INNER JOIN #optimalMits om ON om.TechRootPk = am.TechRootPk
					AND om.CoARootPk IS NULL
				GROUP BY am.CoARootPk
			) S
			ORDER BY S.[Tech Count] DESC, S.[TtlTechMask];

			SELECT @dmPk = MIN(Id) FROM #distinctMits;
			SELECT @techMask = dm.TtlTechMask, @coaRootPk = dm.CoARootPk FROM #distinctMits dm WHERE dm.Id = @dmPk;

			IF @coaRootPk IS NOT NULL
			MERGE #optimalMits om
			USING (
				SELECT om.Id Pk
				FROM #optimalMits om
				WHERE om.TechBitMask & @techMask > 0
			) S ON S.Pk = om.Id
			WHEN MATCHED THEN UPDATE SET
				om.CoACountT	= ISNULL(om.CoACountT, 0) + 1,
				CoARootPk		= CASE WHEN CoARootPk IS NULL THEN @coaRootPk ELSE CoARootPk END;

			IF 1=0 SELECT '->' [Loop Dets], COUNT(*) [OM Count], @breakoutCount [@breakoutCount], @dmPk [@dmPk], @coaRootPk [@coaRootPk] FROM #optimalMits om WHERE om.CoARootPk IS NOT NULL

			IF 1=0
			SELECT '->' [Optimal Mits], @breakoutCount [@breakoutCount],
				om.*, mo.objName Tech, mo.objDescription [Tech Description]
			FROM #optimalMits om
			INNER JOIN dbo.mkRootObject ro ON ro.roPk = om.TechRootPk
			INNER JOIN dbo.mkObject mo ON mo.[objId] = ro.roMaxObjPk
			--WHERE om.CoARootPk IS NOT NULL
			ORDER BY om.CoARootPk DESC

			SELECT @breakoutCount -= 1;
		END
		
		MERGE #optimalMits om
		USING (			
			SELECT om.CoARootPk ,COUNT(*) [CoA Count] 
			FROM #optimalMits om 
			GROUP BY om.CoARootPk
		) Q ON Q.CoARootPk = om.CoARootPk
		WHEN MATCHED THEN UPDATE SET CoACount = [CoA Count];	

		IF 1=1 SELECT '->' [Optimals after loop], om.*, coa.objName CoA FROM #optimalMits om INNER JOIN dbo.mkRootObject ro ON ro.roPk = om.CoARootPk INNER JOIN dbo.mkObject coa ON coa.[objId] = ro.roMaxObjPk ORDER BY om.CoACount DESC, coa.objName, om.TechRank
		
		IF 1=1
		BEGIN	--> After thought: I should find the total number of Techniques covered by each CoA
			DELETE #distinctMits

			SELECT '1188. ==>' [Marko is here], my.CoA_RootPk, coa.objName CoA, my.TtlTechs, om.*
			FROM @mitigationsYr my
			--LEFT JOIN dbo.mkRootObject ro ON ro.roPk = my.CoA_RootPk
			LEFT JOIN #optimalMits om ON om.CoARootPk = my.CoA_RootPk
				AND om.CoACount IS NOT NULL
			INNER JOIN dbo.mkObject coa ON coa.[objId] = my.CoA_Pk
			ORDER BY my.[TtlTechs] DESC
		END

		SELECT 'RS1: The optimal set of CoAs against the Top N Techniques.' [Comment], @Top_Techniques [Top N], @last2Yrs [Last Two Yrs];
		SELECT 'RS1' [RS1], 
			tech.objName [Technique], coa.objName [CoA], ISNULL(om.CoACount, 0) CoACount, tt.[Rank], coa.objDescription [CoA Dets]
			--, om.* 
		FROM #optimalMits om
		INNER JOIN @topTechniques tt ON tt.TechniqueRootPk = om.TechRootPk
		INNER JOIN dbo.mkObject tech ON tech.[objId] = tt.TechniquePk
		LEFT JOIN dbo.mkRootObject roc ON roc.roPk = om.CoARootPk
		LEFT JOIN dbo.mkObject coa ON coa.[objId] = roc.roMaxObjPk
		WHERE om.CoACount IS NOT NULL
		ORDER BY om.CoACount DESC, coa.objName, tt.[Rank], tech.objName;		-- 
		
		SELECT 'RS2: The coverage of the Top N Techniques by the optimal set of CoAs.' [Comment], @Top_Techniques [Top N], @last2Yrs [Last Two Yrs];
		
		SELECT 'RS2t' [RS2],
			S.*, coa.objName CoA, coa.objDescription [CoA Details]
		FROM (
			SELECT r.relSourceRef CoA, COUNT(*) [CoA Count]
			FROM dbo.mkRelationship r
			INNER JOIN (
				SELECT DISTINCT om.CoARootPk
				FROM #optimalMits om
			) S ON S.CoARootPk = r.relSourceRef AND r.relType = 'mitigates' AND r.relYear = @yr2021
			--LEFT JOIN @topTechniques tt ON tt.TechniqueRootPk = r.relTargetRef
			GROUP BY r.relSourceRef
		) S
		INNER JOIN dbo.mkRootObject roc ON roc.roPk = S.CoA
		INNER JOIN dbo.mkObject coa ON coa.[objId] = roc.roMaxObjPk
		ORDER BY S.[CoA Count] DESC;

		SELECT 'RS2t' [RS2], r.*
		FROM dbo.mkRelationship r
		INNER JOIN (
			SELECT DISTINCT om.CoARootPk
			FROM #optimalMits om
		) S ON S.CoARootPk = r.relSourceRef AND r.relType = 'mitigates' AND r.relYear = @yr2021
		LEFT JOIN @topTechniques tt ON tt.TechniqueRootPk = r.relTargetRef
		ORDER BY r.relSourceRef, r.relTargetRef



		SELECT 'RS2' [RS2], 
			tech.objName [Technique], coa.objName [CoA], ISNULL(om.CoACount, 0) CoACount, tt.[Rank], --tt.Mitigations MitCount,
			tt.TechniqueRootPk TechRootPk, om.CoARootPk --,am.MaxYr
			, tech.objDescription [Tech Description], coa.objDescription [CoA Description] 
		FROM @topTechniques tt
		INNER JOIN #optimalMits om ON om.TechRootPk = tt.TechniqueRootPk	
		INNER JOIN dbo.mkRootObject ro ON ro.roPk = tt.TechniqueRootPk
		INNER JOIN dbo.mkObject tech ON tech.[objId] = ro.roMaxObjPk 	
		--LEFT JOIN @allMits am ON tt.TechniqueRootPk = am.TechRootPk
		LEFT JOIN dbo.mkRootObject rom ON rom.roPk = om.CoARootPk
		LEFT JOIN dbo.mkObject coa ON coa.[objId] = rom.roMaxObjPk
		ORDER BY om.CoACount DESC, coa.objName, tt.[Rank], tech.objName;		-- 

	END
	


	/* ################################################################################################
		RESULTS N - All Techniques (for testing)
	   ################################################################################################ */	
	IF @ACTION & 64 > 0
	BEGIN

		IF 1=0	--> Looks like the three Technique duplicates represent different flavours.
		BEGIN
			SELECT 'Duplicates ==>' WARNING, 
				mut.ToTypeName, 
				--mut.ToTypeObjMaxPk Pk, 
				COUNT(*)
			FROM dbo.aMaT_MuTechniquesAndMitigations mut
			INNER JOIN @topTechniques y ON y.Pk = mut.Pk
			GROUP BY mut.ToTypeName --, mut.ToTypeObjMaxPk
			HAVING COUNT(*) > 1;

			SELECT mo.[objId], mo.objName, mo.objYear Yr, 
				mo.objDescription 
				--,mo.*
			FROM dbo.mkObject mo
			WHERE 1=1
			--AND mo.[objId] IN (19936,19925,20107,20158,20466,20351)
			AND mo.objRootObjPk IN ('attack-pattern--21875073-b0ee-49e3-9077-1e2a885359af','attack-pattern--25659dd6-ea12-45c4-97e6-381e3e4b593e','attack-pattern--635cbe30-392d-4e27-978e-66774357c762','attack-pattern--7610cada-1499-41a4-b3dd-46467b68d177','attack-pattern--c2e147a9-d1a8-4074-811a-d8789202d916','attack-pattern--eec23884-3fa1-4d8a-ac50-6f104d51e235')
			ORDER BY  mo.objName, mo.objYear

		END
		SELECT 'RS1: All Techniques' [Comment], @Top_Techniques [Top N], @last2Yrs [Last Two Yrs];

		SELECT 'RS1' [RS1],
			y.[Rank], mut.ToTypeName Technique, mut.[2018], mut.[2019], mut.[2020], mut.[2021]
			--y.[Rank],
			--mut.*
			, mo.objDescription [Details] 
		FROM dbo.aMaT_MuTechniquesAndMitigations mut
		INNER JOIN @topTechniques y ON y.Pk = mut.Pk
		LEFT JOIN dbo.mkObject mo ON mo.[objId] = mut.ToTypeObjMaxPk

		SELECT @Top_Techniques [Top N],
			y.[Rank],
			mut.*, mo.objDescription [Details] 
		FROM dbo.aMaT_MuTechniquesAndMitigations mut
		INNER JOIN @topTechniques y ON y.Pk = mut.Pk
		LEFT JOIN dbo.mkObject mo ON mo.[objId] = mut.ToTypeObjMaxPk
		--WHERE mut.ToTypeName IN ('Domain Account', 'Local Account', 'Steganography')
	END
	

END		--> 1=1 OR @ACTION & 128 > 0

END


GO
------------------------------------------------------------------------------
------------------------------------------------------------------------------

USE [master]
GO
ALTER DATABASE [$(dbName)] SET  READ_WRITE 
GO

SELECT 'The database was provisioned.' [Create_DB_Objects.sql]
