
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
"NEW_AGENCYID",
"NEW_AGENCY_CODE",
"NEW_AGENCY_OPERATING_PLATFORM",
"NEW_BROKERAGE",
"NEW_BROKERAGENAME",
"NEW_EXCLUDED_FROM_CPC",
"NEW_IMPLOOKUP",
"NEW_LEGALENTITY",
"NEW_LEGALENTITYNAME",
"NEW_NAME",
"NEW_OPERATING_PLATFORM_MASTER",
"NEW_OPERATIONAL_REGION_CD",
"NEW_PORTFOLIO_END_DATE",
"NEW_PORTFOLIO_INDICATOR",
"NEW_PORTFOLIO_START_DATE",
"NEW_PORTFOLIO_STATUS",
"NEW_SPECIALTY_RISK_BUSINESS_SECTOR",
"NEW_STATUS",
"NEW_UNDERWRITING_PLATFORM_CD",
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
"NEW_PLCODETYPE"
] %}
{% set summarize = true %}

{% set a_query %}      
SELECT * FROM STG.ST_D365_NEW_AGENCY
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_AGENCYID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1 
{% endset %}


{% set b_query %}
SELECT * FROM STG.ST_NBDYNAMICS_FILTEREDNEW_AGENCY
QUALIFY ROW_NUMBER() OVER(PARTITION BY NEW_AGENCYID ORDER BY INSERT_TS DESC, UNIQUE_KEY DESC) = 1
{% endset %}

{% for column_name in column_names %}

{% set audit_query = audit_helper.compare_column_values_verbose(
  a_query=a_query,
  b_query=b_query,
  primary_key="NEW_AGENCYID",
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

