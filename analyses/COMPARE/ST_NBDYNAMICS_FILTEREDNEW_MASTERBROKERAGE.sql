
{% set column_names = [
"CREATEDBY",
"CREATEDBYNAME",
"CREATEDBYYOMINAME",
"CREATEDON",
"CREATEDONBEHALFBY",
"CREATEDONBEHALFBYNAME",
"CREATEDONBEHALFBYYOMINAME",
"IMPORTSEQUENCENUMBER",
"MODIFIEDBY",
"MODIFIEDBYNAME",
"MODIFIEDBYYOMINAME",
"MODIFIEDON",
"MODIFIEDONBEHALFBY",
"MODIFIEDONBEHALFBYNAME",
"MODIFIEDONBEHALFBYYOMINAME",
"NEW_BROKERAGEFISCALYEAREND",
"NEW_BROKERAGE_LEGAL_NAME",
"NEW_BROKERPARTNERLEVEL",
"NEW_BUSINESSDEVELOPMENTMANAGER",
"NEW_BUSINESSDEVELOPMENTMANAGERNAME",
"NEW_BUSINESSDEVELOPMENTMANAGERYOMINAME",
"NEW_COMPETITOREQUITY",
"NEW_COMPETITORWITHINFLUENCETOBROKERAGE",
"NEW_COMPETITORWITHINFLUENCETOBROKERAGENAME",
"NEW_COMPETITORWITHINFLUENCETOBROKERAGEYOMINAME",
"NEW_CONTRACTACCESS",
"NEW_CONTRACTSTATUS",
"NEW_CORPORATEBROKERAGEKEY",
"NEW_CORPORATEBROKERAGEKEYNAME",
"NEW_CORPORATEBROKERAGENAME",
"NEW_CORPORATEGROUPCODE",
"NEW_CORPORATESTATUS",
"NEW_GRANDFATHEREDINNERCIRCLE",
"NEW_GRANDFATHEREDINNERCIRCLETERM",
"NEW_MANAGINGGENERALAGENT",
"NEW_MASTERBROKERAGEID",
"NEW_MASTERBROKERAGENAME",
"NEW_MASTERGROUPCODE",
"NEW_MASTERSTATUS",
"NEW_NAME",
"NEW_ORIGINALAPPOINTMENTDATE",
"NEW_OWNERSHIPSTRUCTURE",
"NEW_PROVINCEOFOPERATION",
"NEW_REACH",
"NEW_REHABILITATION",
"NEW_SPECIALCLAIMSHANDLING",
"NEW_TYPEOFCOMPETITORINFLUENCE",
"NEW_YEARESTABLISHED",
"OVERRIDDENCREATEDON",
"OWNERID",
"OWNERIDNAME",
"OWNERIDTYPE",
"OWNERIDYOMINAME",
"OWNINGBUSINESSUNIT",
"OWNINGTEAM",
"OWNINGUSER",
"STATECODE",
"STATUSCODE",
"TIMEZONERULEVERSIONNUMBER",
"UTCCONVERSIONTIMEZONECODE",
"NEW_BEPRCONTACTID",
"NEW_BEPRCONTACTID_ENTITYTYPE",
"NEW_BEPRCONTACTIDNAME",
"NEW_BEPRCONTACTIDYOMINAME",
"NEW_BROKERMASTERSHORTNAME",
"NEW_BROKERNETWORK",
"NEW_CLCPCADMINPERCENT",
"NEW_CLCPCGRID",
"NEW_CLSTOPLOSSAMOUNT",
"NEW_CLSYSTEMUSEPERCENT",
"NEW_CPCTYPE",
"NEW_MASTERAPPOINTMENTYEAR",
"NEW_PLCPCADMINPERCENT",
"NEW_PLCPCGRID",
"NEW_PLSTOPLOSSAMOUNT",
"NEW_PLSYSTEMUSEPERCENT",
"NEW_SBSPCADMINPERCENT",
"NEW_SURETYCPCTYPE"
] %}
{% set summarize = true %}

{% set a_query %}      
SELECT * FROM STG.ST_D365_NEW_MASTERBROKERAGE
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_MASTERBROKERAGEID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}


{% set b_query %}
SELECT * FROM STG.ST_NBDYNAMICS_FILTEREDNEW_MASTERBROKERAGE
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_MASTERBROKERAGEID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}

{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="NEW_MASTERBROKERAGEID",
  column_to_compare=column_name
) %}


{% if loop.first %}

with main as ( 

{% endif %}

( {{ audit_query }} )

{% if not loop.last %}

  union all

{% else %}

), 

  {%- if summarize %}

	final as (
	  select
		upper(column_name) as column_name,
		sum(case when conflicting_values then 1 else 0 end) as conflicting_values,
		sum(case when perfect_match then 1 else 0 end) as perfect_match,
		sum(case when null_in_a then 1 else 0 end) as nulls_in_source,
		sum(case when null_in_b then 1 else 0 end) as nulls_in_target,
		sum(case when missing_from_a then 1 else 0 end) as missing_from_source,
		sum(case when missing_from_b then 1 else 0 end) as missing_from_target
	  from main
	  group by 1
	  order by column_name
	)

  {%- else %}

	final as (
	  select
		primary_key,           
		upper(column_name) as column_name,
		conflicting_values,
		perfect_match,
		nulls_in_source,
		nulls_in_target,
		missing_from_source,
		missing_from_target
	  from main    
	  order by primary_key
	)

  {%- endif %}

  select * from final 
  order by conflicting_values desc;

{% endif %}

{% endfor %}

