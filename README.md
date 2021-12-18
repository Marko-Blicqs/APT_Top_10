# Notice

The data set for this project is the MITRE ATT&CK &reg; Enterprise data set version 9.0, which is used under the terms of [their license agreement](https://attack.mitre.org/resources/terms-of-use/). This project was created independently of MITRE and is not endorsed by them.


# Purpose

The project presents a *Top 10* of Advanced Persistent Threat (**APT**) behaviors, a companion list of prioritized Mitigations, and recommendations for where to look for indicators of compromise (**IOC**).

The objective of these artifacts is to demystify APTs and provide concise *mitigation guidance* against the most frequently used APT behaviors. The project is particularly aimed at resource constrained defenders within smaller organizations. This group are increasingly exposed to APT behaviors by virtue of commoditized cybercrime (e.g., in ransomware), yet are ill prepared. The result is a collection of easily understood mitigations that can be selectively applied to augment an organisation's default security posture.


## The Purpose of this Repository

The project imports ATT&CK data into an MS SQL database. This offers two immediate benefits. First, the familiar tabular data structure is conceptually more accessible than the 32k<sup>1</sup> JSON files and, second, the simplicity of SQL syntax provides a straightforward query mechanism to easily examine the entire dataset. This is particularly powerful for identifying long-term and emerging patterns of APT behaviour and for otherwise quickly drilling into the data.

The repository contains the scripts to import the 2018 - 2021 ATT&CK data into an MS SQL Server database, execute our analysis and store the results, and examine those results.

Note <sup>1</sup>: In the *Enterprise* collection of ATT&CK version 9.0.
	
# Results (ATT&CK version 9)

We recommend the document [MITRE ATT&CK &reg; : Design and Philosophy](https://www.mitre.org/sites/default/files/publications/pr-19-01075-28-mitre-attack-design-and-philosophy.pdf), as the starting point for understanding the data.

## Methodology

- Identify all Techniques used by each of the 121 Groups, ignoring whether these were used directly, via a tool, or via malware. 
- Extract the N most frequently used Techniques, ordering them in descending order of frequency of use from 2021 - 2018.
- Identify all Mitigations used against these Techniques and arrange them in descending order, based on the number of times each Technique was used against the Top N Techniques.
- Examine the distribution of Techniques across Tactics (i.e., the motivation behind Techniques).
- Examine associated Data Components to identify where to find IOCs, and which data to look for in those data sources.

## Headline Results

Given the tabular data structure and the simplicity of SQL, it is easy to vary queries. For example, we identified and examined the Top 10, 15, 20, and 30 Techniques. We also looked for emerging APT behavioural trends, by filtering against the most recent two years of data. For brevity, here we only present the basic Top 10 and associated Mitigations. We exclude the resultant Data Sources for IOC etc. 

Note that from version 10, ATT&CK will enrich Data Components by adding additional *what to look for* details.

### Top 10 APT Techniques

- *Rank*: determine how many Techniques within the Top 10 that the Mitigation is effective against and order these values.
- *2018 - 2021*: the number of times the Technique is used within the year.

|Rank |Technique                            |2018 |2019 |2020 |2021 |
|:---:|:------------------------------      |:---:|:---:|:---:|:---:|
|1	 |Ingress Tool Transfer					|12	 |24  |24	|24	 |
|2	 |System Network Configuration Discovery|8	 |16  |16	|24  |
|3	 |Non-Application Layer Protocol		|8	 |8	  |8	|24  |
|4	 |Match Legitimate Name or Location		|0	 |0	  |6	|20  |
|5	 |System Information Discovery			|8	 |16  |16	|16  |
|6	 |Windows Management Instrumentation	|4	 |16  |16	|16  |
|7	 |Remote System Discovery				|8	 |8	  |8	|16  |
|8	 |Application Window Discovery			|0	 |8	  |8	|16  |
|9	 |Indicator Removal on Host				|8	 |8	  |0	|16  |
|10	 |Disable or Modify Tools				|0	 |0	  |10	|14  |

The associated descriptions of these Techniques reveal specific mitigating actions that are not explicit in the associated Mitigations. These include the following. 

|Item			| OS   | Recommendation           |
|:-------		|:---: |:----------------------   |
|System Info	| Win | Restrict access | 
|systemsetup 	| Mac | Restrict access | 
|ARP 			| All | Restrict access / monitor | 
|ipconfig 		| All | Restrict access / monitor | 
|ifconfig 		| All | Restrict access / monitor | 
|nbstat 		| Win | Restrict access / monitor | 
| ICMP 			| All | monitor | 
| TCP/UDP		| All | monitor | 
| SOCKS 		| All | monitor | 
| SOL 			| All | monitor | 


### Mitigations Against the Top 10

- *Rank*: determine how many Techniques within the Top 10 that the Mitigation is effective against and order these values.
- *2018 - 2021*: the number of all Techniques that the Mitigation is effective against, within each year.

|Rank |Mitigation                               |2018 |2019 |2020	|2021 |
|:---:|:------------------------------          |:---:|:---:|:---:	|:---:|
|5	 |Privileged Account Management				|0	 |13  |79	|98  |
|3	 |User Account Management					|0	 |10  |57	|71  |
|9	 |Execution Prevention						|0	 |12  |49	|55  |
|2	 |Network Intrusion Prevention				|0	 |17  |47	|54  |
|1 	 |Restrict File and Directory Permissions	|0	 |5   |51	|53  |
|7	 |Filter Network Traffic					|0	 |8   |31	|38  |
|4	 |Network Segmentation						|0	 |12  |28	|35  |
|8	 |Encrypt Sensitive Information				|0	 |4   |21	|28  |
|10	 |Code Signing								|0	 |1   |13	|17  |
|11	 |Restrict Registry Permissions				|0	 |2   |14	|15  |
|6	 |Remote Data Storage						|0	 |3	  |7	|7   |


# Installation

1. [Download the ATT&CK data](https://github.com/mitre/cti/releases/tag/ATT%26CK-v9.0)

2. Update the four configuration settings in DataImport.ps1. Refer to the instructions in that file.

3. Run DataImport.ps1 
3.1	This creates the target database, populates it with the ATT&CK data, runs our analysis, and stores the results.

In our repeated testing, the import and analysis took 30-35 minutes.

## To Analyse the Data

To view the results of our analysis, use the following two scripts, amending the input variables as required to filter the results. These scripts execute two underlying stored procedures that contain our analysis.

- Analysis_101_Malware.sql
- Analysis_102_Top_N.sql

A reasonable starting point to extend our analysis is to extract these two stored procedures into scripts, as this simplifies creating and refining queries, and build from there. 

## Test and Development Environment

- 1.90GHz, 2 Cores, 16GB RAM
- Windows 10 Home (64-bit)
- SQL Server 2017 Express Edition 14.0.2037.2 (X64)
- PowerShell 5.1.19041.1320
- Jupyter Notebook 6.3.0

	
# Limitations

1. The methodology must be peer reviewed and cross-referenced.

2. In version 9, only four years of data are available. As more data is added over the years, ongoing analysis will enjoy greater confidence.

3. This code has not been peer reviewed and may contain errors.

4. Several analytic processes rely on the SQL PIVOT function. These are hard coded and only support 2018 - 2021. They will need updating annually from 2022.

5. Although the current import process requires a local copy of the data, it should be possible to pull directly from the relevant ATT&CK repository, [refer to](https://attack.mitre.org/resources/updates/updates-october-2021/).

6. The project was developed on a Windows operating system and is limited to Windows/MS SQL Server.


# Manifest

- LICENSE.txt
- README.md
- TERMS OF USE.txt
- Analysis\
	- Analysis_101_Malware.sql
	- Analysis_102_Top_N.sql
- Import\
	- Create_DB_Objects.sql
	- DataImport.ps1
	- MitreFunctions.psm1
- JupyterItems\
	- 1.1 - Killchain Analysis.ipynb
	- 1.2 - Technique Analysis.ipynb

*Note:*
We provide the two Jupyter Notebook files purely as examples of how one might visualise the analysis results. It is also easy to visualise results in MS Excel.
